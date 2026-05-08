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

  reg [21:0] counter;
  always @(posedge clk) begin
    if (~rst_n) begin
      counter <= 0;
    end else begin
      counter <= counter + 1;
    end
  end

  reg signed [7:0] curr_x;
  reg signed [7:0] curr_y;
  always @(posedge clk) begin
    if (~rst_n) begin
      curr_x <= 7'sd4;
      curr_y <= 7'sd0;
    end else if (counter == 0) begin
      // VGA playground doesn't seem to support arithmetic right shift :(
      // curr_x <= curr_x - (curr_y >>> 2);
      // curr_y <= curr_y + (curr_x >>> 2);
      curr_x <= curr_x
        + 0 * {curr_x[7] ? 2'b11 : 2'b00, curr_x[7:2]} 
        + (-1) * {curr_y[7] ? 2'b11 : 2'b00, curr_y[7:2]};
      curr_y <= curr_y
        + {curr_x[7] ? 2'b11 : 2'b00, curr_x[7:2]}
        + 0 * {curr_y[7] ? 2'b11 : 2'b00, curr_y[7:2]};
    end else begin
      curr_x <= curr_x;
      curr_y <= curr_y;
    end
  end
  
  wire on_curr = (grid_centered_x == curr_x) & (grid_centered_y == curr_y);
  wire x_axis = grid_centered_y == 0;
  wire y_axis = grid_centered_x == 0;
  assign R = video_active ? (on_curr ? 2'b11 :
              (x_axis | y_axis) ? 2'b01 : 2'b00) : 2'b00;
  assign G = video_active ? (on_curr ? 2'b11 :
              (x_axis | y_axis) ? 2'b01 : 2'b00) : 2'b00;
  assign B = video_active ? (on_curr ? 2'b11 :
              (x_axis | y_axis) ? 2'b01 : 2'b00) : 2'b00;
  
  /*
  assign R = video_active ? {grid_centered_x[0], grid_centered_y[0]} : 2'b00;
  assign G = video_active ? {grid_centered_x[0], grid_centered_y[0]} : 2'b00;
  assign B = video_active ? {grid_centered_x[0], grid_centered_y[0]} : 2'b00;
  */
  /*
  assign R = video_active ? {grid_x[0], grid_y[0]} : 2'b00;
  assign G = video_active ? {grid_x[0], grid_y[0]} : 2'b00;
  assign B = video_active ? {grid_x[0], grid_y[0]} : 2'b00;
  */
  /*
  wire [9:0] moving_x = pix_x + counter;

  assign R = video_active ? {moving_x[5], pix_y[2]} : 2'b00;
  assign G = video_active ? {moving_x[6], pix_y[2]} : 2'b00;
  assign B = video_active ? {moving_x[7], pix_y[5]} : 2'b00;
  
  always @(posedge vsync, negedge rst_n) begin
    if (~rst_n) begin
      counter <= 0;
    end else begin
      counter <= counter + 1;
    end
  end
  */

  // Suppress unused signals warning
  wire _unused_ok_ = &{grid_x, grid_y};

endmodule
