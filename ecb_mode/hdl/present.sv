/**
 * File              : present.sv
 * Author            : German C.Quiveu <germancq@dte.us.es>
 * Date              : 17.06.2026
 * Last Modified Date: 17.06.2026
 * Last Modified By  : German C.Quiveu <germancq@dte.us.es>
 */

module present (
    input clk,
    input rst,
    output end_key_generation,
    input [79:0] key,
    input [63:0] block_i,
    output [63:0] block_o,
    input enc_dec,
    input rq_data,
    output end_signal
);

  logic [ 4:0] key_index;
  logic [ 4:0] key_index_enc;
  logic [ 4:0] key_index_dec;
  logic [63:0] roundkey;

  logic [63:0] enc_o, dec_o;
  logic [63:0] block_o_logic;
  logic end_enc, end_dec;

  assign key_index = enc_dec ? key_index_dec : key_index_enc;
  assign block_o_logic = enc_dec ? dec_o : enc_o;

  present_key_schedule key_sch_impl (
      .clk(clk),
      .rst(rst),
      .key(key),
      .key_index(key_index),
      .end_signal(end_key_generation),
      .roundkey(roundkey)
  );


  logic start_enc;
  assign start_enc = enc_dec ? 1'b0 : 1'b1;
  logic start_dec;
  assign start_dec = enc_dec ? 1'b1 : 1'b0;

  present_enc present_enc_impl (
      .clk(clk),
      .rst(~end_key_generation || rq_data),
      .start_signal(start_enc),
      .text(block_i),
      .roundkey(roundkey),
      .key_index(key_index_enc),
      .result(enc_o),
      .end_signal(end_enc)
  );

  present_dec present_dec_impl (
      .clk(clk),
      .rst(~end_key_generation || rq_data),
      .start_signal(start_dec),
      .text(block_i),
      .roundkey(roundkey),
      .key_index(key_index_dec),
      .result(dec_o),
      .end_signal(end_dec)
  );

  register #(
      .DATA_WIDTH(64)
  ) result (
      .clk(clk),
      .cl(rst || rq_data),
      .w(end_enc || end_dec),
      .din(block_o_logic),
      .dout(block_o)
  );

  register #(
      .DATA_WIDTH(1)
  ) reg_end_signal (
      .clk(clk),
      .cl(rst || rq_data),
      .w(end_enc || end_dec),
      .din(1'b1),
      .dout(end_signal)
  );

endmodule : present


module present_enc (
    input clk,
    input rst,
    input start_signal,
    input [63:0] text,
    input [63:0] roundkey,
    output [4:0] key_index,
    output [63:0] result,
    output logic end_signal
);

  logic counter_up;

  counter #(
      .DATA_WIDTH(5)
  ) counter_impl (
      .clk (clk),
      .rst (~start_signal | rst),
      .up  (counter_up),
      .down(1'b0),
      .din (5'h0),
      .dout(key_index)
  );

  //assign end_signal = key_index == 5'd31 ? 1'b1 : 1'b0;

  logic [63:0] block_o;
  logic [63:0] register_output;
  logic register_w;
  assign register_w = key_index > 0 ? 1'b1 : 1'b0;
  register #(
      .DATA_WIDTH(64)
  ) block_register (
      .clk(clk),
      .cl(~start_signal | rst),
      .w(register_w),
      .din(block_o),
      .dout(register_output)
  );

  logic [63:0] block_i;
  assign block_i = key_index < 2 ? text : register_output;  //MUX

  enc_stage_2 enc_stage_impl (
      .block_i(block_i),
      .key_i  (roundkey),
      .block_o(block_o)
  );

  assign result = register_output ^ roundkey;

  always_ff @(posedge clk) begin
    if (rst) begin
      end_signal <= 1'b0;
    end else if (key_index == 5'd31) begin
      counter_up <= 1'b0;
      end_signal <= 1'b1;
    end else if (start_signal == 1'b1) begin
      counter_up <= 1'b1;
      end_signal <= 1'b0;
    end

  end

endmodule : present_enc


module present_dec (
    input clk,
    input rst,
    input start_signal,
    input [63:0] text,
    input [63:0] roundkey,
    output [4:0] key_index,
    output [63:0] result,
    output logic end_signal
);

  logic counter_down;

  counter #(
      .DATA_WIDTH(5)
  ) counter_impl (
      .clk (clk),
      .rst (~start_signal | rst),
      .up  (1'b0),
      .down(counter_down),
      .din (5'h1F),
      .dout(key_index)
  );

  //assign end_signal = key_index == 5'd0 ? 1'b1 : 1'b0;

  logic [63:0] block_o;
  logic [63:0] register_output;
  logic register_w;
  assign register_w = key_index < 5'h1F ? 1'b1 : 1'b0;
  register #(
      .DATA_WIDTH(64)
  ) block_register (
      .clk(clk),
      .cl(~start_signal | rst),
      .w(register_w),
      .din(block_o),
      .dout(register_output)
  );

  logic [63:0] block_i;
  assign block_i = key_index > 5'h1D ? text : register_output;  //MUX

  dec_stage_2 dec_stage_impl (
      .block_i(block_i),
      .key_i  (roundkey),
      .block_o(block_o)
  );

  assign result = register_output ^ roundkey;

  always_ff @(posedge clk) begin
    if (rst) begin
      end_signal <= 1'b0;
    end else if (key_index == 5'd0) begin
      counter_down <= 1'b0;
      end_signal   <= 1'b1;
    end else if (start_signal == 1'b1) begin
      counter_down <= 1'b1;
      end_signal   <= 1'b0;
    end


  end


endmodule : present_dec


module present_key_schedule (
    input clk,
    input rst,
    input [79:0] key,
    output logic end_signal,
    input [4:0] key_index,
    output [63:0] roundkey
);


  logic key_register_cl;
  logic key_register_w;
  logic [79:0] key_register_input;
  logic [79:0] key_register_output;

  register #(
      .DATA_WIDTH(80)
  ) key_register (
      .clk(clk),
      .cl(key_register_cl),
      .w(key_register_w),
      .din(key_register_input),
      .dout(key_register_output)
  );


  logic [4:0] counter_output;
  logic counter_up;

  counter #(
      .DATA_WIDTH(5)
  ) counter_impl (
      .clk (clk),
      .rst (rst),
      .up  (counter_up),
      .down(1'b0),
      .din (5'h0),
      .dout(counter_output)
  );


  logic r_w;
  logic [4:0] mem_addr;
  assign mem_addr = end_signal ? key_index : counter_output;

  memory_module #(
      .ADDR(5),
      .DATA_WIDTH(64)
  ) memory_impl (
      .clk (clk),
      .r_w (r_w),
      .addr(mem_addr),
      .din (key_register_output[79:16]),
      .dout(roundkey)
  );


  logic [3:0] s_box_output;

  S_box_enc sbox (
      .din (key_register_output[79:76]),
      .dout(s_box_output)
  );


  typedef enum logic [2:0] {
    IDLE,
    STORE_KEY,
    SHIFT_KEY,
    SBOX_KEY,
    XOR_KEY,
    END
  } state_t;
  state_t current_state, next_state;



  always_comb begin

    next_state = current_state;

    counter_up = 0;
    end_signal = 1'b0;
    key_register_cl = 1'b0;
    key_register_w = 1'b0;
    key_register_input = 80'h0;
    r_w = 1'b0;


    case (current_state)
      IDLE: begin
        key_register_input = key;
        key_register_w = 1'b1;

        next_state = STORE_KEY;


      end
      STORE_KEY: begin


        r_w = 1;

        if (counter_output == 5'd31) begin
          next_state = END;
        end else begin

          next_state = SHIFT_KEY;

        end
      end
      SHIFT_KEY: begin
        key_register_input = {key_register_output[18:0], key_register_output[79:19]};
        key_register_w     = 1'b1;
        counter_up         = 1'b1;
        next_state         = SBOX_KEY;
      end
      SBOX_KEY: begin
        key_register_input = {s_box_output, key_register_output[75:0]};
        key_register_w = 1'b1;
        next_state = XOR_KEY;
      end
      XOR_KEY: begin
        key_register_input = {
          key_register_output[79:20],
          key_register_output[19:15] ^ counter_output,
          key_register_output[14:0]
        };
        key_register_w = 1'b1;
        next_state = STORE_KEY;
      end
      END: begin

        end_signal = 1'b1;


      end
      default: ;
    endcase
  end


  always_ff @(posedge clk) begin
    if (rst) begin
      current_state <= IDLE;
    end else begin
      current_state <= next_state;
    end
  end


endmodule : present_key_schedule
