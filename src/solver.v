/*
 * Takes in (x, y) coordinates and
 * goes through `n` steps of solving
 * the ODE, raising `is_point` (and
 * keeping it raised) if (x, y) is
 * one of those points.
 *
 * Once `xin` changes, resets
 * and redoes process.
 *
 * On `step`, moves starting point
 * forward one time step so that the
 * originally-first point is no longer
 * counted but now a new, additional
 * point is counted.
 */
module solver(
  input wire clk,
  input wire rst,
  input wire signed [7:0] xin,
  input wire signed [7:0] yin,
  output wire is_point,
  input wire step
);

  localparam a =  2'sd0;
  localparam b = -2'sd1;
  localparam c =  2'sd1;
  localparam d =  2'sd0;

  reg signed [7:0] old_x;
  always @(posedge clk) begin
    if (rst) old_x <= 8'sd0;
    else old_x <= xin;
  end

  wire changed_coords = old_x != xin;

  reg signed [7:0] start_x, start_y;
  wire signed [7:0] next_start_x, next_start_y;
  always @(posedge clk) begin
    if (rst) begin
      start_x <= 8'sd4;
      start_y <= 8'sd0;
    end else if (step) begin
      start_x <= next_start_x;
      start_y <= next_start_y;
    end else begin
      start_x <= start_x;
      start_y <= start_y;
    end
  end

  solver_step start_stepper(
    .xin(start_x),
    .yin(start_y),
    .xout(next_start_x),
    .yout(next_start_y),
    .a(a),
    .b(b),
    .c(c),
    .d(d)
  );

  reg signed [7:0] curr_x, curr_y;
  wire signed [7:0] next_curr_x, next_curr_y;
  always @(posedge clk) begin
    if (rst) begin
      curr_x <= 8'sd4;
      curr_y <= 8'sd0;
    end else begin
      curr_x <= next_curr_x;
      curr_y <= next_curr_y;
    end
  end

  solver_step curr_stepper(
    .xin(changed_coords ? start_x : curr_x),
    .yin(changed_coords ? start_y : curr_y),
    .xout(next_curr_x),
    .yout(next_curr_y),
    .a(a),
    .b(b),
    .c(c),
    .d(d)
  );

  wire match_start = (xin == start_x) & (yin == start_y);
  wire match_curr = (xin == curr_x) & (yin == curr_y);
  wire seen_point = (~changed_coords & match_curr) | (changed_coords & match_start);

  reg saved_seen;
  always @(posedge clk) begin
    if (rst) begin
      saved_seen <= 1'b0;
    end else if (changed_coords) begin
      saved_seen <= seen_point;
    end else begin
      saved_seen <= saved_seen | seen_point;
    end
  end

  assign is_point = seen_point | (saved_seen & ~changed_coords);

endmodule


// Simple Euler's method for solving ODEs,
// with a pretty bad timestep of 0.25
// and even worse quantization
module solver_step(
  input wire signed [7:0] xin,
  input wire signed [7:0] yin,
  output wire signed [7:0] xout,
  output wire signed [7:0] yout,
  input wire signed [1:0] a,
  input wire signed [1:0] b,
  input wire signed [1:0] c,
  input wire signed [1:0] d
);
  // VGA playground doesn't seem to support arithmetic right shift :(
  // start_x <= start_x - (start_y >>> 2);
  // start_y <= start_y + (start_x >>> 2);
  assign xout = xin 
                  + a * $signed({xin[7] ? 2'b11 : 2'b00, xin[7:2]}) 
                  + b * $signed({yin[7] ? 2'b11 : 2'b00, yin[7:2]});
  assign yout = yin 
                  + c * $signed({xin[7] ? 2'b11 : 2'b00, xin[7:2]})
                  + d * $signed({yin[7] ? 2'b11 : 2'b00, yin[7:2]});

endmodule
