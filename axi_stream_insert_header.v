`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/28 08:59:22
// Design Name: 
// Module Name: axi_stream_insert_header
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


module axi_stream_insert_header #(
    parameter DATA_WD       = 32,
    parameter DATA_BYTE_WD  = DATA_WD / 8,
    parameter BYTE_CNT_WD   = $clog2(DATA_BYTE_WD)
) (
    input                        clk,
    input                        rst_n,
    // AXI Stream input original data
    input                        valid_in,
    input   [DATA_WD-1 : 0]      data_in,
    input   [DATA_BYTE_WD-1 : 0] keep_in,
    input                        last_in,
    output                       ready_in,
    // AXI Stream output with header inserted
    output reg                   valid_out,
    output reg [DATA_WD-1 : 0]     data_out,
    output reg [DATA_BYTE_WD-1 : 0]keep_out,
    output reg                   last_out,
    input                        ready_out,
    // The header to be inserted to AXI Stream input
    input                        valid_insert,
    input   [DATA_WD-1 : 0]      data_insert,
    input   [DATA_BYTE_WD-1 : 0] keep_insert,
    input   [BYTE_CNT_WD-1 : 0]  byte_insert_cnt,
    output                       ready_insert
);

  // header �Ƿ��Ѵ���
  reg header_inserted;

  // ���� ready �ź�
  assign ready_insert = ~header_inserted && ready_out;
  assign ready_in = header_inserted && ready_out;

  // ���shifted�� header ���ݺ� keep 
  reg [DATA_WD-1:0] data_insert_shifted;
  reg [DATA_BYTE_WD-1:0] keep_insert_shifted;

  // ���� byte_insert_cnt ���� keep mask
  // ��Ч�� k �� MSB������0
  function automatic [DATA_BYTE_WD-1:0] get_keep_mask(input integer k);
    integer i;
    reg [DATA_BYTE_WD-1:0] mask;
    begin
      mask = {DATA_BYTE_WD{1'b0}};
      for (i = 0; i < DATA_BYTE_WD; i = i + 1) begin
         if (i < k)
           // ǰ k ����λ 1
           mask[DATA_BYTE_WD-1 - i] = 1'b1;
         else
           mask[DATA_BYTE_WD-1 - i] = 1'b0;
      end
      get_keep_mask = mask;
    end
  endfunction

  // comb logic������ byte_insert_cnt ��������λ��� header ���ݺ� keep ����
  always @(*) begin
      case (byte_insert_cnt)
         0: begin
             data_insert_shifted = {DATA_WD{1'b0}};
             keep_insert_shifted = {DATA_BYTE_WD{1'b0}};
         end
         default: begin
             data_insert_shifted = data_insert << (((DATA_BYTE_WD - byte_insert_cnt)*8));
             keep_insert_shifted = get_keep_mask(byte_insert_cnt);
         end
      endcase
  end

  // ff logic������ header_inserted ������� header ���� payload
  always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
          header_inserted <= 1'b0;
          valid_out <= 1'b0;
          data_out <= {DATA_WD{1'b0}};
          keep_out <= {DATA_BYTE_WD{1'b0}};
          last_out <= 1'b0;
      end else begin
          if (!header_inserted) begin
              // ��û����header���� header ����ӿ�
              if (valid_insert && ready_out) begin
                  valid_out <= 1'b1;
                  data_out <= data_insert_shifted;
                  keep_out <= keep_insert_shifted;
                  last_out <= 1'b0;
                  header_inserted <= 1'b1;
              end else begin
                  valid_out <= 1'b0;
              end
          end else begin
              // header �Ѳ��룬���� payload
              valid_out <= valid_in;
              if (valid_in && ready_out) begin
                  data_out <= data_in;
                  keep_out <= keep_in;
                  last_out <= last_in;
                  // һ�� burst �� payload ���һ�Ĵ�����ɣ�
                  // ��� header ��־
                  if (last_in) begin 
                      header_inserted <= 1'b0;
                  end
              end
          end
      end
  end

endmodule


