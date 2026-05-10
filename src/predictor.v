/*
 * Takes in x in [-80, 79], y in [59, -60],
 * and looks ahead by 1 to see what RGB would be.
 * Meanwhile, saves previous RGB and outputs.
 *
 * Essentially allows buffer time to calculate
 * if a given point should be on while rendering
 * horizontal pixels in a square
 */
module predictor(
  input wire clk,
  input wire rst,
  input wire signed [7:0] xc,
  input wire signed [7:0] yc,
  output wire [5:0] curr_rgb,
  output wire signed [7:0] xcn, // next centered x
  output wire signed [7:0] ycn, // next centered y
  input wire [5:0] next_rgb
);

  reg signed [7:0] old_xc;
  always @(posedge clk) begin
    if (rst) old_xc <= 8'sd0;
    else old_xc <= xc;
  end

  wire squares_changed = old_xc != xc;

  reg [5:0] old_rgb;
  always @(posedge clk) begin
    if (rst) old_rgb <= 6'b0;
    else old_rgb <= next_rgb;
  end

  reg [5:0] saved_rgb;
  always @(posedge clk) begin
    if (rst) saved_rgb <= 6'b0;
    else if (squares_changed) saved_rgb <= old_rgb;
    else saved_rgb <= saved_rgb;
  end

  assign curr_rgb = squares_changed ? old_rgb : saved_rgb;
  assign xcn = xc + 8'sd1;
  assign ycn = (xc == 8'sd79) ? yc - 8'sd1 : yc;

endmodule
