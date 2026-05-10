/*
 * Copyright (c) 2026 Marcus Alagar
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_bad_ode_plotter_vga (
  input  wire [7:0] ui_in,    // Dedicated inputs
  output wire [7:0] uo_out,   // Dedicated outputs
  input  wire [7:0] uio_in,   // IOs: Input path
  output wire [7:0] uio_out,  // IOs: Output path
  output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
  input  wire       ena,      // always 1 when the design is powered, so you can ignore it
  input  wire       clk,      // clock
  input  wire       rst_n     // reset_n - low to reset
);

  // VGA signals
  wire hsync;
  wire vsync;
  wire [1:0] R;
  wire [1:0] G;
  wire [1:0] B;
  wire video_active;

  // TinyVGA PMOD
  assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};

  // Unused outputs assigned to 0.
  assign uio_out = 0;
  assign uio_oe  = 0;

  // Suppress unused signals warning
  wire _unused_ok = &{ena, ui_in, uio_in};

  wire [9:0] raw_x;
  wire [9:0] raw_y;
  hvsync_generator hvsync_gen(
    .clk(clk),
    .reset(~rst_n),
    .hsync(hsync),
    .vsync(vsync),
    .display_on(video_active),
    .hpos(raw_x),
    .vpos(raw_y)
  );

  wire [7:0] grid_x, grid_y;
  gridder grid(
    .hpos(raw_x),
    .vpos(raw_y),
    .x(grid_x),
    .y(grid_y)
  );

  wire signed [7:0] grid_centered_x, grid_centered_y;
  centerer center(
    .x(grid_x),
    .y(grid_y),
    .xc(grid_centered_x),
    .yc(grid_centered_y)
  );

  wire signed [7:0] next_grid_centered_x, next_grid_centered_y;
  wire [5:0] curr_rgb, next_rgb;
  predictor predict(
    .clk(clk),
    .rst(~rst_n),
    .xc(grid_centered_x),
    .yc(grid_centered_y),
    .curr_rgb(curr_rgb),
    .xcn(next_grid_centered_x),
    .ycn(next_grid_centered_y),
    .next_rgb(next_rgb)
  );

  reg [21:0] counter;
  always @(posedge clk) begin
    if (~rst_n) begin
      counter <= 0;
    end else begin
      counter <= counter + 1;
    end
  end

  wire is_next_point;
  solver sol(
    .clk(clk),
    .rst(~rst_n),
    .xin(next_grid_centered_x),
    .yin(next_grid_centered_y),
    .is_point(is_next_point),
    .step(counter == 0)
  );

  wire x_axis = next_grid_centered_y == 0;
  wire y_axis = next_grid_centered_x == 0;
  assign next_rgb[5:4] = video_active ? (is_next_point ? 2'b11 :
              (x_axis | y_axis) ? 2'b01 : 2'b00) : 2'b00;
  assign next_rgb[3:2] = video_active ? (is_next_point ? 2'b11 :
              (x_axis | y_axis) ? 2'b01 : 2'b00) : 2'b00;
  assign next_rgb[1:0] = video_active ? (is_next_point ? 2'b11 :
              (x_axis | y_axis) ? 2'b01 : 2'b00) : 2'b00;

  assign {R, G, B} = video_active ? curr_rgb : 6'b000000;

  // Suppress unused signals warning
  wire _unused_ok_ = &{grid_x, grid_y};

endmodule
