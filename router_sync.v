module router_sync (
    input  wire        clk,
    input  wire        resetn,
    input  wire        detect_add,   // lfd_state: new header arriving
    input  wire [7:0]  data_in,      // Header byte (has dest address)
    input  wire        empty_0,
    input  wire        empty_1,
    input  wire        empty_2,
    input  wire        read_enb_0,   // Read enables from testbench
    input  wire        read_enb_1,
    input  wire        read_enb_2,
    input  wire        write_enb_0,  // Write enables from FSM
    input  wire        write_enb_1,
    input  wire        write_enb_2,
    input  wire        full_0,       // Full flags from FIFOs
    input  wire        full_1,
    input  wire        full_2,
    output reg         fifo_full,    // Selected FIFO full flag ? FSM
    output wire        vld_out_0,    // Valid output flags
    output wire        vld_out_1,
    output wire        vld_out_2
);

    reg [1:0] addr_reg;   // Registered destination address

    
    // Capture destination address on new packet header
        always @(posedge clk) begin
        if (!resetn)
            addr_reg <= 2'b00;
        else if (detect_add)
            addr_reg <= data_in[1:0];
    end

    
    // Route the correct FIFO full flag back to FSM

    always @(*) begin
        case (addr_reg)
            2'b00: fifo_full = full_0;
            2'b01: fifo_full = full_1;
            2'b10: fifo_full = full_2;
            default: fifo_full = 1'b0;
        endcase
    end

   // valid_out: FIFO is not empty (data available to read)
   assign vld_out_0 = ~empty_0;
    assign vld_out_1 = ~empty_1;
    assign vld_out_2 = ~empty_2;
  
endmodule

