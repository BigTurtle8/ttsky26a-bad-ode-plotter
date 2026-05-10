/*
 * Transforms x, y coordinates with
 * x in [0, 159], y in [0, 119]
 * to x in [-80, 79], y in [59, -60],
 * flipping y so that quadrants match
 * up as expected
 */
module centerer(
  input wire [7:0] x,
  input wire [7:0] y,
  output wire signed [7:0] xc,
  output wire signed [7:0] yc
);
  wire signed [8:0] ext_x = $signed(x);
  wire signed [8:0] ext_y = $signed(y);
  assign xc = ext_x - 8'sd80;
  assign yc = -ext_y + 8'sd59;
endmodule
