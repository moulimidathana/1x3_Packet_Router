`timescale 1ns/1ps

module router_fifo #(
    parameter DEPTH = 16,   // Number of entries
    parameter WIDTH = 8     // Data width in bits
)(
    input  wire             clk,       // System clock
    input  wire             resetn,    // Active-low synchronous reset
    input  wire             write_enb, // Write enable
    input  wire             read_enb,  // Read enable
    input  wire [WIDTH-1:0] data_in,   // Write data
    output wire             full,      // FIFO is full
    output wire             empty,     // FIFO is empty
    output reg  [WIDTH-1:0] data_out   // Read data
);

       // Internal memory and pointers
   
  localparam PTR_W = $clog2(DEPTH);   // Pointer width (4 bits for depth=16)

    reg [WIDTH-1:0] mem [0:DEPTH-1];   // Storage array

    reg [PTR_W:0]   wr_ptr;            // Write pointer (extra bit for full/empty detect)
    reg [PTR_W:0]   rd_ptr;            // Read pointer  (extra bit for full/empty detect)

      // Full and Empty flags
      // Full  : pointers differ only in MSB
    // Empty : pointers are identical
    assign full  = (wr_ptr[PTR_W] != rd_ptr[PTR_W]) &&
                   (wr_ptr[PTR_W-1:0] == rd_ptr[PTR_W-1:0]);
    assign empty = (wr_ptr == rd_ptr);

  
    // Write Logic
  
    always @(posedge clk) begin
        if (!resetn) begin
            wr_ptr <= 0;
        end else if (write_enb && !full) begin
            mem[wr_ptr[PTR_W-1:0]] <= data_in;
            wr_ptr <= wr_ptr + 1'b1;
        end
    end

  
    // Read Logic
     always @(posedge clk) begin
        if (!resetn) begin
            rd_ptr   <= 0;
            data_out <= 0;
        end else if (read_enb && !empty) begin
            data_out <= mem[rd_ptr[PTR_W-1:0]];
            rd_ptr   <= rd_ptr + 1'b1;
        end
    end

endmodule

