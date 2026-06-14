`timescale 1ns/1ps

module router_reg (
    input  wire        clk,
    input  wire        resetn,
    input  wire        pkt_valid,      // Input packet valid
    input  wire [7:0]  data_in,        // Raw input data
    input  wire        lfd_state,      // Load First Data (header)
    input  wire        fifo_full,      // FIFO is full
    input  wire        ld_state,       // Load Data (payload)
    input  wire        full_state,     // FSM in full state
    input  wire        low_pkt_valid,  // pkt_valid just deasserted
    input  wire        parity_done,    // Parity check done (looped)
    output reg  [7:0]  dout,           // Data output to FIFOs
    output wire        error,          // Parity error flag
    output reg         parity_done_out // Signals parity computation done
);

    reg [7:0]  header_byte;       // Stored header byte
    reg [7:0]  internal_parity;   // Running XOR of received bytes
    reg [7:0]  packet_parity;     // Parity byte received from input
    reg        err_reg;           // Latched error flag

    assign error = err_reg;

       // Header register: capture on lfd_state (first data beat)
   
    always @(posedge clk) begin
        if (!resetn)
            header_byte <= 8'h00;
        else if (lfd_state)
            header_byte <= data_in;
    end

       // Data output mux:
    //   - lfd_state  ? send stored header
    //   - ld_state   ? send current payload byte
    //   - full_state ? hold previous value
   
  always @(posedge clk) begin
        if (!resetn)
            dout <= 8'h00;
        else if (lfd_state)
            dout <= data_in;          // First payload byte (after header captured)
        else if (ld_state && !fifo_full)
            dout <= data_in;          // Payload bytes
        else if (full_state)
            dout <= dout;             // Hold during stall
    end

      // Internal parity calculation: XOR accumulator
    // Reset when lfd_state (new packet); accumulate each cycle
  
    always @(posedge clk) begin
        if (!resetn)
            internal_parity <= 8'h00;
        else if (lfd_state)
            internal_parity <= data_in;           // Start with header byte
        else if (ld_state && pkt_valid)
            internal_parity <= internal_parity ^ data_in;  // XOR payload
    end

      // Packet parity byte: captured when pkt_valid deasserts
      always @(posedge clk) begin
        if (!resetn)
            packet_parity <= 8'h00;
        else if (low_pkt_valid)
            packet_parity <= data_in;   // Last byte from sender is parity
    end

      // Parity done flag: goes high one cycle after parity captured
  
    always @(posedge clk) begin
        if (!resetn)
            parity_done_out <= 1'b0;
        else if (low_pkt_valid)
            parity_done_out <= 1'b1;
        else
            parity_done_out <= 1'b0;
    end

    // Error detection: compare calculated vs received parity
  
    always @(posedge clk) begin
        if (!resetn)
            err_reg <= 1'b0;
        else if (parity_done_out)
            err_reg <= (internal_parity != packet_parity);
        else
            err_reg <= 1'b0;
    end

endmodule
