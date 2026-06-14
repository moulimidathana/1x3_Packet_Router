`timescale 1ns/1ps
module router_fsm (
    input  wire        clk,
    input  wire        resetn,
    input  wire        pkt_valid,      // Input packet valid
    input  wire [7:0]  data_in,        // 8-bit input data
    input  wire        fifo_full,      // Selected FIFO is full
    input  wire        fifo_empty_0,   // FIFO 0 empty flag
    input  wire        fifo_empty_1,   // FIFO 1 empty flag
    input  wire        fifo_empty_2,   // FIFO 2 empty flag
    input  wire        parity_done,    // Parity check done
    input  wire        low_pkt_valid,  // pkt_valid de-asserted
    output reg         write_enb_0,    // Write enable FIFO 0
    output reg         write_enb_1,    // Write enable FIFO 1
    output reg         write_enb_2,    // Write enable FIFO 2
    output reg         lfd_state,      // Load First Data state
    output reg         ld_state,       // Load Data state
    output reg         full_state      // FIFO Full state
);

    // State Encoding (One-Hot for speed in FPGAs)

    localparam [2:0]
        DECODE_ADDRESS   = 3'd0,
        LOAD_FIRST_DATA  = 3'd1,
        LOAD_DATA        = 3'd2,
        LOAD_PARITY      = 3'd3,
        FIFO_FULL_STATE  = 3'd4,
        WAIT_TILL_EMPTY  = 3'd5,
        CHECK_PARITY_ERR = 3'd6;

    reg [2:0] state, next_state;

    // Decoded destination from header [1:0]
    reg [1:0] dest_addr;

    // Sequential: State Register

    always @(posedge clk) begin
        if (!resetn)
            state <= DECODE_ADDRESS;
        else
            state <= next_state;
    end


    // Sequential: Capture Destination Address

    always @(posedge clk) begin
        if (!resetn)
            dest_addr <= 2'b00;
        else if (state == DECODE_ADDRESS && pkt_valid)
            dest_addr <= data_in[1:0];  // Lower 2 bits = dest
    end

    // Combinational: Next State Logic

    always @(*) begin
        next_state = state;  // Default: stay in current state
        case (state)

            DECODE_ADDRESS: begin
                if (pkt_valid) begin
                    // Check if target FIFO is empty (safe to write)
                    case (data_in[1:0])
                        2'b00: next_state = fifo_empty_0 ? LOAD_FIRST_DATA : WAIT_TILL_EMPTY;
                        2'b01: next_state = fifo_empty_1 ? LOAD_FIRST_DATA : WAIT_TILL_EMPTY;
                        2'b10: next_state = fifo_empty_2 ? LOAD_FIRST_DATA : WAIT_TILL_EMPTY;
                        default: next_state = DECODE_ADDRESS;
                    endcase
                end
            end

            LOAD_FIRST_DATA: begin
                next_state = LOAD_DATA;
            end

            LOAD_DATA: begin
                if (fifo_full)
                    next_state = FIFO_FULL_STATE;
                else if (low_pkt_valid)
                    next_state = LOAD_PARITY;
                else
                    next_state = LOAD_DATA;
            end

            FIFO_FULL_STATE: begin
                if (!fifo_full) begin
                    if (low_pkt_valid)
                        next_state = LOAD_PARITY;
                    else
                        next_state = LOAD_DATA;
                end
            end

            LOAD_PARITY: begin
                next_state = CHECK_PARITY_ERR;
            end

            CHECK_PARITY_ERR: begin
                if (parity_done)
                    next_state = DECODE_ADDRESS;
            end

            WAIT_TILL_EMPTY: begin
                case (dest_addr)
                    2'b00: next_state = fifo_empty_0 ? LOAD_FIRST_DATA : WAIT_TILL_EMPTY;
                    2'b01: next_state = fifo_empty_1 ? LOAD_FIRST_DATA : WAIT_TILL_EMPTY;
                    2'b10: next_state = fifo_empty_2 ? LOAD_FIRST_DATA : WAIT_TILL_EMPTY;
                    default: next_state = DECODE_ADDRESS;
                endcase
            end

            default: next_state = DECODE_ADDRESS;
        endcase
    end

    // Combinational: Output Logic (Moore FSM)

    always @(*) begin
        // Default outputs
        write_enb_0 = 1'b0;
        write_enb_1 = 1'b0;
        write_enb_2 = 1'b0;
        lfd_state   = 1'b0;
        ld_state    = 1'b0;
        full_state  = 1'b0;

        case (state)
            LOAD_FIRST_DATA: begin
                lfd_state = 1'b1;
                case (dest_addr)
                    2'b00: write_enb_0 = 1'b1;
                    2'b01: write_enb_1 = 1'b1;
                    2'b10: write_enb_2 = 1'b1;
                    default: ;
                endcase
            end

            LOAD_DATA: begin
                ld_state = 1'b1;
                if (!fifo_full) begin
                    case (dest_addr)
                        2'b00: write_enb_0 = 1'b1;
                        2'b01: write_enb_1 = 1'b1;
                        2'b10: write_enb_2 = 1'b1;
                        default: ;
                    endcase
                end
            end

            FIFO_FULL_STATE: begin
                full_state = 1'b1;
            end

            LOAD_PARITY: begin
                case (dest_addr)
                    2'b00: write_enb_0 = 1'b1;
                    2'b01: write_enb_1 = 1'b1;
                    2'b10: write_enb_2 = 1'b1;
                    default: ;
                endcase
            end

            default: ;
        endcase
    end

endmodule
