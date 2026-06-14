`timescale 1ns/1ps

module router_top (
    input  wire        clk,          // System clock
    input  wire        resetn,       // Active-low synchronous reset
    input  wire        pkt_valid,    // Input packet valid signal
    input  wire [7:0]  data_in,      // 8-bit input data bus
    input  wire        read_enb_0,   // Read enable for FIFO 0
    input  wire        read_enb_1,   // Read enable for FIFO 1
    input  wire        read_enb_2,   // Read enable for FIFO 2
    output wire [7:0]  data_out_0,   // Output data from FIFO 0
    output wire [7:0]  data_out_1,   // Output data from FIFO 1
    output wire [7:0]  data_out_2,   // Output data from FIFO 2
    output wire        valid_out_0,  // Valid data at FIFO 0 output
    output wire        valid_out_1,  // Valid data at FIFO 1 output
    output wire        valid_out_2,  // Valid data at FIFO 2 output
    output wire        error         // Parity error flag
);

    // Internal wires between sub-modules

    wire        write_enb_0, write_enb_1, write_enb_2;
    wire        full_0, full_1, full_2;
    wire        empty_0, empty_1, empty_2;
    wire [7:0]  din_fifo;            // Data going into the selected FIFO
    wire        fifo_full;           // Full flag of currently selected FIFO
    wire        lfd_state;           // Load First Data state (header byte)
    wire        ld_state;            // Load Data state (payload bytes)
    wire        full_state;          // Full state from FSM
    wire        parity_done;         // Parity check completed
    wire        low_pkt_valid;       // Pkt valid de-asserted signal

    // Instantiate: FSM Controller (routing logic)
    router_fsm u_fsm (
        .clk           (clk),
        .resetn        (resetn),
        .pkt_valid     (pkt_valid),
        .data_in       (data_in),
        .fifo_full     (fifo_full),
        .fifo_empty_0  (empty_0),
        .fifo_empty_1  (empty_1),
        .fifo_empty_2  (empty_2),
        .parity_done   (parity_done),
        .low_pkt_valid (low_pkt_valid),
        .write_enb_0   (write_enb_0),
        .write_enb_1   (write_enb_1),
        .write_enb_2   (write_enb_2),
        .lfd_state     (lfd_state),
        .ld_state      (ld_state),
        .full_state    (full_state)
    );

    // Instantiate: Register Block (stores packet data)

    router_reg u_reg (
        .clk         (clk),
        .resetn      (resetn),
        .pkt_valid   (pkt_valid),
        .data_in     (data_in),
        .lfd_state   (lfd_state),
        .fifo_full   (fifo_full),
        .ld_state    (ld_state),
        .full_state  (full_state),
        .parity_done (parity_done),
        .low_pkt_valid(low_pkt_valid),
        .dout        (din_fifo),
        .error       (error),
        .parity_done_out(parity_done)
    );

    // Instantiate: Synchronizer (controls write enables)

    router_sync u_sync (
        .clk         (clk),
        .resetn      (resetn),
        .detect_add  (lfd_state),
        .data_in     (data_in),
        .empty_0     (empty_0),
        .empty_1     (empty_1),
        .empty_2     (empty_2),
        .read_enb_0  (read_enb_0),
        .read_enb_1  (read_enb_1),
        .read_enb_2  (read_enb_2),
        .write_enb_0 (write_enb_0),
        .write_enb_1 (write_enb_1),
        .write_enb_2 (write_enb_2),
        .full_0      (full_0),
        .full_1      (full_1),
        .full_2      (full_2),
        .fifo_full   (fifo_full),
        .vld_out_0   (valid_out_0),
        .vld_out_1   (valid_out_1),
        .vld_out_2   (valid_out_2)
    );

    // Instantiate: FIFO 0 (destination 0)

    router_fifo u_fifo0 (
        .clk       (clk),
        .resetn    (resetn),
        .write_enb (write_enb_0),
        .read_enb  (read_enb_0),
        .data_in   (din_fifo),
        .full      (full_0),
        .empty     (empty_0),
        .data_out  (data_out_0)
    );

    // Instantiate: FIFO 1 (destination 1)

    router_fifo u_fifo1 (
        .clk       (clk),
        .resetn    (resetn),
        .write_enb (write_enb_1),
        .read_enb  (read_enb_1),
        .data_in   (din_fifo),
        .full      (full_1),
        .empty     (empty_1),
        .data_out  (data_out_1)
    );


    // Instantiate: FIFO 2 (destination 2)

    router_fifo u_fifo2 (
        .clk       (clk),
        .resetn    (resetn),
        .write_enb (write_enb_2),
        .read_enb  (read_enb_2),
        .data_in   (din_fifo),
        .full      (full_2),
        .empty     (empty_2),
        .data_out  (data_out_2)
    );

endmodule
