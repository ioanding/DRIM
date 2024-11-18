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

`include "axi/typedef.svh"
`include "axi/assign.svh"

// AXI Interconnect utilizing a crossbar with mapped memory addresses

module axi_intercon #(
  parameter int unsigned UNQ_ADDR_SPC      = 32'h10000000,
  parameter int unsigned NoSlaves          = 32'd1,    // How many Axi Slaves  there are
  parameter int unsigned AxiDataWidth      = 32'd32,    // Axi Data Width
  parameter int unsigned AxiIdWidthMasters = 32'd4,
  parameter int unsigned AxiIdUsed         = 32'd4, // Has to be <= AxiIdWidthMasters
  parameter int unsigned AxiUserWidth      = 32'd1
) (
    input  logic    clk_i,
    input  logic    rst_ni,
    AXI_BUS.Slave   ic_slv_port,
    AXI_BUS.Slave   dc_slv_port,
    AXI_BUS.Master  mem_mst_port [NoSlaves-1:0]);


  // axi configuration
  localparam int unsigned NoMasters        = 32'd2;    // How many Axi Masters there are
  localparam int unsigned AxiAddrWidth     = 32'd32;    // Axi Address Width
  localparam int unsigned AxiIdWidthSlaves = AxiIdWidthMasters + $clog2(NoMasters);
  localparam int unsigned AxiStrbWidth     = AxiDataWidth / 8;
  localparam axi_pkg::xbar_cfg_t xbar_cfg = '{

    NoSlvPorts:         NoMasters,
    NoMstPorts:         NoSlaves,
    MaxMstTrans:        10,
    MaxSlvTrans:        6,
    FallThrough:        1'b0,
    LatencyMode:        axi_pkg::CUT_ALL_AX,
    PipelineStages:     32'd1,
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

  // Each slave has its own address range:
  localparam rule_t [xbar_cfg.NoAddrRules-1:0] AddrMap = addr_map_gen();

  function rule_t [xbar_cfg.NoAddrRules-1:0] addr_map_gen ();
    for (int unsigned i = 0; i < xbar_cfg.NoAddrRules; i++) begin
      addr_map_gen[i] = rule_t'{
        idx:        unsigned'(i),
        start_addr:  i    * UNQ_ADDR_SPC,
        end_addr:   (i+1) * UNQ_ADDR_SPC,
        default:    '0
      };
    end
  endfunction

   slv_req_t  [NoMasters-1:0] masters_req;
   slv_resp_t [NoMasters-1:0] masters_resp;
   mst_req_t  [NoSlaves-1:0] slaves_req;
   mst_resp_t [NoSlaves-1:0] slaves_resp;

  // Static assignment from IC and DC
  `AXI_ASSIGN_TO_REQ(masters_req[0], ic_slv_port)
  `AXI_ASSIGN_FROM_RESP(ic_slv_port, masters_resp[0])
  `AXI_ASSIGN_TO_REQ(masters_req[1], dc_slv_port)
  `AXI_ASSIGN_FROM_RESP(dc_slv_port, masters_resp[1])

  for (genvar i = 0; i < NoSlaves; i++) begin : gen_conn_mem_slaves
    `AXI_ASSIGN_FROM_REQ(mem_mst_port[i], slaves_req[i])
    `AXI_ASSIGN_TO_RESP(slaves_resp[i], mem_mst_port[i])
  end

axi_xbar #(
    .Cfg           ( xbar_cfg      ),
    .ATOPs         ( 1'b0          ),
    .slv_aw_chan_t ( aw_chan_mst_t ),
    .mst_aw_chan_t ( aw_chan_slv_t ),
    .w_chan_t      ( w_chan_t      ),
    .slv_b_chan_t  ( b_chan_mst_t  ),
    .mst_b_chan_t  ( b_chan_slv_t  ),
    .slv_ar_chan_t ( ar_chan_mst_t ),
    .mst_ar_chan_t ( ar_chan_slv_t ),
    .slv_r_chan_t  ( r_chan_mst_t  ),
    .mst_r_chan_t  ( r_chan_slv_t  ),
    .slv_req_t     ( slv_req_t     ),
    .slv_resp_t    ( slv_resp_t    ),
    .mst_req_t     ( mst_req_t     ),
    .mst_resp_t    ( mst_resp_t    ),
    .rule_t        ( rule_t        )
  ) axi_xbar (
    .clk_i                 ( clk_i        ),
    .rst_ni                ( rst_ni       ),
    .test_i                ( 1'b0         ),
    .slv_ports_req_i       ( masters_req  ),
    .slv_ports_resp_o      ( masters_resp ),
    .mst_ports_req_o       ( slaves_req   ),
    .mst_ports_resp_i      ( slaves_resp  ),
    .addr_map_i            ( AddrMap      ),
    .en_default_mst_port_i ( 2'd0         ),
    .default_mst_port_i    ( '0           )
  );
endmodule
