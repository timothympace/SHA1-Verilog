module sha1_compression(
   input  [159:0] hash_state_in,
   input  [ 31:0] w,
   input  [  6:0] round,
   output [159:0] hash_state_out
);

   reg  [31:0] k;
   reg  [31:0] f;
   wire [31:0] temp;
   
   wire [31:0] a = hash_state_in[159:128];
   wire [31:0] b = hash_state_in[127:96 ];
   wire [31:0] c = hash_state_in[ 95:64 ];
   wire [31:0] d = hash_state_in[ 63:32 ];
   wire [31:0] e = hash_state_in[ 31:0  ];
   
   assign temp = {a[26:0], a[31:27]} + f + e + k + w;
   assign hash_state_out = {temp, a, {b[1:0], b[31:2]}, c, d};
     
   always @ (round or b or c or d) begin
      case (1'b1)
         between(7'd0,  round, 7'd19): begin k = 32'h5A827999; f = (b & c) | (~b & d); end
         between(7'd20, round, 7'd39): begin k = 32'h6ED9EBA1; f = b ^ c ^ d; end
         between(7'd40, round, 7'd59): begin k = 32'h8F1BBCDC; f = (b & c) | (b & d) | (c & d); end
         between(7'd60, round, 7'd79): begin k = 32'hCA62C1D6; f = b ^ c ^ d; end
      endcase
   end
   
   function reg between(input [6:0] low, value, high); 
      begin
         between = value >= low && value <= high;
      end
   endfunction

endmodule
