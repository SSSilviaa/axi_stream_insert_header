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

  // header 是否已传输
  reg header_inserted;

  // 连接 ready 信号
  assign ready_insert = ~header_inserted && ready_out;
  assign ready_in = header_inserted && ready_out;

  // 存放shifted的 header 数据和 keep 
  reg [DATA_WD-1:0] data_insert_shifted;
  reg [DATA_BYTE_WD-1:0] keep_insert_shifted;

  // 根据 byte_insert_cnt 生成 keep mask
  // 有效的 k 个 MSB，其余0
  function automatic [DATA_BYTE_WD-1:0] get_keep_mask(input integer k);
    integer i;
    reg [DATA_BYTE_WD-1:0] mask;
    begin
      mask = {DATA_BYTE_WD{1'b0}};
      for (i = 0; i < DATA_BYTE_WD; i = i + 1) begin
         if (i < k)
           // 前 k 个高位 1
           mask[DATA_BYTE_WD-1 - i] = 1'b1;
         else
           mask[DATA_BYTE_WD-1 - i] = 1'b0;
      end
      get_keep_mask = mask;
    end
  endfunction

  // comb logic：根据 byte_insert_cnt 来计算移位后的 header 数据和 keep 掩码
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

  // ff logic：根据 header_inserted 决定输出 header 还是 payload
  always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
          header_inserted <= 1'b0;
          valid_out <= 1'b0;
          data_out <= {DATA_WD{1'b0}};
          keep_out <= {DATA_BYTE_WD{1'b0}};
          last_out <= 1'b0;
      end else begin
          if (!header_inserted) begin
              // 还没传送header，看 header 插入接口
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
              // header 已插入，传输 payload
              valid_out <= valid_in;
              if (valid_in && ready_out) begin
                  data_out <= data_in;
                  keep_out <= keep_in;
                  last_out <= last_in;
                  // 一个 burst 的 payload 最后一拍传输完成，
                  // 清除 header 标志
                  if (last_in) begin 
                      header_inserted <= 1'b0;
                  end
              end
          end
      end
  end

endmodule


