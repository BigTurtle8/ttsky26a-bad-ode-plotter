/*
 * Transforms hpos, vpos coordinates into
 * x, y coords in a grid of 8x8 squares.
 */
module gridder(
  input wire [9:0] hpos,
  input wire [9:0] vpos,
  output wire [7:0] x,
  output wire [7:0] y
);
  // declarations for TV-simulator sync parameters
  // horizontal constants
  parameter H_DISPLAY       = 640; // horizontal display width
  parameter H_BACK          =  48; // horizontal left border (back porch)
  parameter H_FRONT         =  16; // horizontal right border (front porch)
  parameter H_SYNC          =  96; // horizontal sync width
  // vertical constants
  parameter V_DISPLAY       = 480; // vertical display height
  parameter V_TOP           =  33; // vertical top border
  parameter V_BOTTOM        =  10; // vertical bottom border
  parameter V_SYNC          =   2; // vertical sync # lines
  // derived constants
  parameter H_SYNC_START    = H_DISPLAY + H_FRONT;
  parameter H_SYNC_END      = H_DISPLAY + H_FRONT + H_SYNC - 1;
  parameter H_MAX           = H_DISPLAY + H_BACK + H_FRONT + H_SYNC - 1;
  parameter V_SYNC_START    = V_DISPLAY + V_BOTTOM;
  parameter V_SYNC_END      = V_DISPLAY + V_BOTTOM + V_SYNC - 1;
  parameter V_MAX           = V_DISPLAY + V_TOP + V_BOTTOM + V_SYNC - 1;

  wire [9:0] shft_hpos = hpos >> 2;
  wire [9:0] shft_vpos = vpos >> 2;
  assign x = (hpos < H_DISPLAY) ? shft_hpos[7:0] : 8'd159;
  assign y = (vpos < V_DISPLAY) ? shft_vpos[7:0] : 8'd119;
endmodule