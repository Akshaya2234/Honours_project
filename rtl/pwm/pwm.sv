`timescale 1ns / 1ps
`default_nettype none

module pwm #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input  wire                  clk,
    input  wire                  rst_n,

    // AXI4-Lite Write Interface
    input  wire [ADDR_WIDTH-1:0] s_axi_awaddr,
    input  wire                  s_axi_awvalid,
    output reg                   s_axi_awready,

    input  wire [DATA_WIDTH-1:0] s_axi_wdata,
    input  wire [3:0]            s_axi_wstrb,
    input  wire                  s_axi_wvalid,
    output reg                   s_axi_wready,

    output reg  [1:0]            s_axi_bresp,
    output reg                   s_axi_bvalid,
    input  wire                  s_axi_bready,

    // AXI4-Lite Read Interface
    input  wire [ADDR_WIDTH-1:0] s_axi_araddr,
    input  wire                  s_axi_arvalid,
    output reg                   s_axi_arready,

    output reg  [DATA_WIDTH-1:0] s_axi_rdata,
    output reg  [1:0]            s_axi_rresp,
    output reg                   s_axi_rvalid,
    input  wire                  s_axi_rready,

    // PWM Output
    output wire                  pwm_out
);

    reg        pwm_en;
    reg [31:0] pwm_period;
    reg [31:0] pwm_duty;
    reg [31:0] pwm_count;

    assign pwm_out = pwm_en && (pwm_count < pwm_duty);

    // PWM Counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pwm_count <= 32'd0;
        else if (!pwm_en || pwm_period == 0)
            pwm_count <= 32'd0;
        else if (pwm_count >= pwm_period - 1'b1)
            pwm_count <= 32'd0;
        else
            pwm_count <= pwm_count + 1'b1;
    end

    // AXI Write Interface
    reg [ADDR_WIDTH-1:0] awaddr_latched;
    reg aw_done, w_done;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_awready <= 0;
            s_axi_wready  <= 0;
            s_axi_bvalid  <= 0;
            s_axi_bresp   <= 0;
            aw_done       <= 0;
            w_done        <= 0;
            awaddr_latched <= 0;
            pwm_en        <= 0;
            pwm_period    <= 0;
            pwm_duty      <= 0;
        end else begin

            if (s_axi_awvalid && !aw_done) begin
                s_axi_awready <= 1;
                awaddr_latched <= s_axi_awaddr;
                aw_done <= 1;
            end else
                s_axi_awready <= 0;

            if (s_axi_wvalid && !w_done) begin
                s_axi_wready <= 1;
                w_done <= 1;
            end else
                s_axi_wready <= 0;

            if (aw_done && w_done && !s_axi_bvalid) begin
                case (awaddr_latched[3:0])
                    4'h0: pwm_en     <= s_axi_wdata[0];
                    4'h4: pwm_period <= s_axi_wdata;
                    4'h8: pwm_duty   <= s_axi_wdata;
                    default: ;
                endcase

                s_axi_bvalid <= 1;
                s_axi_bresp <= 2'b00;
            end

            if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 0;
                aw_done <= 0;
                w_done <= 0;
            end
        end
    end

    // AXI Read Interface
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_arready <= 0;
            s_axi_rvalid  <= 0;
            s_axi_rdata   <= 0;
            s_axi_rresp   <= 0;
        end else begin

            if (s_axi_arvalid && !s_axi_rvalid) begin
                s_axi_arready <= 1;
                s_axi_rvalid <= 1;
                s_axi_rresp <= 2'b00;

                case (s_axi_araddr[3:0])
                    4'h0: s_axi_rdata <= {31'd0, pwm_en};
                    4'h4: s_axi_rdata <= pwm_period;
                    4'h8: s_axi_rdata <= pwm_duty;
                    4'hC: s_axi_rdata <= pwm_count;
                    default: s_axi_rdata <= 32'd0;
                endcase
            end else
                s_axi_arready <= 0;

            if (s_axi_rvalid && s_axi_rready)
                s_axi_rvalid <= 0;
        end
    end

endmodule

`default_nettype wire
