/**
*@info top module
*@info Sub-Modules: processor_top.sv, main_memory.sv
*
*
* @brief Initializes the Processor and the main memory controller, and connects them
*
*/
`ifdef MODEL_TECH
    `include "structs.sv"
`endif
`include "enum.sv"
module module_top (
    input logic clk  ,
    input logic rst_n
);
    //Memory System Parameters
    localparam IC_ENTRIES   = 32  ;
    localparam IC_DW        = 256 ;
    localparam DC_ENTRIES   = 32  ;
    localparam DC_DW        = 256 ;
    localparam L2_ENTRIES   = 1900000;
    localparam L2_DW        = 512 ;
    localparam REALISTIC    = 1   ;
    localparam DELAY_CYCLES = 10  ;
    //Predictor Parameters
    localparam RAS_DEPTH        = 8  ;
    localparam GSH_HISTORY_BITS = 2  ;
    localparam GSH_SIZE         = 256;
    localparam BTB_SIZE         = 256;
    //Dual Issue Enabler
    localparam DUAL_ISSUE = 1;
    //ROB Parameters    (Do NOT MODIFY, structs cannot update their widths automatically)
    localparam ROB_ENTRIES  = 8                  ; //default: 8
    localparam ROB_TICKET_W = $clog2(ROB_ENTRIES); //default: DO NOT MODIFY
    //Other Parameters  (DO NOT MODIFY)
    localparam ISTR_DW        = 32        ; //default: 32
    localparam ADDR_BITS      = 32        ; //default: 32
    localparam DATA_WIDTH     = 32        ; //default: 32
    localparam R_WIDTH        = 6         ; //default: 6
    localparam MICROOP_W      = 5         ; //default: 5
    localparam UNCACHEABLE_ST = 4294901760; //default: 4294901760

    // Axi parameters
    localparam AXI_ADDR_WIDTH = 32;
    localparam AXI_DATA_WIDTH = 32;
    localparam AXI_USER_WIDTH = 1;
    localparam AXI_ID_WIDTH   = 4;
    // axi memory parameters
    localparam WARN_UNINITIALIZED = 0;
    localparam APPL_DELAY = 2ns;
    localparam ACQ_DELAY = 8ns;

    //===================================================================================
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

    // logic                  ic_AXI_AWVALID, dc_AXI_AWVALID;
    // logic                  ic_AXI_AWREADY, dc_AXI_AWREADY;
    // logic [ADDR_BITS-1 :0] ic_AXI_AWADDR , dc_AXI_AWADDR ;
    // burst_type             ic_AXI_AWBURST, dc_AXI_AWBURST;
    // logic [7           :0] ic_AXI_AWLEN  , dc_AXI_AWLEN  ;
    // logic [2           :0] ic_AXI_AWSIZE , dc_AXI_AWSIZE ;
    // logic [3           :0] ic_AXI_AWID   , dc_AXI_AWID   ;
    // logic                  ic_AXI_WVALID , dc_AXI_WVALID ;
    // logic                  ic_AXI_WREADY , dc_AXI_WREADY ;
    // logic [DATA_WIDTH-1:0] ic_AXI_WDATA  , dc_AXI_WDATA  ;
    // logic                  ic_AXI_WLAST  , dc_AXI_WLAST  ;
    // logic [3           :0] ic_AXI_WSTRB  , dc_AXI_WSTRB  ;
    // logic [3           :0] ic_AXI_BID    , dc_AXI_BID    ;
    // logic [1           :0] ic_AXI_BRESP  , dc_AXI_BRESP  ;
    // logic                  ic_AXI_BVALID , dc_AXI_BVALID ;
    // logic                  ic_AXI_BREADY , dc_AXI_BREADY ;
    // logic                  ic_AXI_ARREADY, dc_AXI_ARREADY;
    // logic                  ic_AXI_ARVALID, dc_AXI_ARVALID;
    // logic [ADDR_BITS-1 :0] ic_AXI_ARADDR , dc_AXI_ARADDR ;
    // burst_type             ic_AXI_ARBURST, dc_AXI_ARBURST;
    // logic [7           :0] ic_AXI_ARLEN  , dc_AXI_ARLEN  ;
    // logic [2           :0] ic_AXI_ARSIZE , dc_AXI_ARSIZE ;
    // logic [3           :0] ic_AXI_ARID   , dc_AXI_ARID   ;
    // logic [DATA_WIDTH-1:0] ic_AXI_RDATA  , dc_AXI_RDATA  ;
    // logic                  ic_AXI_RLAST  , dc_AXI_RLAST  ;
    // logic [3           :0] ic_AXI_RID    , dc_AXI_RID    ;
    // logic [1           :0] ic_AXI_RRESP  , dc_AXI_RRESP  ;
    // logic                  ic_AXI_RVALID , dc_AXI_RVALID ;
    // logic                  ic_AXI_RREADY , dc_AXI_RREADY ;

    logic  [3:0] icache_awid;
    logic [31:0] icache_awaddr;
    logic  [7:0] icache_awlen;
    logic  [2:0] icache_awsize;
    logic  [1:0] icache_awburst;
    logic        icache_awlock;
    logic  [3:0] icache_awcache;
    logic  [2:0] icache_awprot;
    logic  [3:0] icache_awregion;
    logic  [0:0] icache_awuser;
    logic  [3:0] icache_awqos;
    logic        icache_awvalid;
    logic        icache_awready;
    logic  [3:0] icache_arid;
    logic [31:0] icache_araddr;
    logic  [7:0] icache_arlen;
    logic  [2:0] icache_arsize;
    logic  [1:0] icache_arburst;
    logic        icache_arlock;
    logic  [3:0] icache_arcache;
    logic  [2:0] icache_arprot;
    logic  [3:0] icache_arregion;
    logic  [0:0] icache_aruser;
    logic  [3:0] icache_arqos;
    logic        icache_arvalid;
    logic        icache_arready;
    logic [31:0] icache_wdata;
    logic  [3:0] icache_wstrb;
    logic        icache_wlast;
    logic  [0:0] icache_wuser;
    logic        icache_wvalid;
    logic        icache_wready;
    logic  [3:0] icache_bid;
    logic  [1:0] icache_bresp;
    logic        icache_bvalid;
    logic  [0:0] icache_buser;
    logic        icache_bready;
    logic  [3:0] icache_rid;
    logic [31:0] icache_rdata;
    logic  [1:0] icache_rresp;
    logic        icache_rlast;
    logic  [0:0] icache_ruser;
    logic        icache_rvalid;
    logic        icache_rready;
    logic  [3:0] dcache_awid;
    logic [31:0] dcache_awaddr;
    logic  [7:0] dcache_awlen;
    logic  [2:0] dcache_awsize;
    logic  [1:0] dcache_awburst;
    logic        dcache_awlock;
    logic  [3:0] dcache_awcache;
    logic  [2:0] dcache_awprot;
    logic  [3:0] dcache_awregion;
    logic  [0:0] dcache_awuser;
    logic  [3:0] dcache_awqos;
    logic        dcache_awvalid;
    logic        dcache_awready;
    logic  [3:0] dcache_arid;
    logic [31:0] dcache_araddr;
    logic  [7:0] dcache_arlen;
    logic  [2:0] dcache_arsize;
    logic  [1:0] dcache_arburst;
    logic        dcache_arlock;
    logic  [3:0] dcache_arcache;
    logic  [2:0] dcache_arprot;
    logic  [3:0] dcache_arregion;
    logic  [0:0] dcache_aruser;
    logic  [3:0] dcache_arqos;
    logic        dcache_arvalid;
    logic        dcache_arready;
    logic [31:0] dcache_wdata;
    logic  [3:0] dcache_wstrb;
    logic        dcache_wlast;
    logic  [0:0] dcache_wuser;
    logic        dcache_wvalid;
    logic        dcache_wready;
    logic  [3:0] dcache_bid;
    logic  [1:0] dcache_bresp;
    logic        dcache_bvalid;
    logic  [0:0] dcache_buser;
    logic        dcache_bready;
    logic  [3:0] dcache_rid;
    logic [31:0] dcache_rdata;
    logic  [1:0] dcache_rresp;
    logic        dcache_rlast;
    logic  [0:0] dcache_ruser;
    logic        dcache_rvalid;
    logic        dcache_rready;
    logic  [4:0] mem_one_awid;
    logic [31:0] mem_one_awaddr;
    logic  [7:0] mem_one_awlen;
    logic  [2:0] mem_one_awsize;
    logic  [1:0] mem_one_awburst;
    logic        mem_one_awlock;
    logic  [3:0] mem_one_awcache;
    logic  [2:0] mem_one_awprot;
    logic  [3:0] mem_one_awregion;
    logic  [0:0] mem_one_awuser;
    logic  [3:0] mem_one_awqos;
    logic        mem_one_awvalid;
    logic        mem_one_awready;
    logic  [4:0] mem_one_arid;
    logic [31:0] mem_one_araddr;
    logic  [7:0] mem_one_arlen;
    logic  [2:0] mem_one_arsize;
    logic  [1:0] mem_one_arburst;
    logic        mem_one_arlock;
    logic  [3:0] mem_one_arcache;
    logic  [2:0] mem_one_arprot;
    logic  [3:0] mem_one_arregion;
    logic  [0:0] mem_one_aruser;
    logic  [3:0] mem_one_arqos;
    logic        mem_one_arvalid;
    logic        mem_one_arready;
    logic [31:0] mem_one_wdata;
    logic  [3:0] mem_one_wstrb;
    logic        mem_one_wlast;
    logic  [0:0] mem_one_wuser;
    logic        mem_one_wvalid;
    logic        mem_one_wready;
    logic  [4:0] mem_one_bid;
    logic  [1:0] mem_one_bresp;
    logic        mem_one_bvalid;
    logic  [0:0] mem_one_buser;
    logic        mem_one_bready;
    logic  [4:0] mem_one_rid;
    logic [31:0] mem_one_rdata;
    logic  [1:0] mem_one_rresp;
    logic        mem_one_rlast;
    logic  [0:0] mem_one_ruser;
    logic        mem_one_rvalid;
    logic        mem_one_rready;


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
    // //////////////////////////////////////////////////
    // //               Main Memory Module    to be deleted 
    // //////////////////////////////////////////////////
    // main_memory_top # (
    //     .USE_AXI                (0),
    //     .L2_BLOCK_DW            (L2_DW),
    //     .L2_ENTRIES             (L2_ENTRIES),
    //     .ADDRESS_BITS           (ADDR_BITS),
    //     .ICACHE_BLOCK_DW        (IC_DW),
    //     .DCACHE_BLOCK_DW        (DC_DW),
    //     .REALISTIC              (REALISTIC),
    //     .DELAY_CYCLES           (DELAY_CYCLES),
    //     .FILE_NAME              ("memory.txt"),
    //     .ID_W                   (4),
    //     .ADDR_W                 (32),
    //     .AXI_DW                 (32),
    //     .RESP_W                 (2)
    // ) main_memory_top (
    //     .clk_i                  (clk),
    //     .rst_n_i                (rst_n),
    //     // icache
    //     .icache_valid_i         (icache_valid_i),
    //     .icache_address_i       (icache_address_i),
    //     .icache_valid_o         (icache_valid_o),
    //     .icache_data_o          (icache_data_o),
    //     // Request Write Port to L2
    //     .write_l2_valid         (write_l2_valid),
    //     .write_l2_addr          (write_l2_addr),
    //     .write_l2_data          (write_l2_data),
    //     // Request Read Port to L2
    //     .dcache_valid_i         (dcache_valid_i),
    //     .dcache_address_i       (dcache_address_i),
    //     // Update Port from L2
    //     .dcache_valid_o         (dcache_valid_o),
    //     .dcache_address_o       (dcache_address_o),
    //     .dcache_data_o          (dcache_data_o)
    // );

    
    /////////////////////////////////////////////////
    //               Caches' Subsection            //
    /////////////////////////////////////////////////
    cache_top # (
        .USE_AXI                (1),
        .ADDR_BITS              (ADDR_BITS),
        .ISTR_DW                (ISTR_DW),
        .DATA_WIDTH             (DATA_WIDTH),
        .R_WIDTH                (R_WIDTH),
        .MICROOP_W              (MICROOP_W),
        .ROB_ENTRIES            (ROB_ENTRIES),
        .IC_ENTRIES             (IC_ENTRIES),
        .DC_ENTRIES             (DC_ENTRIES),
        .IC_DW                  (IC_DW),
        .DC_DW                  (DC_DW),
        .AXI_AW                 (AXI_ADDR_WIDTH),
        .AXI_DW                 (AXI_DATA_WIDTH)
    ) caches_top (
        .clk                    (clk),
        .resetn                 (rst_n),

        .icache_current_pc      (current_pc),
        .icache_hit_icache      (hit_icache),
        .icache_miss_icache     (miss_icache),
        .icache_half_fetch      (half_fetch),
        .icache_instruction_out (fetched_data),
        .dcache_output_used     (ld_st_output_used),
        .dcache_load_valid      (cache_load_valid),
        .dcache_load_address    (cache_load_addr),
        .dcache_load_dest       (cache_load_dest),
        .dcache_load_microop    (cache_load_microop),
        .dcache_load_ticket     (cache_load_ticket),
        .dcache_store_valid     (cache_store_cached),
        .dcache_store_address   (cache_store_addr),
        .dcache_store_data      (cache_store_data),
        .dcache_store_microop   (cache_store_microop),
        .dcache_will_block      (cache_will_block),
        .dcache_blocked         (cache_blocked),
        .dcache_served_output   (cache_fu_update),

        .ic_m_axi_awvalid       (icache_awvalid),
        .ic_m_axi_awready       (icache_awready),
        .ic_m_axi_awaddr        (icache_awaddr),
        .ic_m_axi_awburst       (icache_awburst),
        .ic_m_axi_awlen         (icache_awlen),
        .ic_m_axi_awsize        (icache_awsize),
        .ic_m_axi_awid          (icache_awid),
        .ic_m_axi_wvalid        (icache_wvalid),
        .ic_m_axi_wready        (icache_wready),
        .ic_m_axi_wdata         (icache_wdata),
        .ic_m_axi_wlast         (icache_wlast),
        .ic_m_axi_wstrb         (icache_wstrb),
        .ic_m_axi_bid           (icache_bid),
        .ic_m_axi_bresp         (icache_bresp),
        .ic_m_axi_bvalid        (icache_bvalid),
        .ic_m_axi_bready        (icache_bready),
        .ic_m_axi_arready       (icache_arready),
        .ic_m_axi_arvalid       (icache_arvalid),
        .ic_m_axi_araddr        (icache_araddr),
        .ic_m_axi_arburst       (icache_arburst),
        .ic_m_axi_arlen         (icache_arlen),
        .ic_m_axi_arsize        (icache_arsize),
        .ic_m_axi_arid          (icache_arid),
        .ic_m_axi_rdata         (icache_rdata),
        .ic_m_axi_rlast         (icache_rlast),
        .ic_m_axi_rid           (icache_rid),
        .ic_m_axi_rresp         (icache_rresp),
        .ic_m_axi_rvalid        (icache_rvalid),
        .ic_m_axi_rready        (icache_rready),

        .dc_m_axi_awvalid       (dcache_awvalid),
        .dc_m_axi_awready       (dcache_awready),
        .dc_m_axi_awaddr        (dcache_awaddr),
        .dc_m_axi_awburst       (dcache_awburst),
        .dc_m_axi_awlen         (dcache_awlen),
        .dc_m_axi_awsize        (dcache_awsize),
        .dc_m_axi_awid          (dcache_awid),
        .dc_m_axi_wvalid        (dcache_wvalid),
        .dc_m_axi_wready        (dcache_wready),
        .dc_m_axi_wdata         (dcache_wdata),
        .dc_m_axi_wlast         (dcache_wlast),
        .dc_m_axi_wstrb         (dcache_wstrb),
        .dc_m_axi_bid           (dcache_bid),
        .dc_m_axi_bresp         (dcache_bresp),
        .dc_m_axi_bvalid        (dcache_bvalid),
        .dc_m_axi_bready        (dcache_bready),
        .dc_m_axi_arready       (dcache_arready),
        .dc_m_axi_arvalid       (dcache_arvalid),
        .dc_m_axi_araddr        (dcache_araddr),
        .dc_m_axi_arburst       (dcache_arburst),
        .dc_m_axi_arlen         (dcache_arlen),
        .dc_m_axi_arsize        (dcache_arsize),
        .dc_m_axi_arid          (dcache_arid),
        .dc_m_axi_rdata         (dcache_rdata),
        .dc_m_axi_rlast         (dcache_rlast),
        .dc_m_axi_rid           (dcache_rid),
        .dc_m_axi_rresp         (dcache_rresp),
        .dc_m_axi_rvalid        (dcache_rvalid),
        .dc_m_axi_rready        (dcache_rready)
        // // icache
        // .valid_out              (icache_valid_i),
        // .address_out            (icache_address_i),
        // .ready_in               (icache_valid_o),
        // .data_in                (icache_data_o),
        // // Request Write Port to L2
        // .write_l2_valid         (write_l2_valid_c),
        // .write_l2_addr          (write_l2_addr_c),
        // .write_l2_data          (write_l2_data_c),
        // // Request Read Port to L2
        // .request_l2_valid       (dcache_valid_i),
        // .request_l2_addr        (dcache_address_i),
        // // Update Port from L2
        // .update_l2_valid        (dcache_valid_o),
        // .update_l2_addr         (dcache_address_o),
        // .update_l2_data         (dcache_data_o)
    );

    assign icache_awlock=0;
    assign icache_awcache=4'd0;
    assign icache_awprot=3'd0;
    assign icache_awregion=4'd0;
    assign icache_awqos=4'd0;
    assign icache_awuser=0;
    assign icache_arlock=0;
    assign icache_arcache=4'd0;
    assign icache_arprot=3'd0;
    assign icache_arregion=4'd0;
    assign icache_arqos=4'd0;
    assign icache_aruser=0;
    assign icache_wuser=0;
    //assign icache_buser=0;
    //assign icache_ruser=0;
    assign dcache_awlock=0;
    assign dcache_awcache=4'd0;
    assign dcache_awprot=3'd0;
    assign dcache_awregion=4'd0;
    assign dcache_awqos=4'd0;
    assign dcache_awuser=0;
    assign dcache_arlock=0;
    assign dcache_arcache=4'd0;
    assign dcache_arprot=3'd0;
    assign dcache_arregion=4'd0;
    assign dcache_arqos=4'd0;
    assign dcache_aruser=0;
    assign dcache_wuser=0;
    //assign dcache_buser=0;
    //assign dcache_ruser=0;
    assign mem_one_awlock=0;
    assign mem_one_awcache=4'd0;
    assign mem_one_awprot=3'd0;
    assign mem_one_awregion=4'd0;
    assign mem_one_awqos=4'd0;
    assign mem_one_awuser=0;
    assign mem_one_arlock=0;
    assign mem_one_arcache=4'd0;
    assign mem_one_arprot=3'd0;
    assign mem_one_arregion=4'd0;
    assign mem_one_arqos=4'd0;
    assign mem_one_aruser=0;
    assign mem_one_wuser=0;
    assign mem_one_buser=0;
    assign mem_one_ruser=0;

    //////////////////////
    //   Interconnect   //
    //////////////////////
    
    AXI_BUS #(
        .AXI_ADDR_WIDTH ( AXI_ADDR_WIDTH      ),
        .AXI_DATA_WIDTH ( AXI_DATA_WIDTH      ),
        .AXI_ID_WIDTH   ( AXI_ID_WIDTH+1 ),
        .AXI_USER_WIDTH ( AXI_USER_WIDTH      )
    ) mem_one_slv_bus ();

    axi_intercon axi_intercon (
        .clk_i              (clk),
        .rst_ni             (rst_n),
        .i_icache_awid      (icache_awid),
        .i_icache_awaddr    (icache_awaddr),
        .i_icache_awlen     (icache_awlen),
        .i_icache_awsize    (icache_awsize),
        .i_icache_awburst   (icache_awburst),
        .i_icache_awlock    (icache_awlock),
        .i_icache_awcache   (icache_awcache),
        .i_icache_awprot    (icache_awprot),
        .i_icache_awregion  (icache_awregion),
        .i_icache_awuser    (icache_awuser),
        .i_icache_awqos     (icache_awqos),
        .i_icache_awvalid   (icache_awvalid),
        .o_icache_awready   (icache_awready),
        .i_icache_arid      (icache_arid),
        .i_icache_araddr    (icache_araddr),
        .i_icache_arlen     (icache_arlen),
        .i_icache_arsize    (icache_arsize),
        .i_icache_arburst   (icache_arburst),
        .i_icache_arlock    (icache_arlock),
        .i_icache_arcache   (icache_arcache),
        .i_icache_arprot    (icache_arprot),
        .i_icache_arregion  (icache_arregion),
        .i_icache_aruser    (icache_aruser),
        .i_icache_arqos     (icache_arqos),
        .i_icache_arvalid   (icache_arvalid),
        .o_icache_arready   (icache_arready),
        .i_icache_wdata     (icache_wdata),
        .i_icache_wstrb     (icache_wstrb),
        .i_icache_wlast     (icache_wlast),
        .i_icache_wuser     (icache_wuser),
        .i_icache_wvalid    (icache_wvalid),
        .o_icache_wready    (icache_wready),
        .o_icache_bid       (icache_bid),
        .o_icache_bresp     (icache_bresp),
        .o_icache_bvalid    (icache_bvalid),
        .o_icache_buser     (icache_buser),
        .i_icache_bready    (icache_bready),
        .o_icache_rid       (icache_rid),
        .o_icache_rdata     (icache_rdata),
        .o_icache_rresp     (icache_rresp),
        .o_icache_rlast     (icache_rlast),
        .o_icache_ruser     (icache_ruser),
        .o_icache_rvalid    (icache_rvalid),
        .i_icache_rready    (icache_rready),
        .i_dcache_awid      (dcache_awid),
        .i_dcache_awaddr    (dcache_awaddr),
        .i_dcache_awlen     (dcache_awlen),
        .i_dcache_awsize    (dcache_awsize),
        .i_dcache_awburst   (dcache_awburst),
        .i_dcache_awlock    (dcache_awlock),
        .i_dcache_awcache   (dcache_awcache),
        .i_dcache_awprot    (dcache_awprot),
        .i_dcache_awregion  (dcache_awregion),
        .i_dcache_awuser    (dcache_awuser),
        .i_dcache_awqos     (dcache_awqos),
        .i_dcache_awvalid   (dcache_awvalid),
        .o_dcache_awready   (dcache_awready),
        .i_dcache_arid      (dcache_arid),
        .i_dcache_araddr    (dcache_araddr),
        .i_dcache_arlen     (dcache_arlen),
        .i_dcache_arsize    (dcache_arsize),
        .i_dcache_arburst   (dcache_arburst),
        .i_dcache_arlock    (dcache_arlock),
        .i_dcache_arcache   (dcache_arcache),
        .i_dcache_arprot    (dcache_arprot),
        .i_dcache_arregion  (dcache_arregion),
        .i_dcache_aruser    (dcache_aruser),
        .i_dcache_arqos     (dcache_arqos),
        .i_dcache_arvalid   (dcache_arvalid),
        .o_dcache_arready   (dcache_arready),
        .i_dcache_wdata     (dcache_wdata),
        .i_dcache_wstrb     (dcache_wstrb),
        .i_dcache_wlast     (dcache_wlast),
        .i_dcache_wuser     (dcache_wuser),
        .i_dcache_wvalid    (dcache_wvalid),
        .o_dcache_wready    (dcache_wready),
        .o_dcache_bid       (dcache_bid),
        .o_dcache_bresp     (dcache_bresp),
        .o_dcache_bvalid    (dcache_bvalid),
        .o_dcache_buser     (dcache_buser),
        .i_dcache_bready    (dcache_bready),
        .o_dcache_rid       (dcache_rid),
        .o_dcache_rdata     (dcache_rdata),
        .o_dcache_rresp     (dcache_rresp),
        .o_dcache_rlast     (dcache_rlast),
        .o_dcache_ruser     (dcache_ruser),
        .o_dcache_rvalid    (dcache_rvalid),
        .i_dcache_rready    (dcache_rready),
        .o_mem_one_awid     (mem_one_slv_bus.aw_id),
        .o_mem_one_awaddr   (mem_one_slv_bus.aw_addr),
        .o_mem_one_awlen    (mem_one_slv_bus.aw_len),
        .o_mem_one_awsize   (mem_one_slv_bus.aw_size),
        .o_mem_one_awburst  (mem_one_slv_bus.aw_burst),
        .o_mem_one_awlock   (mem_one_slv_bus.aw_lock),
        .o_mem_one_awcache  (mem_one_slv_bus.aw_cache),
        .o_mem_one_awprot   (mem_one_slv_bus.aw_prot),
        .o_mem_one_awregion (mem_one_slv_bus.aw_region),
        .o_mem_one_awuser   (mem_one_slv_bus.aw_user),
        .o_mem_one_awqos    (mem_one_slv_bus.aw_qos),
        .o_mem_one_awvalid  (mem_one_slv_bus.aw_valid),
        .i_mem_one_awready  (mem_one_slv_bus.aw_ready),
        .o_mem_one_arid     (mem_one_slv_bus.ar_id),
        .o_mem_one_araddr   (mem_one_slv_bus.ar_addr),
        .o_mem_one_arlen    (mem_one_slv_bus.ar_len),
        .o_mem_one_arsize   (mem_one_slv_bus.ar_size),
        .o_mem_one_arburst  (mem_one_slv_bus.ar_burst),
        .o_mem_one_arlock   (mem_one_slv_bus.ar_lock),
        .o_mem_one_arcache  (mem_one_slv_bus.ar_cache),
        .o_mem_one_arprot   (mem_one_slv_bus.ar_prot),
        .o_mem_one_arregion (mem_one_slv_bus.ar_region),
        .o_mem_one_aruser   (mem_one_slv_bus.ar_user),
        .o_mem_one_arqos    (mem_one_slv_bus.ar_qos),
        .o_mem_one_arvalid  (mem_one_slv_bus.ar_valid),
        .i_mem_one_arready  (mem_one_slv_bus.ar_ready),
        .o_mem_one_wdata    (mem_one_slv_bus.w_data),
        .o_mem_one_wstrb    (mem_one_slv_bus.w_strb),
        .o_mem_one_wlast    (mem_one_slv_bus.w_last),
        .o_mem_one_wuser    (mem_one_slv_bus.w_user),
        .o_mem_one_wvalid   (mem_one_slv_bus.w_valid),
        .i_mem_one_wready   (mem_one_slv_bus.w_ready),
        .i_mem_one_bid      (mem_one_slv_bus.b_id),
        .i_mem_one_bresp    (mem_one_slv_bus.b_resp),
        .i_mem_one_bvalid   (mem_one_slv_bus.b_valid),
        .i_mem_one_buser    (mem_one_slv_bus.b_user),
        .o_mem_one_bready   (mem_one_slv_bus.b_ready),
        .i_mem_one_rid      (mem_one_slv_bus.r_id),
        .i_mem_one_rdata    (mem_one_slv_bus.r_data),
        .i_mem_one_rresp    (mem_one_slv_bus.r_resp),
        .i_mem_one_rlast    (mem_one_slv_bus.r_last),
        .i_mem_one_ruser    (mem_one_slv_bus.r_user),
        .i_mem_one_rvalid   (mem_one_slv_bus.r_valid),
        .o_mem_one_rready   (mem_one_slv_bus.r_ready));

    assign mem_one_slv_bus.aw_atop = 6'd0;

    /////////////////////////
    // axi_mem_sim (ram) 1 //
    /////////////////////////


    // assign mem_one_awid     = mem_one_slv_bus.aw_id;
    // assign mem_one_awaddr   = mem_one_slv_bus.aw_addr;
    // assign mem_one_awlen    = mem_one_slv_bus.aw_len;
    // assign mem_one_awsize   = mem_one_slv_bus.aw_size;
    // assign mem_one_awburst  = mem_one_slv_bus.aw_burst;
    // assign mem_one_awlock   = mem_one_slv_bus.aw_lock;
    // assign mem_one_awcache  = mem_one_slv_bus.aw_cache;
    // assign mem_one_awprot   = mem_one_slv_bus.aw_prot;
    // assign mem_one_awregion = mem_one_slv_bus.aw_region;
    // assign mem_one_awuser   = mem_one_slv_bus.aw_user;
    // assign mem_one_awqos    = mem_one_slv_bus.aw_qos;
    // assign mem_one_awvalid  = mem_one_slv_bus.aw_valid;
    // assign mem_one_awready  = mem_one_slv_bus.aw_ready;
    // assign mem_one_arid     = mem_one_slv_bus.ar_id;
    // assign mem_one_araddr   = mem_one_slv_bus.ar_addr;
    // assign mem_one_arlen    = mem_one_slv_bus.ar_len;
    // assign mem_one_arsize   = mem_one_slv_bus.ar_size;
    // assign mem_one_arburst  = mem_one_slv_bus.ar_burst;
    // assign mem_one_arlock   = mem_one_slv_bus.ar_lock;
    // assign mem_one_arcache  = mem_one_slv_bus.ar_cache;
    // assign mem_one_arprot   = mem_one_slv_bus.ar_prot;
    // assign mem_one_arregion = mem_one_slv_bus.ar_region;
    // assign mem_one_aruser   = mem_one_slv_bus.ar_user;
    // assign mem_one_arqos    = mem_one_slv_bus.ar_qos;
    // assign mem_one_arvalid  = mem_one_slv_bus.ar_valid;
    // assign mem_one_arready  = mem_one_slv_bus.ar_ready;
    // assign mem_one_wdata    = mem_one_slv_bus.w_data;
    // assign mem_one_wstrb    = mem_one_slv_bus.w_strb;
    // assign mem_one_wlast    = mem_one_slv_bus.w_last;
    // assign mem_one_wuser    = mem_one_slv_bus.w_user;
    // assign mem_one_wvalid   = mem_one_slv_bus.w_valid;
    // assign mem_one_wready   = mem_one_slv_bus.w_ready;
    // assign mem_one_rid      = mem_one_slv_bus.r_id;
    // assign mem_one_rdata    = mem_one_slv_bus.r_data;
    // assign mem_one_rlast    = mem_one_slv_bus.r_last;
    // assign mem_one_ruser    = mem_one_slv_bus.r_user;
    // assign mem_one_rvalid   = mem_one_slv_bus.r_valid;
    // assign mem_one_rready   = mem_one_slv_bus.r_ready;
    // assign mem_one_bid      = mem_one_slv_bus.b_id;
    // assign mem_one_bresp    = mem_one_slv_bus.b_resp;
    // assign mem_one_buser    = mem_one_slv_bus.b_user;
    // assign mem_one_bvalid   = mem_one_slv_bus.b_valid;
    // assign mem_one_bready   = mem_one_slv_bus.b_ready;

    axi_sim_mem_intf #(
        .AXI_ADDR_WIDTH      (AXI_ADDR_WIDTH),
        .AXI_DATA_WIDTH      (AXI_DATA_WIDTH),
        .AXI_ID_WIDTH        (AXI_ID_WIDTH),
        .AXI_USER_WIDTH      (AXI_USER_WIDTH),
        .WARN_UNINITIALIZED  (WARN_UNINITIALIZED),
        .APPL_DELAY          (APPL_DELAY),
        .ACQ_DELAY           (ACQ_DELAY)
    ) i_axi_sim_mem_intf (
        .clk_i              (clk),
        .rst_ni             (rst_n),
        .axi_slv            (mem_one_slv_bus),
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

    //=====================================================================
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