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

    wire  [3:0] icache_awid;
    wire [31:0] icache_awaddr;
    wire  [7:0] icache_awlen;
    wire  [2:0] icache_awsize;
    wire  [1:0] icache_awburst;
    wire        icache_awlock;
    wire  [3:0] icache_awcache;
    wire  [2:0] icache_awprot;
    wire  [3:0] icache_awregion;
    wire  [0:0] icache_awuser;
    wire  [3:0] icache_awqos;
    wire        icache_awvalid;
    wire        icache_awready;
    wire  [3:0] icache_arid;
    wire [31:0] icache_araddr;
    wire  [7:0] icache_arlen;
    wire  [2:0] icache_arsize;
    wire  [1:0] icache_arburst;
    wire        icache_arlock;
    wire  [3:0] icache_arcache;
    wire  [2:0] icache_arprot;
    wire  [3:0] icache_arregion;
    wire  [0:0] icache_aruser;
    wire  [3:0] icache_arqos;
    wire        icache_arvalid;
    wire        icache_arready;
    wire [31:0] icache_wdata;
    wire  [3:0] icache_wstrb;
    wire        icache_wlast;
    wire  [0:0] icache_wuser;
    wire        icache_wvalid;
    wire        icache_wready;
    wire  [3:0] icache_bid;
    wire  [1:0] icache_bresp;
    wire        icache_bvalid;
    wire  [0:0] icache_buser;
    wire        icache_bready;
    wire  [3:0] icache_rid;
    wire [31:0] icache_rdata;
    wire  [1:0] icache_rresp;
    wire        icache_rlast;
    wire  [0:0] icache_ruser;
    wire        icache_rvalid;
    wire        icache_rready;
    wire  [3:0] dcache_awid;
    wire [31:0] dcache_awaddr;
    wire  [7:0] dcache_awlen;
    wire  [2:0] dcache_awsize;
    wire  [1:0] dcache_awburst;
    wire        dcache_awlock;
    wire  [3:0] dcache_awcache;
    wire  [2:0] dcache_awprot;
    wire  [3:0] dcache_awregion;
    wire  [0:0] dcache_awuser;
    wire  [3:0] dcache_awqos;
    wire        dcache_awvalid;
    wire        dcache_awready;
    wire  [3:0] dcache_arid;
    wire [31:0] dcache_araddr;
    wire  [7:0] dcache_arlen;
    wire  [2:0] dcache_arsize;
    wire  [1:0] dcache_arburst;
    wire        dcache_arlock;
    wire  [3:0] dcache_arcache;
    wire  [2:0] dcache_arprot;
    wire  [3:0] dcache_arregion;
    wire  [0:0] dcache_aruser;
    wire  [3:0] dcache_arqos;
    wire        dcache_arvalid;
    wire        dcache_arready;
    wire [31:0] dcache_wdata;
    wire  [3:0] dcache_wstrb;
    wire        dcache_wlast;
    wire  [0:0] dcache_wuser;
    wire        dcache_wvalid;
    wire        dcache_wready;
    wire  [3:0] dcache_bid;
    wire  [1:0] dcache_bresp;
    wire        dcache_bvalid;
    wire  [0:0] dcache_buser;
    wire        dcache_bready;
    wire  [3:0] dcache_rid;
    wire [31:0] dcache_rdata;
    wire  [1:0] dcache_rresp;
    wire        dcache_rlast;
    wire  [0:0] dcache_ruser;
    wire        dcache_rvalid;
    wire        dcache_rready;
    wire  [4:0] mem_one_awid;
    wire [31:0] mem_one_awaddr;
    wire  [7:0] mem_one_awlen;
    wire  [2:0] mem_one_awsize;
    wire  [1:0] mem_one_awburst;
    wire        mem_one_awlock;
    wire  [3:0] mem_one_awcache;
    wire  [2:0] mem_one_awprot;
    wire  [3:0] mem_one_awregion;
    wire  [0:0] mem_one_awuser;
    wire  [3:0] mem_one_awqos;
    wire        mem_one_awvalid;
    wire        mem_one_awready;
    wire  [4:0] mem_one_arid;
    wire [31:0] mem_one_araddr;
    wire  [7:0] mem_one_arlen;
    wire  [2:0] mem_one_arsize;
    wire  [1:0] mem_one_arburst;
    wire        mem_one_arlock;
    wire  [3:0] mem_one_arcache;
    wire  [2:0] mem_one_arprot;
    wire  [3:0] mem_one_arregion;
    wire  [0:0] mem_one_aruser;
    wire  [3:0] mem_one_arqos;
    wire        mem_one_arvalid;
    wire        mem_one_arready;
    wire [31:0] mem_one_wdata;
    wire  [3:0] mem_one_wstrb;
    wire        mem_one_wlast;
    wire  [0:0] mem_one_wuser;
    wire        mem_one_wvalid;
    wire        mem_one_wready;
    wire  [4:0] mem_one_bid;
    wire  [1:0] mem_one_bresp;
    wire        mem_one_bvalid;
    wire  [0:0] mem_one_buser;
    wire        mem_one_bready;
    wire  [4:0] mem_one_rid;
    wire [31:0] mem_one_rdata;
    wire  [1:0] mem_one_rresp;
    wire        mem_one_rlast;
    wire  [0:0] mem_one_ruser;
    wire        mem_one_rvalid;
    wire        mem_one_rready;


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

        .ic_m_axi_awvalid       (icache_awvalid)
        .ic_m_axi_awready       (icache_awready)
        .ic_m_axi_awaddr        (icache_awaddr)
        .ic_m_axi_awburst       (icache_awburst)
        .ic_m_axi_awlen         (icache_awlen)
        .ic_m_axi_awsize        (icache_awsize)
        .ic_m_axi_awid          (icache_awid)
        .ic_m_axi_wvalid        (icache_wvalid)
        .ic_m_axi_wready        (icache_wready)
        .ic_m_axi_wdata         (icache_wdata)
        .ic_m_axi_wlast         (icache_wlast)
        .ic_m_axi_wstrb         (icache_wstrb)
        .ic_m_axi_bid           (icache_bid)
        .ic_m_axi_bresp         (icache_bresp)
        .ic_m_axi_bvalid        (icache_bvalid)
        .ic_m_axi_bready        (icache_bready)
        .ic_m_axi_arready       (icache_arready)
        .ic_m_axi_arvalid       (icache_arvalid)
        .ic_m_axi_araddr        (icache_araddr)
        .ic_m_axi_arburst       (icache_arburst)
        .ic_m_axi_arlen         (icache_arlen)
        .ic_m_axi_arsize        (icache_arsize)
        .ic_m_axi_arid          (icache_arid)
        .ic_m_axi_rdata         (icache_rdata)
        .ic_m_axi_rlast         (icache_rlast)
        .ic_m_axi_rid           (icache_rid)
        .ic_m_axi_rresp         (icache_rresp)
        .ic_m_axi_rvalid        (icache_rvalid)
        .ic_m_axi_rready        (icache_rready)

        .dc_m_axi_awvalid       (dcache_awvalid)
        .dc_m_axi_awready       (dcache_awready)
        .dc_m_axi_awaddr        (dcache_awaddr)
        .dc_m_axi_awburst       (dcache_awburst)
        .dc_m_axi_awlen         (dcache_awlen)
        .dc_m_axi_awsize        (dcache_awsize)
        .dc_m_axi_awid          (dcache_awid)
        .dc_m_axi_wvalid        (dcache_wvalid)
        .dc_m_axi_wready        (dcache_wready)
        .dc_m_axi_wdata         (dcache_wdata)
        .dc_m_axi_wlast         (dcache_wlast)
        .dc_m_axi_wstrb         (dcache_wstrb)
        .dc_m_axi_bid           (dcache_bid)
        .dc_m_axi_bresp         (dcache_bresp)
        .dc_m_axi_bvalid        (dcache_bvalid)
        .dc_m_axi_bready        (dcache_bready)
        .dc_m_axi_arready       (dcache_arready)
        .dc_m_axi_arvalid       (dcache_arvalid)
        .dc_m_axi_araddr        (dcache_araddr)
        .dc_m_axi_arburst       (dcache_arburst)
        .dc_m_axi_arlen         (dcache_arlen)
        .dc_m_axi_arsize        (dcache_arsize)
        .dc_m_axi_arid          (dcache_arid)
        .dc_m_axi_rdata         (dcache_rdata)
        .dc_m_axi_rlast         (dcache_rlast)
        .dc_m_axi_rid           (dcache_rid)
        .dc_m_axi_rresp         (dcache_rresp)
        .dc_m_axi_rvalid        (dcache_rvalid)
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
    assign icache_buser=0;
    assign icache_ruser=0;
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
    assign dcache_buser=0;
    assign dcache_ruser=0;
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
        .o_mem_one_awid     (mem_one_awid),
        .o_mem_one_awaddr   (mem_one_awaddr),
        .o_mem_one_awlen    (mem_one_awlen),
        .o_mem_one_awsize   (mem_one_awsize),
        .o_mem_one_awburst  (mem_one_awburst),
        .o_mem_one_awlock   (mem_one_awlock),
        .o_mem_one_awcache  (mem_one_awcache),
        .o_mem_one_awprot   (mem_one_awprot),
        .o_mem_one_awregion (mem_one_awregion),
        .o_mem_one_awuser   (mem_one_awuser),
        .o_mem_one_awqos    (mem_one_awqos),
        .o_mem_one_awvalid  (mem_one_awvalid),
        .i_mem_one_awready  (mem_one_awready),
        .o_mem_one_arid     (mem_one_arid),
        .o_mem_one_araddr   (mem_one_araddr),
        .o_mem_one_arlen    (mem_one_arlen),
        .o_mem_one_arsize   (mem_one_arsize),
        .o_mem_one_arburst  (mem_one_arburst),
        .o_mem_one_arlock   (mem_one_arlock),
        .o_mem_one_arcache  (mem_one_arcache),
        .o_mem_one_arprot   (mem_one_arprot),
        .o_mem_one_arregion (mem_one_arregion),
        .o_mem_one_aruser   (mem_one_aruser),
        .o_mem_one_arqos    (mem_one_arqos),
        .o_mem_one_arvalid  (mem_one_arvalid),
        .i_mem_one_arready  (mem_one_arready),
        .o_mem_one_wdata    (mem_one_wdata),
        .o_mem_one_wstrb    (mem_one_wstrb),
        .o_mem_one_wlast    (mem_one_wlast),
        .o_mem_one_wuser    (mem_one_wuser),
        .o_mem_one_wvalid   (mem_one_wvalid),
        .i_mem_one_wready   (mem_one_wready),
        .i_mem_one_bid      (mem_one_bid),
        .i_mem_one_bresp    (mem_one_bresp),
        .i_mem_one_bvalid   (mem_one_bvalid),
        .i_mem_one_buser    (mem_one_buser),
        .o_mem_one_bready   (mem_one_bready),
        .i_mem_one_rid      (mem_one_rid),
        .i_mem_one_rdata    (mem_one_rdata),
        .i_mem_one_rresp    (mem_one_rresp),
        .i_mem_one_rlast    (mem_one_rlast),
        .i_mem_one_ruser    (mem_one_ruser),
        .i_mem_one_rvalid   (mem_one_rvalid),
        .o_mem_one_rready   (mem_one_rready));

    /////////////////////////
    // axi_mem_sim (ram) 1 //
    /////////////////////////

    AXI_BUS #(
        .AXI_ADDR_WIDTH ( AXI_ADDR_WIDTH      ),
        .AXI_DATA_WIDTH ( AXI_DATA_WIDTH      ),
        .AXI_ID_WIDTH   ( AXI_ID_WIDTH ),
        .AXI_USER_WIDTH ( AXI_USER_WIDTH      )
    ) mem_one_slv_bus ();

    assign mem_one_slv_bus.aw.atop = 6'd0;
    assign mem_one_slv_bus.aw_id        = mem_one_awid;
    assign mem_one_slv_bus.aw_addr      = mem_one_awaddr;
    assign mem_one_slv_bus.aw_len       = mem_one_awlen;
    assign mem_one_slv_bus.aw_size      = mem_one_awsize;
    assign mem_one_slv_bus.aw_burst     = mem_one_awburst;
    assign mem_one_slv_bus.aw_lock      = mem_one_awlock;
    assign mem_one_slv_bus.aw_cache     = mem_one_awcache;
    assign mem_one_slv_bus.aw_prot      = mem_one_awprot;
    assign mem_one_slv_bus.aw_region    = mem_one_awregion;
    assign mem_one_slv_bus.aw_user      = mem_one_awuser;
    assign mem_one_slv_bus.aw_qos       = mem_one_awqos;
    assign mem_one_slv_bus.aw_valid     = mem_one_awvalid;
    assign mem_one_slv_bus.aw_ready     = mem_one_awready;
    assign mem_one_slv_bus.ar_id        = mem_one_arid;
    assign mem_one_slv_bus.ar_addr      = mem_one_araddr;
    assign mem_one_slv_bus.ar_len       = mem_one_arlen;
    assign mem_one_slv_bus.ar_size      = mem_one_arsize;
    assign mem_one_slv_bus.ar_burst     = mem_one_arburst;
    assign mem_one_slv_bus.ar_lock      = mem_one_arlock;
    assign mem_one_slv_bus.ar_cache     = mem_one_arcache;
    assign mem_one_slv_bus.ar_prot      = mem_one_arprot;
    assign mem_one_slv_bus.ar_region    = mem_one_arregion;
    assign mem_one_slv_bus.ar_user      = mem_one_aruser;
    assign mem_one_slv_bus.ar_qos       = mem_one_arqos;
    assign mem_one_slv_bus.ar_valid     = mem_one_arvalid;
    assign mem_one_slv_bus.ar_ready     = mem_one_arready;
    assign mem_one_slv_bus.w_data       = mem_one_wdata;
    assign mem_one_slv_bus.w_strb       = mem_one_wstrb;
    assign mem_one_slv_bus.w_last       = mem_one_wlast;
    assign mem_one_slv_bus.w_user       = mem_one_wuser;
    assign mem_one_slv_bus.w_valid      = mem_one_wvalid;
    assign mem_one_slv_bus.w_ready      = mem_one_wready;
    assign mem_one_slv_bus.r_id         = mem_one_rid;
    assign mem_one_slv_bus.r_data       = mem_one_rdata;
    assign mem_one_slv_bus.r_strb       = mem_one_rstrb;
    assign mem_one_slv_bus.r_last       = mem_one_rlast;
    assign mem_one_slv_bus.r_user       = mem_one_ruser;
    assign mem_one_slv_bus.r_valid      = mem_one_rvalid;
    assign mem_one_slv_bus.r_ready      = mem_one_rready;
    assign mem_one_slv_bus.b_id         = mem_one_bid;
    assign mem_one_slv_bus.b_resp       = mem_one_bresp;
    assign mem_one_slv_bus.b_user       = mem_one_buser;
    assign mem_one_slv_bus.b_valid      = mem_one_bvalid;
    assign mem_one_slv_bus.b_ready      = mem_one_bready;

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
    )

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