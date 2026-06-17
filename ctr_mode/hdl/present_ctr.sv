/**
 * File              : present_ctr.sv
 * Author            : German C.Quiveu <germancq@dte.us.es>
 * Date              : 17.06.2026
 * Last Modified Date: 17.06.2026
 * Last Modified By  : German C.Quiveu <germancq@dte.us.es>
 */

module present_ctr (
    input clk,
    input rst,
    input [63:0] IV,
    input [63:0] block_number,
    input [79:0] key,
    input [63:0] block_i,
    output [63:0] block_o,
    input rq_data,
    output end_key_generation,
    output end_signal
);


  logic end_enc;
  logic [4:0] key_index_enc;
  logic [63:0] roundkey;
  logic [63:0] text;
  logic [63:0] enc_o;


  present_key_schedule key_sch_impl (
      .clk(clk),
      .rst(rst),
      .key(key),
      .key_index(key_index_enc),
      .end_signal(end_key_generation),
      .roundkey(roundkey)
  );

  adder #(
      .N(64)
  ) adder_inst (
      .a(IV),
      .b(block_number),
      .s(text),
      .c()
  );


  present_enc present_enc_impl (
      .clk(clk),
      .rst(~end_key_generation || rq_data),
      .start_signal(1'b1),
      .text(text),
      .roundkey(roundkey),
      .key_index(key_index_enc),
      .result(enc_o),
      .end_signal(end_enc)
  );

  register #(
      .DATA_WIDTH(64)
  ) result (
      .clk(clk),
      .cl(rst || rq_data),
      .w(end_enc),
      .din(enc_o ^ block_i),
      .dout(block_o)
  );

  register #(
      .DATA_WIDTH(1)
  ) reg_end_signal (
      .clk(clk),
      .cl(rst || rq_data),
      .w(end_enc),
      .din(1'b1),
      .dout(end_signal)
  );


endmodule : present_ctr
