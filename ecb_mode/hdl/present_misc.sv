/**
 * File              : present_misc.sv
 * Author            : German C.Quiveu <germancq@dte.us.es>
 * Date              : 17.06.2026
 * Last Modified Date: 17.06.2026
 * Last Modified By  : German C.Quiveu <germancq@dte.us.es>
 */

module enc_stage (
    input  [63:0] block_i,
    input  [63:0] key_i,
    output [63:0] block_o
);

  logic [63:0] s_box_o;

  s_layer_enc slayer_i (
      .din (block_i),
      .dout(s_box_o)
  );

  logic [63:0] p_layer_o;

  player_enc player_i (
      .din (s_box_o),
      .dout(p_layer_o)
  );

  assign block_o = p_layer_o ^ key_i;


endmodule : enc_stage

module enc_stage_2 (
    input  [63:0] block_i,
    input  [63:0] key_i,
    output [63:0] block_o
);

  logic [63:0] s_box_o;

  s_layer_enc slayer_i (
      .din (block_i ^ key_i),
      .dout(s_box_o)
  );

  logic [63:0] p_layer_o;

  player_enc player_i (
      .din (s_box_o),
      .dout(p_layer_o)
  );

  assign block_o = p_layer_o;


endmodule : enc_stage_2

module dec_stage (
    input  [63:0] block_i,
    input  [63:0] key_i,
    output [63:0] block_o
);

  logic [63:0] p_layer_o;

  player_dec player_i (
      .din (block_i),
      .dout(p_layer_o)
  );

  logic [63:0] s_box_o;

  s_layer_dec slayer_i (
      .din (p_layer_o),
      .dout(s_box_o)
  );



  assign block_o = s_box_o ^ key_i;


endmodule : dec_stage

module dec_stage_2 (
    input  [63:0] block_i,
    input  [63:0] key_i,
    output [63:0] block_o
);

  logic [63:0] p_layer_o;

  player_dec player_i (
      .din (block_i ^ key_i),
      .dout(p_layer_o)
  );

  logic [63:0] s_box_o;

  s_layer_dec slayer_i (
      .din (p_layer_o),
      .dout(s_box_o)
  );



  assign block_o = s_box_o;


endmodule : dec_stage_2

module S_box_enc (
    input [3:0] din,
    output logic [3:0] dout
);

  always_comb begin
    case (din)
      0: dout = 4'hC;
      1: dout = 4'h5;
      2: dout = 4'h6;
      3: dout = 4'hB;
      4: dout = 4'h9;
      5: dout = 4'h0;
      6: dout = 4'hA;
      7: dout = 4'hD;
      8: dout = 4'h3;
      9: dout = 4'hE;
      10: dout = 4'hF;
      11: dout = 4'h8;
      12: dout = 4'h4;
      13: dout = 4'h7;
      14: dout = 4'h1;
      15: dout = 4'h2;
      default: dout = 4'hC;
    endcase
  end


endmodule : S_box_enc


module S_box_dec (
    input [3:0] din,
    output logic [3:0] dout
);

  always_comb begin
    case (din)
      0: dout = 4'h5;
      1: dout = 4'hE;
      2: dout = 4'hF;
      3: dout = 4'h8;
      4: dout = 4'hC;
      5: dout = 4'h1;
      6: dout = 4'h2;
      7: dout = 4'hD;
      8: dout = 4'hB;
      9: dout = 4'h4;
      10: dout = 4'h6;
      11: dout = 4'h3;
      12: dout = 4'h0;
      13: dout = 4'h7;
      14: dout = 4'h9;
      15: dout = 4'hA;
      default: dout = 4'h5;
    endcase
  end


endmodule : S_box_dec


module s_layer_enc (
    input  [63:0] din,
    output [63:0] dout
);

  genvar i;
  generate
    for (i = 0; i < 16; i = i + 1) begin
      S_box_enc sbox (
          .din (din[(i*4)+3:i*4]),
          .dout(dout[(i*4)+3:i*4])
      );
    end
  endgenerate





endmodule : s_layer_enc


module s_layer_dec (
    input  [63:0] din,
    output [63:0] dout
);

  genvar i;
  generate
    for (i = 0; i < 16; i = i + 1) begin
      S_box_dec sbox (
          .din (din[(i*4)+3:i*4]),
          .dout(dout[(i*4)+3:i*4])
      );
    end
  endgenerate





endmodule : s_layer_dec


module player_enc (
    input [63:0] din,
    output logic [63:0] dout
);

  always_comb begin

    dout[0]  = din[0];
    dout[1]  = din[4];
    dout[2]  = din[8];
    dout[3]  = din[12];
    dout[4]  = din[16];
    dout[5]  = din[20];
    dout[6]  = din[24];
    dout[7]  = din[28];
    dout[8]  = din[32];
    dout[9]  = din[36];
    dout[10] = din[40];
    dout[11] = din[44];
    dout[12] = din[48];
    dout[13] = din[52];
    dout[14] = din[56];
    dout[15] = din[60];
    dout[16] = din[1];
    dout[17] = din[5];
    dout[18] = din[9];
    dout[19] = din[13];
    dout[20] = din[17];
    dout[21] = din[21];
    dout[22] = din[25];
    dout[23] = din[29];
    dout[24] = din[33];
    dout[25] = din[37];
    dout[26] = din[41];
    dout[27] = din[45];
    dout[28] = din[49];
    dout[29] = din[53];
    dout[30] = din[57];
    dout[31] = din[61];
    dout[32] = din[2];
    dout[33] = din[6];
    dout[34] = din[10];
    dout[35] = din[14];
    dout[36] = din[18];
    dout[37] = din[22];
    dout[38] = din[26];
    dout[39] = din[30];
    dout[40] = din[34];
    dout[41] = din[38];
    dout[42] = din[42];
    dout[43] = din[46];
    dout[44] = din[50];
    dout[45] = din[54];
    dout[46] = din[58];
    dout[47] = din[62];
    dout[48] = din[3];
    dout[49] = din[7];
    dout[50] = din[11];
    dout[51] = din[15];
    dout[52] = din[19];
    dout[53] = din[23];
    dout[54] = din[27];
    dout[55] = din[31];
    dout[56] = din[35];
    dout[57] = din[39];
    dout[58] = din[43];
    dout[59] = din[47];
    dout[60] = din[51];
    dout[61] = din[55];
    dout[62] = din[59];
    dout[63] = din[63];

  end


endmodule : player_enc


module player_dec (
    input [63:0] din,
    output logic [63:0] dout
);

  always_comb begin

    dout[0]  = din[0];
    dout[4]  = din[1];
    dout[8]  = din[2];
    dout[12] = din[3];
    dout[16] = din[4];
    dout[20] = din[5];
    dout[24] = din[6];
    dout[28] = din[7];
    dout[32] = din[8];
    dout[36] = din[9];
    dout[40] = din[10];
    dout[44] = din[11];
    dout[48] = din[12];
    dout[52] = din[13];
    dout[56] = din[14];
    dout[60] = din[15];
    dout[1]  = din[16];
    dout[5]  = din[17];
    dout[9]  = din[18];
    dout[13] = din[19];
    dout[17] = din[20];
    dout[21] = din[21];
    dout[25] = din[22];
    dout[29] = din[23];
    dout[33] = din[24];
    dout[37] = din[25];
    dout[41] = din[26];
    dout[45] = din[27];
    dout[49] = din[28];
    dout[53] = din[29];
    dout[57] = din[30];
    dout[61] = din[31];
    dout[2]  = din[32];
    dout[6]  = din[33];
    dout[10] = din[34];
    dout[14] = din[35];
    dout[18] = din[36];
    dout[22] = din[37];
    dout[26] = din[38];
    dout[30] = din[39];
    dout[34] = din[40];
    dout[38] = din[41];
    dout[42] = din[42];
    dout[46] = din[43];
    dout[50] = din[44];
    dout[54] = din[45];
    dout[58] = din[46];
    dout[62] = din[47];
    dout[3]  = din[48];
    dout[7]  = din[49];
    dout[11] = din[50];
    dout[15] = din[51];
    dout[19] = din[52];
    dout[23] = din[53];
    dout[27] = din[54];
    dout[31] = din[55];
    dout[35] = din[56];
    dout[39] = din[57];
    dout[43] = din[58];
    dout[47] = din[59];
    dout[51] = din[60];
    dout[55] = din[61];
    dout[59] = din[62];
    dout[63] = din[63];

  end


endmodule : player_dec
