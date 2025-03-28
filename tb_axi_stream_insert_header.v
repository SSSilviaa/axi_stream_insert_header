`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/28 09:00:09
// Design Name: 
// Module Name: tb_axi_stream_insert_header
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module tb_axi_stream_insert_header_random();

parameter DATA_WD = 32;
parameter DATA_BYTE_WD = DATA_WD / 8;
parameter BYTE_CNT_WD = 3;
// Clock �� Reset
reg clk;
reg rst_n;
// Payload
reg                 valid_in;
reg [DATA_WD-1:0]   data_in;
reg [DATA_BYTE_WD-1:0] keep_in;
reg                 last_in;
wire                ready_in;
// Output
wire                valid_out;
wire [DATA_WD-1:0]  data_out;
wire [DATA_BYTE_WD-1:0] keep_out;
wire                last_out;
reg                 ready_out;

// Header
reg                 valid_insert;
reg [DATA_WD-1:0]   data_insert;
reg [DATA_BYTE_WD-1:0] keep_insert;
reg [BYTE_CNT_WD-1:0]  byte_insert_cnt;
wire                ready_insert;

axi_stream_insert_header #(
    .DATA_WD(DATA_WD)
) dut (
    .clk(clk),
    .rst_n(rst_n),
    // Payload�ӿ�
    .valid_in(valid_in),
    .data_in(data_in),
    .keep_in(keep_in),
    .last_in(last_in),
    .ready_in(ready_in),
    // ����ӿ�
    .valid_out(valid_out),
    .data_out(data_out),
    .keep_out(keep_out),
    .last_out(last_out),
    .ready_out(ready_out),
    // Header�ӿ�
    .valid_insert(valid_insert),
    .data_insert(data_insert),
    .keep_insert(keep_insert),
    .byte_insert_cnt(byte_insert_cnt),
    .ready_insert(ready_insert)
);

// ʱ��10ns����
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end


initial begin
    ready_out = 1;
end
// ��� ready_out
always @(posedge clk) begin
    if ($urandom_range(0,9) < 2)
       ready_out <= 0;
    else
       ready_out <= 1;
end

// ��ͬ�� keep �ź�
integer i, num_beats;
reg [DATA_WD-1:0] payload_data;
reg [DATA_BYTE_WD-1:0] payload_keep;
reg [3:0] keep_options_payload [0:3];
reg [3:0] keep_options_header [0:3];

initial begin
    // payload keep 
    keep_options_payload[0] = 4'b1111;
    keep_options_payload[1] = 4'b1110;
    keep_options_payload[2] = 4'b1100;
    keep_options_payload[3] = 4'b1000;
    // header keep 
    keep_options_header[0] = 4'b1111; // ȫ��Ч
    keep_options_header[1] = 4'b0111; // ���1�ֽ���Ч
    keep_options_header[2] = 4'b0011; // ���2�ֽ���Ч
    keep_options_header[3] = 4'b0001; // ���3�ֽ���Ч
end

// ������ɶ�� burst��ÿ�� burst ����һ��header �ͼ��� payload
initial begin
    // ��ʼ��
    rst_n = 0;
    valid_in = 0;
    data_in  = 0;
    keep_in  = 0;
    last_in  = 0;
    valid_insert = 0;
    data_insert  = 0;
    keep_insert  = 0;
    byte_insert_cnt = 0;
    
    #20;
    rst_n = 1;
    #10;
    
    // ����5�� burst
    for (i = 0; i < 5; i = i + 1) begin
        // ���� header
        data_insert = $urandom;
        case ($urandom_range(0,3))
           0: begin keep_insert = keep_options_header[0]; byte_insert_cnt = 4; end
           1: begin keep_insert = keep_options_header[1]; byte_insert_cnt = 3; end
           2: begin keep_insert = keep_options_header[2]; byte_insert_cnt = 2; end
           3: begin keep_insert = keep_options_header[3]; byte_insert_cnt = 1; end
        endcase
        // ��� header beat
        valid_insert = 1;
        // �ȴ� header serted ���
        wait (ready_in);
        @(posedge clk);
        valid_insert = 0;
        
        // ������� payload
        num_beats = $urandom_range(1,5);
        $display("Burst %0d: payload beats = %0d", i, num_beats);
        repeat (num_beats - 1) begin
            // �������һ��ʱȫ����Ч
            payload_data = $urandom;
            valid_in = 1;
            data_in = payload_data;
            keep_in = 4'b1111;
            last_in = 0;
            wait (ready_in);
            @(posedge clk);
            valid_in = 0;
            @(posedge clk);
        end
        // ���һ�ģ����ѡ�񲿷���Ч
        payload_data = $urandom;
        valid_in = 1;
        data_in = payload_data;
        keep_in = keep_options_payload[$urandom_range(0,3)];
        last_in = 1;
        wait (ready_in);
        @(posedge clk);
        valid_in = 0;
        @(posedge clk);
        $display("Burst %0d completed", i);

        repeat (5) @(posedge clk);
    end
    
    #100;
    $finish;
end


endmodule

