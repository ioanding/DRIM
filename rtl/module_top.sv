// Copyright (c) 2024-2025 Integrated Circuits Lab, Democritus University of Thrace, Greece.
// 
// Copyright and related rights are licensed under the MIT License (the "License");
// you may not use this file except in compliance with the License. Unless required
// by applicable law or agreed to in writing, software, hardware and materials 
// distributed under this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
// OR CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Authors:
// - Ioannis Dingolis <ioanding@ee.duth.gr>

`ifdef MODEL_TECH
    `include "structs.sv"
`endif

// Initializes the processor, the interconnect, the axi memory controller(s) and 
// connects them together

module module_top #(
    // Clock period
    parameter time         ClkPeriod    = 10ns,
    // Number of total axi_mem_sims
    parameter int unsigned NoAxiMemSims = 1,
    // Address space size for each axi_mem_sim
    parameter int unsigned UnqAddrSpace = 32'h100000
) (
    input logic clk,
    input logic rst_n
);
    //////////////////////////////////////////////////
    //                Local Parameters              //
    //////////////////////////////////////////////////

    // -=-=-=-=-=-=-=-=- Processor =-=-=-=-=-=-=-=- //
    // Memory System 
    localparam IC_ENTRIES       = 32  ;
    localparam IC_DW            = 256 ;
    localparam DC_ENTRIES       = 32  ;
    localparam DC_DW            = 256 ;
    localparam L2_ENTRIES       = 1900000;
    localparam L2_DW            = 512 ;
    localparam REALISTIC        = 1   ;
    localparam DELAY_CYCLES     = 10  ;
    // Predictor
    localparam RAS_DEPTH        = 8  ;
    localparam GSH_HISTORY_BITS = 2  ;
    localparam GSH_SIZE         = 256;
    localparam BTB_SIZE         = 256;
    // Dual Issue Enabler
    localparam DUAL_ISSUE       = 1;
    // ROB (Do NOT MODIFY, structs cannot update their widths automatically)
    localparam ROB_ENTRIES      = 8                  ; //default: 8
    localparam ROB_TICKET_W     = $clog2(ROB_ENTRIES); //default: DO NOT MODIFY
    // Other  (DO NOT MODIFY)
    localparam ISTR_DW          = 32        ; //default: 32
    localparam ADDR_BITS        = 32        ; //default: 32
    localparam DATA_WIDTH       = 32        ; //default: 32
    localparam R_WIDTH          = 6         ; //default: 6
    localparam MICROOP_W        = 5         ; //default: 5
    localparam UNCACHEABLE_ST   = 4294901760; //default: 4294901760

    // -=-=-=-=-=-=-=-=-=-= AXI =-=-=-=-=-=-=-=-=-= //
    // AXI Interconnect
    localparam AXI_ADDR_WIDTH   = 32;
    localparam AXI_DATA_WIDTH   = 32;
    localparam AXI_USER_WIDTH   = 1;
    localparam AXI_ID_WIDTH     = 4;
    localparam NUM_MASTERS      = 2;  // Two masters (IC and DC)
    localparam XBAR_SLV_IW      = AXI_ID_WIDTH + $clog2(NUM_MASTERS); // Id width for xbar
    // axi_mem_sim 
    localparam WARN_UNINIT      = 0;
    localparam time APPL_DELAY  = ( ClkPeriod / 5     );    
    localparam time ACQ_DELAY   = ( 4 * ClkPeriod / 5 );    


    //////////////////////////////////////////////////
    //                     Wires                    //
    //////////////////////////////////////////////////
    logic                        icache_valid_i, dcache_valid_i, cache_store_valid, icache_valid_o, dcache_valid_o, cache_load_valid, write_l2_valid;
    logic     [   ADDR_BITS-1:0] icache_address_i, dcache_address_i, cache_store_addr, icache_address_o, dcache_address_o, write_l2_addr_c, write_l2_addr, cache_load_addr;
    logic     [       DC_DW-1:0] write_l2_data, write_l2_data_c, dcache_data_o;
    logic     [  DATA_WIDTH-1:0] cache_store_data    ;
    logic     [       IC_DW-1:0] icache_data_o       ;
    logic     [   ADDR_BITS-1:0] current_pc          ;
    logic                        hit_icache, miss_icache, half_fetch;
    logic     [     ISTR_DW-1:0] fetched_data        ;
    logic                        cache_store_uncached, cache_store_cached, write_l2_valid_c;
    logic     [     R_WIDTH-1:0] cache_load_dest     ;
    logic     [   MICROOP_W-1:0] cache_load_microop, cache_store_microop;
    logic     [ROB_TICKET_W-1:0] cache_load_ticket   ;
    ex_update                    cache_fu_update     ;

    logic        frame_buffer_write  ;
    logic [15:0] frame_buffer_data   ;
    logic [14:0] frame_buffer_address;
    logic [ 7:0] red_o, green_o, blue_o;
    logic [ 4:0] color               ;

    logic                  ic_inactive_valid_o;
    logic [ADDR_BITS-1:0]  ic_inactive_addr_o;
    logic [IC_DW-1:0]      ic_inactive_data_o;

    //////////////////////////////////////////////////
    //                   AXI Buses                  //
    //////////////////////////////////////////////////

    AXI_BUS #(
        .AXI_ADDR_WIDTH ( AXI_ADDR_WIDTH ),
        .AXI_DATA_WIDTH ( AXI_DATA_WIDTH ),
        .AXI_ID_WIDTH   ( AXI_ID_WIDTH   ),
        .AXI_USER_WIDTH ( AXI_USER_WIDTH )
    ) icache_mst ();
    AXI_BUS #(
        .AXI_ADDR_WIDTH ( AXI_ADDR_WIDTH ),
        .AXI_DATA_WIDTH ( AXI_DATA_WIDTH ),
        .AXI_ID_WIDTH   ( AXI_ID_WIDTH   ),
        .AXI_USER_WIDTH ( AXI_USER_WIDTH )
    ) dcache_mst ();
    AXI_BUS #(
        .AXI_ADDR_WIDTH ( AXI_ADDR_WIDTH ),
        .AXI_DATA_WIDTH ( AXI_DATA_WIDTH ),
        .AXI_ID_WIDTH   ( XBAR_SLV_IW    ),
        .AXI_USER_WIDTH ( AXI_USER_WIDTH )
    ) mem_slv [NoAxiMemSims-1:0] ();

    //////////////////////////////////////////////////
    //                   Processor                  //
    //////////////////////////////////////////////////

    processor_top #(
        .ADDR_BITS       (ADDR_BITS       ),
        .INSTR_BITS      (ISTR_DW         ),
        .DATA_WIDTH      (DATA_WIDTH      ),
        .MICROOP_WIDTH   (5               ),
        .PR_WIDTH        (R_WIDTH         ),
        .ROB_ENTRIES     (ROB_ENTRIES     ),
        .RAS_DEPTH       (RAS_DEPTH       ),
        .GSH_HISTORY_BITS(GSH_HISTORY_BITS),
        .GSH_SIZE        (GSH_SIZE        ),
        .BTB_SIZE        (BTB_SIZE        ),
        .DUAL_ISSUE      (DUAL_ISSUE      ),
        .MAX_BRANCH_IF   (4               )
    ) top_processor (
        .clk               (clk                ),
        .rst_n             (rst_n              ),
        //Input from ICache
        .current_pc        (current_pc         ),
        .hit_icache        (hit_icache         ),
        .miss_icache       (miss_icache        ),
        .half_fetch        (half_fetch         ),
        .fetched_data      (fetched_data       ),
        // Writeback into DCache (stores)
        .cache_wb_valid_o  (cache_store_valid  ),
        .cache_wb_addr_o   (cache_store_addr   ),
        .cache_wb_data_o   (cache_store_data   ),
        .cache_wb_microop_o(cache_store_microop),
        // Load for DCache
        .cache_load_valid  (cache_load_valid   ),
        .cache_load_addr   (cache_load_addr    ),
        .cache_load_dest   (cache_load_dest    ),
        .cache_load_microop(cache_load_microop ),
        .cache_load_ticket (cache_load_ticket  ),
        //Misc
        .cache_fu_update   (cache_fu_update    ),
        .cache_blocked     (cache_blocked      ),
        .cache_will_block  (cache_will_block   ),
        .ld_st_output_used (ld_st_output_used  )
    );
    //Check for new store if cached/uncached and drive it into the cache
    assign cache_store_uncached = cache_store_valid & (cache_store_addr>=UNCACHEABLE_ST);
    assign cache_store_cached   = cache_store_valid & ~cache_store_uncached;
    //Create the Signals for the write-through into the L2
    assign write_l2_valid   = cache_store_uncached | write_l2_valid_c;
    assign write_l2_addr    = cache_store_uncached ? cache_store_addr : write_l2_addr_c;
    assign write_l2_data    = cache_store_uncached ? cache_store_data : write_l2_data_c;
    // assign write_l2_microop = cache_store_uncached ? cache_store_microop : 5'b0;

    assign frame_buffer_write   = cache_store_uncached;
    assign frame_buffer_data    = cache_store_data[15:0];
    assign frame_buffer_address = cache_store_addr[14:0];
    assign color                = cache_store_data[4:0];

    logic [15:0] frame_buffer[19200-1:0];
    always_ff @(posedge clk) begin : FB
        if(frame_buffer_write) begin
            frame_buffer[frame_buffer_address] = frame_buffer_data;
        end
    end
    
    /////////////////////////////////////////////////
    //               Caches' Subsection            //
    /////////////////////////////////////////////////
    cache_top # (
        .USE_AXI                ( 1              ),
        .ADDR_BITS              ( ADDR_BITS      ),
        .ISTR_DW                ( ISTR_DW        ),
        .DATA_WIDTH             ( DATA_WIDTH     ),
        .R_WIDTH                ( R_WIDTH        ),
        .MICROOP_W              ( MICROOP_W      ),
        .ROB_ENTRIES            ( ROB_ENTRIES    ),
        .IC_ENTRIES             ( IC_ENTRIES     ),
        .DC_ENTRIES             ( DC_ENTRIES     ),
        .IC_DW                  ( IC_DW          ),
        .DC_DW                  ( DC_DW          ),
        .AXI_AW                 ( AXI_ADDR_WIDTH ),
        .AXI_DW                 ( AXI_DATA_WIDTH )
    ) caches_top (
        .clk                    ( clk                 ),
        .resetn                 ( rst_n               ),
        .icache_current_pc      ( current_pc          ),
        .icache_hit_icache      ( hit_icache          ),
        .icache_miss_icache     ( miss_icache         ),
        .icache_half_fetch      ( half_fetch          ),
        .icache_instruction_out ( fetched_data        ),
        .dcache_output_used     ( ld_st_output_used   ),
        .dcache_load_valid      ( cache_load_valid    ),
        .dcache_load_address    ( cache_load_addr     ),
        .dcache_load_dest       ( cache_load_dest     ),
        .dcache_load_microop    ( cache_load_microop  ),
        .dcache_load_ticket     ( cache_load_ticket   ),
        .dcache_store_valid     ( cache_store_cached  ),
        .dcache_store_address   ( cache_store_addr    ),
        .dcache_store_data      ( cache_store_data    ),
        .dcache_store_microop   ( cache_store_microop ),
        .dcache_will_block      ( cache_will_block    ),
        .dcache_blocked         ( cache_blocked       ),
        .dcache_served_output   ( cache_fu_update     ),
        .ic_m_axi_awvalid       ( icache_mst.aw_valid ),
        .ic_m_axi_awready       ( icache_mst.aw_ready ),
        .ic_m_axi_awaddr        ( icache_mst.aw_addr  ),
        .ic_m_axi_awburst       ( icache_mst.aw_burst ),
        .ic_m_axi_awlen         ( icache_mst.aw_len   ),
        .ic_m_axi_awsize        ( icache_mst.aw_size  ),
        .ic_m_axi_awid          ( icache_mst.aw_id    ),
        .ic_m_axi_wvalid        ( icache_mst.w_valid  ),
        .ic_m_axi_wready        ( icache_mst.w_ready  ),
        .ic_m_axi_wdata         ( icache_mst.w_data   ),
        .ic_m_axi_wlast         ( icache_mst.w_last   ),
        .ic_m_axi_wstrb         ( icache_mst.w_strb   ),
        .ic_m_axi_bid           ( icache_mst.b_id     ),
        .ic_m_axi_bresp         ( icache_mst.b_resp   ),
        .ic_m_axi_bvalid        ( icache_mst.b_valid  ),
        .ic_m_axi_bready        ( icache_mst.b_ready  ),
        .ic_m_axi_arready       ( icache_mst.ar_ready ),
        .ic_m_axi_arvalid       ( icache_mst.ar_valid ),
        .ic_m_axi_araddr        ( icache_mst.ar_addr  ),
        .ic_m_axi_arburst       ( icache_mst.ar_burst ),
        .ic_m_axi_arlen         ( icache_mst.ar_len   ),
        .ic_m_axi_arsize        ( icache_mst.ar_size  ),
        .ic_m_axi_arid          ( icache_mst.ar_id    ),
        .ic_m_axi_rdata         ( icache_mst.r_data   ),
        .ic_m_axi_rlast         ( icache_mst.r_last   ),
        .ic_m_axi_rid           ( icache_mst.r_id     ),
        .ic_m_axi_rresp         ( icache_mst.r_resp   ),
        .ic_m_axi_rvalid        ( icache_mst.r_valid  ),
        .ic_m_axi_rready        ( icache_mst.r_ready  ),
        .dc_m_axi_awvalid       ( dcache_mst.aw_valid ),
        .dc_m_axi_awready       ( dcache_mst.aw_ready ),
        .dc_m_axi_awaddr        ( dcache_mst.aw_addr  ),
        .dc_m_axi_awburst       ( dcache_mst.aw_burst ),
        .dc_m_axi_awlen         ( dcache_mst.aw_len   ),
        .dc_m_axi_awsize        ( dcache_mst.aw_size  ),
        .dc_m_axi_awid          ( dcache_mst.aw_id    ),
        .dc_m_axi_wvalid        ( dcache_mst.w_valid  ),
        .dc_m_axi_wready        ( dcache_mst.w_ready  ),
        .dc_m_axi_wdata         ( dcache_mst.w_data   ),
        .dc_m_axi_wlast         ( dcache_mst.w_last   ),
        .dc_m_axi_wstrb         ( dcache_mst.w_strb   ),
        .dc_m_axi_bid           ( dcache_mst.b_id     ),
        .dc_m_axi_bresp         ( dcache_mst.b_resp   ),
        .dc_m_axi_bvalid        ( dcache_mst.b_valid  ),
        .dc_m_axi_bready        ( dcache_mst.b_ready  ),
        .dc_m_axi_arready       ( dcache_mst.ar_ready ),
        .dc_m_axi_arvalid       ( dcache_mst.ar_valid ),
        .dc_m_axi_araddr        ( dcache_mst.ar_addr  ),
        .dc_m_axi_arburst       ( dcache_mst.ar_burst ),
        .dc_m_axi_arlen         ( dcache_mst.ar_len   ),
        .dc_m_axi_arsize        ( dcache_mst.ar_size  ),
        .dc_m_axi_arid          ( dcache_mst.ar_id    ),
        .dc_m_axi_rdata         ( dcache_mst.r_data   ),
        .dc_m_axi_rlast         ( dcache_mst.r_last   ),
        .dc_m_axi_rid           ( dcache_mst.r_id     ),
        .dc_m_axi_rresp         ( dcache_mst.r_resp   ),
        .dc_m_axi_rvalid        ( dcache_mst.r_valid  ),
        .dc_m_axi_rready        ( dcache_mst.r_ready  ),
        // Connection with L2 - Not Used.
        .valid_out              (),
        .address_out            (),
        .ready_in               (),
        .data_in                (),
        .write_l2_valid         (),
        .write_l2_addr          (),
        .write_l2_data          (),
        .request_l2_valid       (),
        .request_l2_addr        (),
        .update_l2_valid        (),
        .update_l2_addr         (),
        .update_l2_data         ()
    );

    //////////////////////////////////////////////////
    //                 Interconnect                 //
    //////////////////////////////////////////////////

    axi_intercon #(
        .UNQ_ADDR_SPC       ( UnqAddrSpace   ),
        .NoSlaves           ( NoAxiMemSims   ),
        .AxiDataWidth       ( AXI_DATA_WIDTH ),
        .AxiIdWidthMasters  ( AXI_ID_WIDTH   ),
        .AxiIdUsed          ( AXI_ID_WIDTH   ),
        .AxiUserWidth       ( AXI_USER_WIDTH )
    ) axi_intercon (
        .clk_i              ( clk        ),
        .rst_ni             ( rst_n      ),
        .ic_slv_port        ( icache_mst ),
        .dc_slv_port        ( dcache_mst ),
        .mem_mst_port       ( mem_slv    )
    );

    //////////////////////////////////////////////////
    //               axi_mem_sim (RAM)              //
    //////////////////////////////////////////////////

    for (genvar i = 0; i < NoAxiMemSims; i++) begin : gen_axi_mem_sim
        axi_sim_mem_intf #(
            .AXI_ADDR_WIDTH     ( AXI_ADDR_WIDTH ),
            .AXI_DATA_WIDTH     ( AXI_DATA_WIDTH ),
            .AXI_ID_WIDTH       ( XBAR_SLV_IW    ),
            .AXI_USER_WIDTH     ( AXI_USER_WIDTH ),
            .WARN_UNINITIALIZED ( WARN_UNINIT    ),
            .APPL_DELAY         ( APPL_DELAY     ),
            .ACQ_DELAY          ( ACQ_DELAY      )
        ) i_axi_sim_mem_intf (
            .clk_i              ( clk        ),
            .rst_ni             ( rst_n      ),
            .axi_slv            ( mem_slv[i] ),
            .mon_w_valid_o      (),
            .mon_w_addr_o       (),
            .mon_w_data_o       (),
            .mon_w_id_o         (),
            .mon_w_user_o       (),
            .mon_w_beat_count_o (),
            .mon_w_last_o       (),
            .mon_r_valid_o      (),
            .mon_r_addr_o       (),
            .mon_r_data_o       (),
            .mon_r_id_o         (),
            .mon_r_user_o       (),
            .mon_r_beat_count_o (),
            .mon_r_last_o       ()
        );
    end

    //////////////////////////////////////////////////
    //                VGA Controller                //
    //////////////////////////////////////////////////
    logic [14:0] vga_address;
    logic [15:0] vga_data;
    logic hsync, vsync, vga_clk;

    assign vga_data = frame_buffer[vga_address];

    vga_controller vga_controller (
        .clk    (clk        ),
        .rst_n  (rst_n      ),
        //read
        .valid_o(           ),
        .address(vga_address),
        .data_in(vga_data   ),
        //output
        .hsync  (hsync      ),
        .vsync  (vsync      ),
        .vga_clk(vga_clk    ),
        .red_o  (red_o      ),
        .green_o(green_o    ),
        .blue_o (blue_o     )
    );

endmodule : module_top