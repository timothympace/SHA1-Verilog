module sha1_update(
   input              clk,
   input              start,
   input      [511:0] data_in,
   input      [159:0] hash_state_in,
   output             done,
   output reg [159:0] hash_state_out  
);

   localparam IDLE        = 2'd0;
   localparam COMPRESSING = 2'd1;
   localparam DONE        = 2'd2;
   reg [1:0] sm_state;
   reg [1:0] sm_next_state;

   reg [511:0] w;
   wire [159:0] compression_state_loopback;
   reg [ 31:0] w_roundi;
   reg [  6:0] round;
   reg         next_round;

   wire [ 31:0] next_w;
   
   initial begin
      round = 7'd0;
      w = 512'd0;
      sm_state = IDLE;
   end
   
   sha1_compression rnd_compression(
      .hash_state_in(hash_state_out),
      .w(w_roundi),
      .round(round),
      .hash_state_out(compression_state_loopback)
   );
   
   assign next_w = w[511:480] ^ w[447:416] ^ w[255:224] ^ w[95:64];
   assign done = sm_state == DONE;

   always @ (*) begin
      next_round = 1'b0;
      case (sm_state)
         IDLE        : sm_next_state = start ? COMPRESSING : IDLE;
         COMPRESSING : {sm_next_state, next_round} = round == 7'd79 ? {DONE, 1'b0} : {COMPRESSING, 1'b1};
         DONE        : sm_next_state = IDLE;
      endcase
      w_roundi = (round > 15) ? w[31:0] : w >> (10'd480 - (round << 5));
   end
   
   always @ (posedge clk) begin      
      if (start) begin
         w <= data_in;
         hash_state_out <= hash_state_in;
         round <= 7'd0;
      end
      else begin
         if (round >= 15) w <= {w[479:0], {next_w[30:0], next_w[31]}};
         if (next_round) round <= round + 1'b1;
         if (sm_next_state == DONE) begin
            hash_state_out <= {
               compression_state_loopback[159:128] + hash_state_in[159:128],
               compression_state_loopback[127:96 ] + hash_state_in[127:96 ],
               compression_state_loopback[ 95:64 ] + hash_state_in[ 95:64 ],
               compression_state_loopback[ 63:32 ] + hash_state_in[ 63:32 ],
               compression_state_loopback[ 31:0  ] + hash_state_in[ 31:0  ]
            };
         end
         else hash_state_out <= compression_state_loopback;
      end
      sm_state <= sm_next_state;
   end

endmodule
