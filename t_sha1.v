module t_sha1();
   reg           clk;
   reg           start;
   reg           eof;
   reg  [511:0]  data_block;
   reg  [ 63:0]  msg_length;
   wire [159:0]  hash;
   wire          next_block;
   wire          done;
   
   integer fpr, bytes_returned;

   sha1 uut(
      .clk(clk),
      .start(start),
      .eof(eof),
      .data_block(data_block),
      .msg_length(msg_length),
      .hash(hash),
      .next_block(next_block),
      .done(done)
   );
   
   initial begin
      clk = 1'b0;
      start = 1'b0;
      eof   = 1'b0;
      data_block = 512'd0;
      msg_length = 64'd0;
      
      fpr = $fopen("testvector3.tv", "rb");
      bytes_returned = $fread(data_block, fpr);
      if (bytes_returned == 0) eof = 1'b1;
      msg_length = msg_length + bytes_returned;
      pulse_start();
   end
   
   always #10 clk = ~clk;

   always @ (posedge clk) begin
      if (next_block) begin
         bytes_returned = $fread(data_block, fpr);
         if (bytes_returned == 0) eof = 1'b1;
         msg_length = msg_length + bytes_returned;
      end
      else if (done) end_simulation();
   end

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
