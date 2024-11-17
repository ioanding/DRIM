`include "axi/typedef.svh"
module axi_intercon
   (input  logic        clk_i,
    input  logic        rst_ni,
    input  logic  [3:0] i_icache_awid,
    input  logic [31:0] i_icache_awaddr,
    input  logic  [7:0] i_icache_awlen,
    input  logic  [2:0] i_icache_awsize,
    input  logic  [1:0] i_icache_awburst,
    input  logic        i_icache_awlock,
    input  logic  [3:0] i_icache_awcache,
    input  logic  [2:0] i_icache_awprot,
    input  logic  [3:0] i_icache_awregion,
    input  logic  [3:0] i_icache_awqos,
    input  logic        i_icache_awvalid,
    output logic        o_icache_awready,
    input  logic  [3:0] i_icache_arid,
    input  logic [31:0] i_icache_araddr,
    input  logic  [7:0] i_icache_arlen,
    input  logic  [2:0] i_icache_arsize,
    input  logic  [1:0] i_icache_arburst,
    input  logic        i_icache_arlock,
    input  logic  [3:0] i_icache_arcache,
    input  logic  [2:0] i_icache_arprot,
    input  logic  [3:0] i_icache_arregion,
    input  logic  [3:0] i_icache_arqos,
    input  logic        i_icache_arvalid,
    output logic        o_icache_arready,
    input  logic [63:0] i_icache_wdata,
    input  logic  [7:0] i_icache_wstrb,
    input  logic        i_icache_wlast,
    input  logic        i_icache_wvalid,
    output logic        o_icache_wready,
    output logic  [3:0] o_icache_bid,
    output logic  [1:0] o_icache_bresp,
    output logic        o_icache_bvalid,
    input  logic        i_icache_bready,
    output logic  [3:0] o_icache_rid,
    output logic [63:0] o_icache_rdata,
    output logic  [1:0] o_icache_rresp,
    output logic        o_icache_rlast,
    output logic        o_icache_rvalid,
    input  logic        i_icache_rready,
    input  logic  [3:0] i_dcache_awid,
    input  logic [31:0] i_dcache_awaddr,
    input  logic  [7:0] i_dcache_awlen,
    input  logic  [2:0] i_dcache_awsize,
    input  logic  [1:0] i_dcache_awburst,
    input  logic        i_dcache_awlock,
    input  logic  [3:0] i_dcache_awcache,
    input  logic  [2:0] i_dcache_awprot,
    input  logic  [3:0] i_dcache_awregion,
    input  logic  [3:0] i_dcache_awqos,
    input  logic        i_dcache_awvalid,
    output logic        o_dcache_awready,
    input  logic  [3:0] i_dcache_arid,
    input  logic [31:0] i_dcache_araddr,
    input  logic  [7:0] i_dcache_arlen,
    input  logic  [2:0] i_dcache_arsize,
    input  logic  [1:0] i_dcache_arburst,
    input  logic        i_dcache_arlock,
    input  logic  [3:0] i_dcache_arcache,
    input  logic  [2:0] i_dcache_arprot,
    input  logic  [3:0] i_dcache_arregion,
    input  logic  [3:0] i_dcache_arqos,
    input  logic        i_dcache_arvalid,
    output logic        o_dcache_arready,
    input  logic [63:0] i_dcache_wdata,
    input  logic  [7:0] i_dcache_wstrb,
    input  logic        i_dcache_wlast,
    input  logic        i_dcache_wvalid,
    output logic        o_dcache_wready,
    output logic  [3:0] o_dcache_bid,
    output logic  [1:0] o_dcache_bresp,
    output logic        o_dcache_bvalid,
    input  logic        i_dcache_bready,
    output logic  [3:0] o_dcache_rid,
    output logic [63:0] o_dcache_rdata,
    output logic  [1:0] o_dcache_rresp,
    output logic        o_dcache_rlast,
    output logic        o_dcache_rvalid,
    input  logic        i_dcache_rready,
    output logic  [4:0] o_mem_one_awid,
    output logic [31:0] o_mem_one_awaddr,
    output logic  [7:0] o_mem_one_awlen,
    output logic  [2:0] o_mem_one_awsize,
    output logic  [1:0] o_mem_one_awburst,
    output logic        o_mem_one_awlock,
    output logic  [3:0] o_mem_one_awcache,
    output logic  [2:0] o_mem_one_awprot,
    output logic  [3:0] o_mem_one_awregion,
    output logic  [3:0] o_mem_one_awqos,
    output logic        o_mem_one_awvalid,
    input  logic        i_mem_one_awready,
    output logic  [4:0] o_mem_one_arid,
    output logic [31:0] o_mem_one_araddr,
    output logic  [7:0] o_mem_one_arlen,
    output logic  [2:0] o_mem_one_arsize,
    output logic  [1:0] o_mem_one_arburst,
    output logic        o_mem_one_arlock,
    output logic  [3:0] o_mem_one_arcache,
    output logic  [2:0] o_mem_one_arprot,
    output logic  [3:0] o_mem_one_arregion,
    output logic  [3:0] o_mem_one_arqos,
    output logic        o_mem_one_arvalid,
    input  logic        i_mem_one_arready,
    output logic [63:0] o_mem_one_wdata,
    output logic  [7:0] o_mem_one_wstrb,
    output logic        o_mem_one_wlast,
    output logic        o_mem_one_wvalid,
    input  logic        i_mem_one_wready,
    input  logic  [4:0] i_mem_one_bid,
    input  logic  [1:0] i_mem_one_bresp,
    input  logic        i_mem_one_bvalid,
    output logic        o_mem_one_bready,
    input  logic  [4:0] i_mem_one_rid,
    input  logic [63:0] i_mem_one_rdata,
    input  logic  [1:0] i_mem_one_rresp,
    input  logic        i_mem_one_rlast,
    input  logic        i_mem_one_rvalid,
    output logic        o_mem_one_rready);


  localparam int unsigned NoMasters   = 32'd2;    // How many Axi Masters there are
  localparam int unsigned NoSlaves    = 32'd1;    // How many Axi Slaves  there are

  // axi configuration
  localparam int unsigned AxiIdWidthMasters =  32'd4;
  localparam int unsigned AxiIdUsed         =  32'd4; // Has to be <= AxiIdWidthMasters
  localparam int unsigned AxiIdWidthSlaves  =  AxiIdWidthMasters + $clog2(NoMasters);
  localparam int unsigned AxiAddrWidth      =  32'd32;    // Axi Address Width
  localparam int unsigned AxiDataWidth      =  32'd64;    // Axi Data Width
  localparam int unsigned AxiStrbWidth      =  AxiDataWidth / 8;
  localparam int unsigned AxiUserWidth      =  1;
  localparam axi_pkg::xbar_cfg_t xbar_cfg = '{

    NoSlvPorts:         NoMasters,
    NoMstPorts:         NoSlaves,
    MaxMstTrans:        10,
    MaxSlvTrans:        6,
    FallThrough:        1'b0,
    LatencyMode:        axi_pkg::CUT_ALL_AX,
    AxiIdWidthSlvPorts: AxiIdWidthMasters,
    AxiIdUsedSlvPorts:  AxiIdUsed,
    UniqueIds:          1'b0,
    AxiAddrWidth:       AxiAddrWidth,
    AxiDataWidth:       AxiDataWidth,
    NoAddrRules:        NoSlaves
  };

  typedef logic [AxiIdWidthMasters-1:0] id_mst_t;
  typedef logic [AxiIdWidthSlaves-1:0]  id_slv_t;
  typedef logic [AxiAddrWidth-1:0]      addr_t;
  typedef axi_pkg::xbar_rule_32_t       rule_t; // Has to be the same width as axi addr
  typedef logic [AxiDataWidth-1:0]      data_t;
  typedef logic [AxiStrbWidth-1:0]      strb_t;
  typedef logic [AxiUserWidth-1:0]      user_t;

  `AXI_TYPEDEF_AW_CHAN_T(aw_chan_mst_t, addr_t, id_mst_t, user_t)
  `AXI_TYPEDEF_AW_CHAN_T(aw_chan_slv_t, addr_t, id_slv_t, user_t)
  `AXI_TYPEDEF_W_CHAN_T(w_chan_t, data_t, strb_t, user_t)
  `AXI_TYPEDEF_B_CHAN_T(b_chan_mst_t, id_mst_t, user_t)
  `AXI_TYPEDEF_B_CHAN_T(b_chan_slv_t, id_slv_t, user_t)

  `AXI_TYPEDEF_AR_CHAN_T(ar_chan_mst_t, addr_t, id_mst_t, user_t)
  `AXI_TYPEDEF_AR_CHAN_T(ar_chan_slv_t, addr_t, id_slv_t, user_t)
  `AXI_TYPEDEF_R_CHAN_T(r_chan_mst_t, data_t, id_mst_t, user_t)
  `AXI_TYPEDEF_R_CHAN_T(r_chan_slv_t, data_t, id_slv_t, user_t)

  `AXI_TYPEDEF_REQ_T(slv_req_t, aw_chan_mst_t, w_chan_t, ar_chan_mst_t)
  `AXI_TYPEDEF_RESP_T(slv_resp_t, b_chan_mst_t, r_chan_mst_t)
  `AXI_TYPEDEF_REQ_T(mst_req_t, aw_chan_slv_t, w_chan_t, ar_chan_slv_t)
  `AXI_TYPEDEF_RESP_T(mst_resp_t, b_chan_slv_t, r_chan_slv_t)

  localparam rule_t [0:0] AddrMap = '{
    '{idx: 32'd0, start_addr: 32'h00000000, end_addr: 32'h10000000}};
   slv_req_t  [1:0] masters_req;
   slv_resp_t [1:0] masters_resp;
   mst_req_t  [0:0] slaves_req;
   mst_resp_t [0:0] slaves_resp;

   //Master icache
   assign masters_req[0].aw.id = i_icache_awid;
   assign masters_req[0].aw.addr = i_icache_awaddr;
   assign masters_req[0].aw.len = i_icache_awlen;
   assign masters_req[0].aw.size = i_icache_awsize;
   assign masters_req[0].aw.burst = i_icache_awburst;
   assign masters_req[0].aw.lock = i_icache_awlock;
   assign masters_req[0].aw.cache = i_icache_awcache;
   assign masters_req[0].aw.prot = i_icache_awprot;
   assign masters_req[0].aw.region = i_icache_awregion;
   assign masters_req[0].aw.qos = i_icache_awqos;
   assign masters_req[0].aw.atop = 6'd0;
   assign masters_req[0].aw_valid = i_icache_awvalid;
   assign o_icache_awready = masters_resp[0].aw_ready;
   assign masters_req[0].ar.id = i_icache_arid;
   assign masters_req[0].ar.addr = i_icache_araddr;
   assign masters_req[0].ar.len = i_icache_arlen;
   assign masters_req[0].ar.size = i_icache_arsize;
   assign masters_req[0].ar.burst = i_icache_arburst;
   assign masters_req[0].ar.lock = i_icache_arlock;
   assign masters_req[0].ar.cache = i_icache_arcache;
   assign masters_req[0].ar.prot = i_icache_arprot;
   assign masters_req[0].ar.region = i_icache_arregion;
   assign masters_req[0].ar.qos = i_icache_arqos;
   assign masters_req[0].ar_valid = i_icache_arvalid;
   assign o_icache_arready = masters_resp[0].ar_ready;
   assign masters_req[0].w.data = i_icache_wdata;
   assign masters_req[0].w.strb = i_icache_wstrb;
   assign masters_req[0].w.last = i_icache_wlast;
   assign masters_req[0].w_valid = i_icache_wvalid;
   assign o_icache_wready = masters_resp[0].w_ready;
   assign o_icache_bid = masters_resp[0].b.id;
   assign o_icache_bresp = masters_resp[0].b.resp;
   assign o_icache_bvalid = masters_resp[0].b_valid;
   assign masters_req[0].b_ready = i_icache_bready;
   assign o_icache_rid = masters_resp[0].r.id;
   assign o_icache_rdata = masters_resp[0].r.data;
   assign o_icache_rresp = masters_resp[0].r.resp;
   assign o_icache_rlast = masters_resp[0].r.last;
   assign o_icache_rvalid = masters_resp[0].r_valid;
   assign masters_req[0].r_ready = i_icache_rready;

   //Master dcache
   assign masters_req[1].aw.id = i_dcache_awid;
   assign masters_req[1].aw.addr = i_dcache_awaddr;
   assign masters_req[1].aw.len = i_dcache_awlen;
   assign masters_req[1].aw.size = i_dcache_awsize;
   assign masters_req[1].aw.burst = i_dcache_awburst;
   assign masters_req[1].aw.lock = i_dcache_awlock;
   assign masters_req[1].aw.cache = i_dcache_awcache;
   assign masters_req[1].aw.prot = i_dcache_awprot;
   assign masters_req[1].aw.region = i_dcache_awregion;
   assign masters_req[1].aw.qos = i_dcache_awqos;
   assign masters_req[1].aw.atop = 6'd0;
   assign masters_req[1].aw_valid = i_dcache_awvalid;
   assign o_dcache_awready = masters_resp[1].aw_ready;
   assign masters_req[1].ar.id = i_dcache_arid;
   assign masters_req[1].ar.addr = i_dcache_araddr;
   assign masters_req[1].ar.len = i_dcache_arlen;
   assign masters_req[1].ar.size = i_dcache_arsize;
   assign masters_req[1].ar.burst = i_dcache_arburst;
   assign masters_req[1].ar.lock = i_dcache_arlock;
   assign masters_req[1].ar.cache = i_dcache_arcache;
   assign masters_req[1].ar.prot = i_dcache_arprot;
   assign masters_req[1].ar.region = i_dcache_arregion;
   assign masters_req[1].ar.qos = i_dcache_arqos;
   assign masters_req[1].ar_valid = i_dcache_arvalid;
   assign o_dcache_arready = masters_resp[1].ar_ready;
   assign masters_req[1].w.data = i_dcache_wdata;
   assign masters_req[1].w.strb = i_dcache_wstrb;
   assign masters_req[1].w.last = i_dcache_wlast;
   assign masters_req[1].w_valid = i_dcache_wvalid;
   assign o_dcache_wready = masters_resp[1].w_ready;
   assign o_dcache_bid = masters_resp[1].b.id;
   assign o_dcache_bresp = masters_resp[1].b.resp;
   assign o_dcache_bvalid = masters_resp[1].b_valid;
   assign masters_req[1].b_ready = i_dcache_bready;
   assign o_dcache_rid = masters_resp[1].r.id;
   assign o_dcache_rdata = masters_resp[1].r.data;
   assign o_dcache_rresp = masters_resp[1].r.resp;
   assign o_dcache_rlast = masters_resp[1].r.last;
   assign o_dcache_rvalid = masters_resp[1].r_valid;
   assign masters_req[1].r_ready = i_dcache_rready;

   //Slave mem_one
   assign o_mem_one_awid = slaves_req[0].aw.id;
   assign o_mem_one_awaddr = slaves_req[0].aw.addr;
   assign o_mem_one_awlen = slaves_req[0].aw.len;
   assign o_mem_one_awsize = slaves_req[0].aw.size;
   assign o_mem_one_awburst = slaves_req[0].aw.burst;
   assign o_mem_one_awlock = slaves_req[0].aw.lock;
   assign o_mem_one_awcache = slaves_req[0].aw.cache;
   assign o_mem_one_awprot = slaves_req[0].aw.prot;
   assign o_mem_one_awregion = slaves_req[0].aw.region;
   assign o_mem_one_awqos = slaves_req[0].aw.qos;
   assign o_mem_one_awvalid = slaves_req[0].aw_valid;
   assign slaves_resp[0].aw_ready = i_mem_one_awready;
   assign o_mem_one_arid = slaves_req[0].ar.id;
   assign o_mem_one_araddr = slaves_req[0].ar.addr;
   assign o_mem_one_arlen = slaves_req[0].ar.len;
   assign o_mem_one_arsize = slaves_req[0].ar.size;
   assign o_mem_one_arburst = slaves_req[0].ar.burst;
   assign o_mem_one_arlock = slaves_req[0].ar.lock;
   assign o_mem_one_arcache = slaves_req[0].ar.cache;
   assign o_mem_one_arprot = slaves_req[0].ar.prot;
   assign o_mem_one_arregion = slaves_req[0].ar.region;
   assign o_mem_one_arqos = slaves_req[0].ar.qos;
   assign o_mem_one_arvalid = slaves_req[0].ar_valid;
   assign slaves_resp[0].ar_ready = i_mem_one_arready;
   assign o_mem_one_wdata = slaves_req[0].w.data;
   assign o_mem_one_wstrb = slaves_req[0].w.strb;
   assign o_mem_one_wlast = slaves_req[0].w.last;
   assign o_mem_one_wvalid = slaves_req[0].w_valid;
   assign slaves_resp[0].w_ready = i_mem_one_wready;
   assign slaves_resp[0].b.id = i_mem_one_bid;
   assign slaves_resp[0].b.resp = i_mem_one_bresp;
   assign slaves_resp[0].b_valid = i_mem_one_bvalid;
   assign o_mem_one_bready = slaves_req[0].b_ready;
   assign slaves_resp[0].r.id = i_mem_one_rid;
   assign slaves_resp[0].r.data = i_mem_one_rdata;
   assign slaves_resp[0].r.resp = i_mem_one_rresp;
   assign slaves_resp[0].r.last = i_mem_one_rlast;
   assign slaves_resp[0].r_valid = i_mem_one_rvalid;
   assign o_mem_one_rready = slaves_req[0].r_ready;


axi_xbar
  #(.Cfg           (xbar_cfg),
    .ATOPs         (1'b0),
    .slv_aw_chan_t (aw_chan_mst_t),
    .mst_aw_chan_t (aw_chan_slv_t),
    .w_chan_t      (w_chan_t),
    .slv_b_chan_t  (b_chan_mst_t),
    .mst_b_chan_t  (b_chan_slv_t),
    .slv_ar_chan_t (ar_chan_mst_t),
    .mst_ar_chan_t (ar_chan_slv_t),
    .slv_r_chan_t  (r_chan_mst_t),
    .mst_r_chan_t  (r_chan_slv_t),
    .slv_req_t     (slv_req_t),
    .slv_resp_t    (slv_resp_t),
    .mst_req_t     (mst_req_t),
    .mst_resp_t    (mst_resp_t),
    .rule_t        (rule_t))
 axi_xbar
   (.clk_i                 (clk_i),
    .rst_ni                (rst_ni),
    .test_i                (1'b0),
    .slv_ports_req_i       (masters_req),
    .slv_ports_resp_o      (masters_resp),
    .mst_ports_req_o       (slaves_req),
    .mst_ports_resp_i      (slaves_resp),
    .addr_map_i            (AddrMap),
    .en_default_mst_port_i (2'd0),
    .default_mst_port_i    ('0));

endmodule
