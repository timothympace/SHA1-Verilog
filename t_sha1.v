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
         stream = pad_bytes(stream);
         if (bytes_returned < 56) blocks_remaining = 2'd1;
         else blocks_remaining = 2'd2;
      end
      else blocks_remaining = 2'd2;
      pulse_start();
   end
   
   always #1 clk = ~clk;

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
         if (blocks_remaining == 1 && msg_length > 128) stream = pad_bytes(stream);
         if (blocks_remaining == 0) end_simulation();
         pulse_start();
      end
   end
   
   function [1023:0] pad_bytes;
      input [1023:0] bytes;
      reg [64:0] bits_in_file;
      reg [10:0] pad_amount;
      reg [10:0] bits_in_block;
      integer i;
      begin
         bits_in_file = (msg_length) << 3;
         bits_in_block = bits_in_file % 512;
         if (bits_in_block == 0) bits_in_block = 512;
         pad_bytes[11'd1023 - bits_in_block] = 1'b1;
         bits_in_block = bits_in_block + 1'b1;
         if (bits_in_block < 448) pad_amount = 448 - bits_in_block;
         else pad_amount = 960 - bits_in_block;
         for (i = 0; i < bits_in_block - 1'b1; i = i + 1'b1) begin
            pad_bytes[11'd1023-i] = bytes[11'd1023-i];
         end
         for (i = bits_in_block; i < bits_in_block + pad_amount; i = i + 1'b1) begin
            pad_bytes[11'd1023-i] = 1'b0;
         end
         bits_in_block = bits_in_block + pad_amount;
         for (i = bits_in_block; i < bits_in_block + 64; i = i + 1'b1) begin
            pad_bytes[11'd1023-i] = bits_in_file[6'd63 - (i - bits_in_block)];
            $display("index is: %d, contents are: %h\n", 6'd63 - (i - bits_in_block), msg_length[6'd63 - (i - bits_in_block)]);
         end
         bits_in_block = bits_in_block + 64;
      end
   endfunction
   
   task pulse_start;
      begin
         //Pulse the start signal for next block.
         start     <= 1'b1;
         #2 start <= 1'b0;
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
