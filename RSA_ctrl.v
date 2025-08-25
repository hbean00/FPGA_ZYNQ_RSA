module RSA_ctrl #(
    parameter ADDR_bw = 13, // for FPGA BRAM ctrl
    parameter BRAM_DATA_bw = 32,
    parameter RSA_DATA_bw = 32,
    parameter MAX_DATA_NUM = 128
) (
    input CLK,
    input RSTn,

    //input control
    (* MARK_DEBUG="true" *) input wire fifo_empty,
    (* MARK_DEBUG="true" *) input wire RSA_ready,
    // (* MARK_DEBUG="true" *) input wire [RSA_DATA_bw -1 : 0] temp_data,
    (* MARK_DEBUG="true" *) input wire [RSA_DATA_bw -1 : 0] temp_exp,
    (* MARK_DEBUG="true" *) input wire exp_valid,
    (* MARK_DEBUG="true" *) input wire [RSA_DATA_bw -1 : 0] temp_mod,
    (* MARK_DEBUG="true" *) input wire mod_valid,

//    (* MARK_DEBUG="true" *) output wire [RSA_DATA_bw - 1: 0] RSA_data,
    (* MARK_DEBUG="true" *) output wire [RSA_DATA_bw - 1: 0] RSA_exp,
    (* MARK_DEBUG="true" *) output wire [RSA_DATA_bw - 1: 0] RSA_mod,
    (* MARK_DEBUG="true" *) output wire fifo_rd,
    (* MARK_DEBUG="true" *) output wire RSA_en_in,

    //output control
    (* MARK_DEBUG="true" *) output wire [ADDR_bw -1: 0] BRAM_RSA_addr,
    (* MARK_DEBUG="true" *) output wire BRAM_RSA_en,
    (* MARK_DEBUG="true" *) output wire BRAM_RSA_we
);

//input control
    // reg [RSA_DATA_bw-1 : 0] reg_data;
    reg [RSA_DATA_bw-1 : 0] reg_exp;
    reg [RSA_DATA_bw-1 : 0] reg_mod;

    reg reg_rd;
    reg data_ready; //data is ready
    reg exp_ready;
    reg mod_ready;


//output control

reg MUX_CTRL; //select MUX
reg [ADDR_bw-1:0] data_cnt;
wire rsa_we;
wire rsa_en;

wire [BRAM_DATA_bw-1 : 0] din, dout;
wire [ADDR_bw -1 : 0] addr;
wire en, we;
wire ready;
wire clr;

assign ready = RSA_ready;

//manage RSA input
always @(posedge CLK or negedge RSTn) begin
    if(~RSTn) begin
        // reg_data <= 0;
        reg_exp <= 0;
        reg_mod <=0;
        reg_rd <= 0;
        data_ready <= 0;
        exp_ready <= 0;
        mod_ready <= 0;
    end else begin
        if(exp_valid) begin
            reg_exp <= temp_exp;
            exp_ready <= 1;
        end
        if(mod_valid) begin
            reg_mod <= temp_mod;
            mod_ready <= 1;
        end
        if( ~fifo_empty && ~reg_rd && ~data_ready && ~reg_rd) begin //get data only when data is required && ~fifo_rd_rst_busy
            reg_rd <= 1;
        end else if ( reg_rd ) begin
            reg_rd <= 0;
            data_ready <= 1;
        end 
        if ( RSA_en_in ) begin
            data_ready <= 0;
        end
    end
end

// assign RSA_data = reg_data;
assign RSA_exp = reg_exp;
assign RSA_mod = reg_mod;
assign fifo_rd = reg_rd;
assign RSA_en_in = data_ready & exp_ready & mod_ready & ready;


//manage RSA output


reg ready_1d;
reg ready_valid;
always @(posedge CLK or negedge RSTn) begin
    if (~RSTn) ready_valid <= 0;
    else       ready_valid <= 1;
end 

//write RSA_result into Block Memory
//prevent nRST to posedge
always @(posedge CLK or negedge RSTn) begin
    if(~RSTn) ready_1d <= 0; 
    else begin
        ready_1d <= ready;
    end
end 
wire tic_ready = (ready_valid && ready && ~ready_1d)? 1 : 0;
always @(posedge CLK or negedge RSTn) begin
    if(~RSTn) begin
        data_cnt <= 0;
    end
    else if( tic_ready )begin
        data_cnt <= data_cnt + 1'b1;
    end
    else begin
        if( data_cnt == MAX_DATA_NUM) begin
            data_cnt <= 0;
        end
    end 
end

assign BRAM_RSA_addr = data_cnt;
assign BRAM_RSA_en = tic_ready;
assign BRAM_RSA_we = tic_ready;

endmodule