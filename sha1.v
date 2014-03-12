module sha1(
   input              clk,
   input              start,
   input              eof,
   input      [511:0] data_block,
   input      [ 63:0] msg_length,
   output reg [159:0] hash,
   output             next_block,
   output             done
);

   localparam IDLE      = 3'd0;
   localparam BUFFERING = 3'd1;
   localparam STARTHASH = 3'd2;
   localparam HASH      = 3'd3;
   localparam PAD_BLOCK = 3'd4;
   localparam STARTLAST = 3'd5;
   localparam HASHLAST  = 3'd6;
   localparam DONE      = 3'd7;
   reg [2:0] sm_state;
   reg [2:0] sm_next_state;
   
   reg [1023:0] data_buffer;
   reg [1:0] last_blocks;
   wire [159:0] hash_state_out;
   wire block_done;
   wire start_block;
   wire shift_buffer;
   wire blocks_remaining;
   
   wire [63:0] bits_in_file = msg_length << 3;
   wire [63:0] bits_last_block = bits_in_file % 10'd512;
   
   sha1_update block_hash(
      .clk(clk),
      .start(start_block),
      .data_in(data_buffer[1023:512]),
      .hash_state_in(hash),
      .done(block_done),
      .hash_state_out(hash_state_out)
   );
   
   initial begin
      sm_state = IDLE;
   end
   
   assign next_block  = (sm_state == IDLE && start) || (sm_state == HASH && block_done);
   assign start_block = (sm_state == STARTHASH || sm_state == STARTLAST);
   assign shift_buffer = (sm_state == BUFFERING || (sm_state == HASHLAST && sm_next_state == STARTLAST));
   assign blocks_remaining = last_blocks > 0;
   assign done = sm_state == DONE;
   
   always @ (*) begin
      case (sm_state)
         IDLE      : sm_next_state = start ? BUFFERING : IDLE;
         BUFFERING : sm_next_state = eof ? PAD_BLOCK : STARTHASH;
         STARTHASH : sm_next_state = HASH;
         HASH      : sm_next_state = block_done ? BUFFERING : HASH;
         PAD_BLOCK : sm_next_state = STARTLAST;
         STARTLAST : sm_next_state = blocks_remaining ? HASHLAST : DONE;
         HASHLAST  : sm_next_state = block_done ? ( blocks_remaining ? STARTLAST : DONE) : HASHLAST;
         DONE      : sm_next_state = IDLE;
      endcase
   end
   
   always @ (posedge clk) begin
      if (start) begin
         hash <= 160'h67452301EFCDAB8998BADCFE10325476C3D2E1F0;
         data_buffer <= {512'd0, data_block};
         last_blocks <= 1'b0;
      end
      else if (shift_buffer) begin
         data_buffer <= {data_buffer[511:0], data_block};
      end
      else if (sm_state == PAD_BLOCK) begin
         data_buffer <= sha1_pad_bytes(data_buffer);
         last_blocks <= ((bits_last_block < 448 && bits_last_block != 0) || msg_length == 0) ? 2'd1 : 2'd2;
      end
      if (block_done) hash <= hash_state_out;
      if ((sm_state == HASHLAST) && block_done) last_blocks <= last_blocks - 1'b1;
      sm_state <= sm_next_state;
   end

   function [1023:0] sha1_pad_bytes;
      input [1023:0] bytes;

      reg   [10:0] pad_amount;
      reg   [10:0] bits_last_blk;
      reg   [9:0] offset;
      integer i;
      begin         
         // Valid bits in the last block we are trying
         // to pad.  If modulus returns 0, then it is 512.
         bits_last_blk = bits_last_block;
         if (bits_last_blk == 0) bits_last_blk = 512;

         // Figure out the padding amount for 0's.  If the block
         // is less than 447 then the padding is whatever it takes
         // to get it up to 447 since 447 + 1 + 64 = 512.  Likewise
         // for blocks greater than this, we need to get up to
         // 959 + 1 + 64 = 1024.  Since 1024 is the maxium amount
         // we can pad up to with a block size of 512 bits.
         if (msg_length == 0) begin
            pad_amount = 9'd447;
            offset = 10'd512;
         end
         else if (bits_last_blk < 447) begin 
            pad_amount = 447 - bits_last_blk;
            offset = 10'd512;
         end
         else begin
            pad_amount = 959 - bits_last_blk;
            offset = 10'd0;
         end
         
         for (i = 10'd1023; i != ~32'd0; i = i - 1'b1) begin
            if (i > 1'b1 + pad_amount + 6'd63 + offset) sha1_pad_bytes[i] = bytes[i];
            else if (i == pad_amount + 1'b1 + 6'd63 + offset) sha1_pad_bytes[i] = 1'b1;
            else if (i > 6'd63 + offset) sha1_pad_bytes[i] = 1'b0;
            else if (i > offset) begin
               $display("i is: %d index is %d val is %h\n", i, i - offset, bits_in_file[i - offset]);
               sha1_pad_bytes[i] = bits_in_file[i - offset];
            end
            else sha1_pad_bytes[i] = 1'b0;
         end
      end
   endfunction

endmodule
