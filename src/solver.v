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

  reg signed [7:0] old_x;
  always @(posedge clk) begin
    if (rst) old_x <= 8'sd0;
    else old_x <= x;
  end

  wire changed_coords = old_x != x;

  reg signed [7:0] start_x;
  reg signed [7:0] start_y;
  always @(posedge clk) begin
    if (rst) begin
      start_x <= 7'sd4;
      start_y <= 7'sd0;
    end else if (step) begin
      // VGA playground doesn't seem to support arithmetic right shift :(
      // start_x <= start_x - (start_y >>> 2);
      // start_y <= start_y + (start_x >>> 2);
      start_x <= start_x
        + 0 * {start_x[7] ? 2'b11 : 2'b00, start_x[7:2]} 
        + (-1) * {start_y[7] ? 2'b11 : 2'b00, start_y[7:2]};
      start_y <= start_y
        + {start_x[7] ? 2'b11 : 2'b00, start_x[7:2]}
        + 0 * {start_y[7] ? 2'b11 : 2'b00, start_y[7:2]};
    end else begin
      start_x <= start_x;
      start_y <= start_y;
    end
  end

  reg signed [7:0] curr_x;
  reg signed [7:0] curr_y;
  always @(posedge clk) begin
    if (~rst_n) begin
      curr_x <= 7'sd4;
      curr_y <= 7'sd0;
    end else if (changed_coords) begin
      curr_x <= start_x 
        + 0 * {start_x[7] ? 2'b11 : 2'b00, start_x[7:2]} 
        + (-1) * {start_y[7] ? 2'b11 : 2'b00, start_y[7:2]};
      curr_y <= curr_y
        + {start_x[7] ? 2'b11 : 2'b00, start_x[7:2]}
        + 0 * {start_y[7] ? 2'b11 : 2'b00, start_y[7:2]};
    end else begin
      curr_x <= curr_x
        + 0 * {curr_x[7] ? 2'b11 : 2'b00, curr_x[7:2]} 
        + (-1) * {curr_y[7] ? 2'b11 : 2'b00, curr_y[7:2]};
      curr_y <= curr_y
        + {curr_x[7] ? 2'b11 : 2'b00, curr_x[7:2]}
        + 0 * {curr_y[7] ? 2'b11 : 2'b00, curr_y[7:2]};
    end
  end

  wire match_start = (xin == start_x) & (yin == curr_y);
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
