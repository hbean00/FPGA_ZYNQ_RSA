module WRAP_RSA #(
    parameter RSA_DATA_bw = 32,
    parameter BRAM_ADDR_bw = 13,
    parameter BRAM_DATA_bw = 32,
    parameter integer MAX_DATA_NUM = 128,

    parameter integer C_S00_AXI_DATA_WIDTH	= 32,
    parameter integer C_S00_AXI_ADDR_WIDTH	= 4
) (
    // Users to add ports here

    // User ports ends
    // Do not modify the ports beyond this line
    (* MARK_DEBUG="true" *)input wire CLK,
    (* MARK_DEBUG="true" *)input wire RSTn,

    (* MARK_DEBUG="true" *) input wire ENA_top,
    (* MARK_DEBUG="true" *) input wire WEA_top,
    (* MARK_DEBUG="true" *) input wire [BRAM_ADDR_bw-1:0] ADDRA_top,
    (* MARK_DEBUG="true" *) input wire [BRAM_DATA_bw-1:0] DINA_top,
    (* MARK_DEBUG="true" *) output wire [BRAM_DATA_bw-1:0] DOUTA_top,

//    (* MARK_DEBUG="true" *) output wire DONE_intr,

    // Ports of Axi Slave Bus Interface S00_AXI
    // input wire  s00_axi_aclk,
    // input wire  s00_axi_aresetn,
    input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
    input wire [2 : 0] s00_axi_awprot,
    input wire  s00_axi_awvalid,
    output wire  s00_axi_awready,
    input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
    input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
    input wire  s00_axi_wvalid,
    output wire  s00_axi_wready,
    output wire [1 : 0] s00_axi_bresp,
    output wire  s00_axi_bvalid,
    input wire  s00_axi_bready,
    input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
    input wire [2 : 0] s00_axi_arprot,
    input wire  s00_axi_arvalid,
    output wire  s00_axi_arready,
    output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
    output wire [1 : 0] s00_axi_rresp,
    output wire  s00_axi_rvalid,
    input wire  s00_axi_rready
);

//WIRE AXI
wire s00_axi_aclk = CLK;
wire s00_axi_aresetn = RSTn;
wire [RSA_DATA_bw -1 : 0] wire_exp;
wire [RSA_DATA_bw -1 : 0] wire_mod;
wire MUX;
wire exp_valid, mod_valid;


//WIRE FIFO
wire empty;
wire full;
wire [RSA_DATA_bw -1 : 0] wire_data;
wire fifo_en;
wire [RSA_DATA_bw -1 : 0] fifo_data;
wire fifo_rd;


//WIRE CONTROLLER
wire [RSA_DATA_bw-1:0] exp, mod, cypher;
wire ready;
wire ds;
wire RSA_en, RSA_we;
wire [BRAM_ADDR_bw -1 : 0] RSA_addr;


//WIRE BRAM
wire [BRAM_DATA_bw-1 : 0] din, dout;
wire [BRAM_ADDR_bw -1 : 0] addr;
wire en, we;

(* MARK_DEBUG="true" *) wire [BRAM_ADDR_bw-1:0] addra_shift = ADDRA_top >> 2; // registering ? timing ?

    myip_v1_0_S00_AXI # ( 
    .C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
    .C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
    ) myip_v1_0_S00_AXI_inst (
        //user port
    .write_en(fifo_en),
    .rsa_data(wire_data),
    .rsa_exp(wire_exp),
    .rsa_mod(wire_mod),
    .MUX_CTRL(MUX),
    .exp_valid_1(exp_valid),
    .mod_valid_1(mod_valid),
    .fifo_full(full),

        //AXI4-LITE
    .S_AXI_ACLK(s00_axi_aclk),
    .S_AXI_ARESETN(s00_axi_aresetn),
    .S_AXI_AWADDR(s00_axi_awaddr),
    .S_AXI_AWPROT(s00_axi_awprot),
    .S_AXI_AWVALID(s00_axi_awvalid),
    .S_AXI_AWREADY(s00_axi_awready),
    .S_AXI_WDATA(s00_axi_wdata),
    .S_AXI_WSTRB(s00_axi_wstrb),
    .S_AXI_WVALID(s00_axi_wvalid),
    .S_AXI_WREADY(s00_axi_wready),
    .S_AXI_BRESP(s00_axi_bresp),
    .S_AXI_BVALID(s00_axi_bvalid),
    .S_AXI_BREADY(s00_axi_bready),
    .S_AXI_ARADDR(s00_axi_araddr),
    .S_AXI_ARPROT(s00_axi_arprot),
    .S_AXI_ARVALID(s00_axi_arvalid),
    .S_AXI_ARREADY(s00_axi_arready),
    .S_AXI_RDATA(s00_axi_rdata),
    .S_AXI_RRESP(s00_axi_rresp),
    .S_AXI_RVALID(s00_axi_rvalid),
    .S_AXI_RREADY(s00_axi_rready)
    );

    fifo_generator_0 u_fifo(
    //CLK
    .clk(CLK),
    .srst(~RSTn),
    
    //FIFO_WRITE
    .full(full),
    .din(wire_data),
    .wr_en(fifo_en),

    //FIFO_READ
    .empty(empty),
    .dout(fifo_data),
    .rd_en(fifo_rd)
    );

    RSA_ctrl #(
        .ADDR_bw(BRAM_ADDR_bw),
        .BRAM_DATA_bw(BRAM_DATA_bw),
        .RSA_DATA_bw(RSA_DATA_bw),
        .MAX_DATA_NUM(MAX_DATA_NUM)
    ) u_ctrl (
        .CLK(CLK),
        .RSTn(RSTn),

        //input control
        .fifo_empty(empty),
        .RSA_ready(ready), //rsa
        // .temp_data(fifo_data),
        .temp_exp(wire_exp),
        .exp_valid(exp_valid),
        .temp_mod(wire_mod),
        .mod_valid(mod_valid),

        // .RSA_data(data), //rsa input
        .RSA_exp(exp), //rsa input
        .RSA_mod(mod), //rsa input
        .fifo_rd(fifo_rd), 
        .RSA_en_in(ds),

        //output control
        .BRAM_RSA_addr(RSA_addr),
        .BRAM_RSA_en(RSA_en),
        .BRAM_RSA_we(RSA_we)
    );

    RSACypher i_rsacyper(
    .indata(fifo_data),
    .inExp(exp),
    .inMod(mod),
    .clk(CLK),
    .ds(ds),
    .reset(~RSTn),
    .cypher(cypher),
    .ready(ready)
    );    

assign addr = (MUX) ? addra_shift : RSA_addr;
assign din = (MUX) ? DINA_top : cypher;
assign DOUTA_top = dout;
assign en = (MUX) ? ENA_top : RSA_en;
assign we = (MUX) ? WEA_top : RSA_we;

    blk_mem_gen_0 i_buffer (
        .addra(addr),
        .clka(CLK),
        .dina(din),
        .douta(dout),
        .ena(en),
        .wea(we)
    );
    
endmodule