module t_sha1();
   reg           clk;
   reg           start;
   reg  [1023:0] stream;
   reg  [511:0]  window;
   reg  [159:0]  hash;
   wire          done;
   wire [159:0]  hash_state_out;
   
   integer fpr, bytes_returned;
   
   reg [63:0] msg_length;
   reg [1:0] blocks_remaining;

   sha1_update uut(
      .clk(clk),
      .start(start),
      .data_in(stream[1023:512]),
      .hash_state_in(hash),
      .done(done),
      .hash_state_out(hash_state_out)
   );
   
   initial begin
      clk = 1'b0;
      start = 1'b0;
      stream = 1024'd0;
      blocks_remaining = 2'd0;
      hash = 160'h67452301EFCDAB8998BADCFE10325476C3D2E1F0;
      fpr = $fopen("inputfile", "rb");
      bytes_returned = $fread(stream, fpr);
      msg_length = bytes_returned;
      if (bytes_returned == 0) end_simulation();
      else if (bytes_returned <= 64) begin
         stream = sha1_pad_bytes(stream);
         if (bytes_returned < 56) blocks_remaining = 2'd1;
         else blocks_remaining = 2'd2;
      end
      else blocks_remaining = 2'd2;
      pulse_start();
   end
   
   always #10 clk = ~clk;

   always @ (posedge clk) begin
      if (done) begin
         hash = hash_state_out;
         blocks_remaining = blocks_remaining - 1'b1;
         
         bytes_returned = $fread(window, fpr);
         msg_length = msg_length + bytes_returned;
         if (bytes_returned) begin
            blocks_remaining = blocks_remaining + 2'd1;
            if (bytes_returned >= 56 && bytes_returned < 64) blocks_remaining = blocks_remaining + 2'd1;
         end
         stream = {stream[511:0], window};
         if (blocks_remaining == 1 && msg_length > 128) stream = sha1_pad_bytes(stream);
         if (blocks_remaining == 0) end_simulation();
         pulse_start();
      end
   end
   
   function [1023:0] sha1_pad_bytes;
      input [1023:0] bytes;
   
      reg   [63:0] bits_in_file;
      reg   [10:0] pad_amount;
      reg   [10:0] bits_last_block;
      reg   [9:0] offset;
      integer i;
      begin
         // Bits in file is the message length * 8 (<< 3)
         bits_in_file = (msg_length) << 3;
         
         // Valid bits in the last block we are trying
         // to pad.  If modulus returns 0, then it is 512.
         bits_last_block = bits_in_file % 512;
         if (bits_last_block == 0) bits_last_block = 512;

         // Figure out the padding amount for 0's.  If the block
         // is less than 447 then the padding is whatever it takes
         // to get it up to 447 since 447 + 1 + 64 = 512.  Likewise
         // for blocks greater than this, we need to get up to
         // 959 + 1 + 64 = 1024.  Since 1024 is the maxium amount
         // we can pad up to with a block size of 512 bits.
         if (bits_last_block < 447) begin 
            pad_amount = 447 - bits_last_block;
            offset = 10'd512;
         end
         else begin
            pad_amount = 959 - bits_last_block;
            offset = 10'd0;
         end
         
         for (i = 10'd1023; i != ~32'd0; i = i - 1'b1) begin
            if (i > 1'b1 + pad_amount + 6'd63 + offset) begin
               $display("i is: %d for copying bytes\n", i);
               sha1_pad_bytes[i] = bytes[i];
            end
            else if (i == pad_amount + 1'b1 + 6'd63 + offset) begin
               $display("i is: %d for copying the 1\n", i);
               sha1_pad_bytes[i] = 1'b1;
            end
            else if (i > 6'd63 + offset) begin
               $display("i is: %d for copying the 0's\n", i);
               sha1_pad_bytes[i] = 1'b0;
            end
            else if (i > offset) begin 
               $display("i is: %d for copying the length. index into array is %d and val is %h and offset is %h\n", i, (i - offset) - 1'b1, bits_in_file[(i-offset) - 1'b1], offset);
               sha1_pad_bytes[i] = bits_in_file[i - offset];
            end
            else begin
               $display("i is: %d for copying z's\n", i);
               sha1_pad_bytes[i] = 1'b0;
            end
         end
      end
   endfunction
   
   task pulse_start;
      begin
         //Pulse the start signal for next block.
         start     <= 1'b1;
         #20 start <= 1'b0;
      end
   endtask
   
   task end_simulation;
      begin
         $display("Hexdigest: %h", hash);
         $fclose(fpr);
         $stop;
      end
   endtask
   
endmodule
