`timescale 1ns/1ps

module tb_router_top;

    reg         clk;
    reg         resetn;
    reg         pkt_valid;
    reg  [7:0]  data_in;
    reg         read_enb_0, read_enb_1, read_enb_2;

    wire [7:0]  data_out_0, data_out_1, data_out_2;
    wire        valid_out_0, valid_out_1, valid_out_2;
    wire        error;

    // DUT
    router_top dut (
        .clk         (clk),
        .resetn      (resetn),
        .pkt_valid   (pkt_valid),
        .data_in     (data_in),
        .read_enb_0  (read_enb_0),
        .read_enb_1  (read_enb_1),
        .read_enb_2  (read_enb_2),
        .data_out_0  (data_out_0),
        .data_out_1  (data_out_1),
        .data_out_2  (data_out_2),
        .valid_out_0 (valid_out_0),
        .valid_out_1 (valid_out_1),
        .valid_out_2 (valid_out_2),
        .error       (error)
    );

    // Clock
    initial clk = 0;
    always #5 clk = ~clk;

    // Monitor
    initial begin
        $monitor("[%0t] d0=%h d1=%h d2=%h | vld={%b,%b,%b} | err=%b",
                 $time, data_out_0, data_out_1, data_out_2,
                 valid_out_0, valid_out_1, valid_out_2, error);
    end

    // Main Test
    initial begin
        pkt_valid  = 0;
        data_in    = 0;
        read_enb_0 = 0;
        read_enb_1 = 0;
        read_enb_2 = 0;

        // Reset
        resetn = 0;
        repeat(5) @(posedge clk);
        resetn = 1;

        // -------- TEST 1 --------
        send_packet(2'b00, 4, 1'b1);
        #20;
        read_fifo(0, 6);

        // -------- TEST 2 --------
        send_packet(2'b01, 3, 1'b1);
        #20;
        read_fifo(1, 5);

        // -------- TEST 3 --------
        send_packet(2'b10, 5, 1'b1);
        #20;
        read_fifo(2, 7);

        // -------- TEST 4 (Error) --------
        send_packet(2'b00, 4, 1'b0);
        #20;

        // -------- TEST 5 --------
        send_packet(2'b10, 2, 1'b1);
        #5;
        send_packet(2'b10, 2, 1'b1);
        #20;
        read_fifo(2, 4);
        read_fifo(2, 4);

        #100 $finish;
    end

    
    // TASK: SEND PACKET
    
    task send_packet;
        input [1:0] dest;
        input [5:0] payload_len;
        input correct_parity;

        reg [7:0] header;
        reg [7:0] parity_calc;
        reg [7:0] payload;
        integer i;

        begin
            header = {payload_len, dest};
            parity_calc = header;

            // Header
            @(negedge clk);
            pkt_valid = 1;
            data_in = header;

            // Payload
            for (i=1; i<=payload_len; i=i+1) begin
                @(posedge clk);
                payload = i * 8'h11;
                parity_calc = parity_calc ^ payload;
                data_in = payload;
            end

            // Parity
            @(posedge clk);
            pkt_valid = 0;

            if (!correct_parity)
                parity_calc = ~parity_calc;

            data_in = parity_calc;

            @(posedge clk);
            data_in = 0;
        end
    endtask

        // TASK: READ FIFO
    
    task read_fifo;
        input integer port;
        input integer count;

        integer j;
        begin
            for (j=0; j<count; j=j+1) begin
                @(negedge clk);
                case(port)
                    0: read_enb_0 = 1;
                    1: read_enb_1 = 1;
                    2: read_enb_2 = 1;
                endcase

                @(posedge clk);

                case(port)
                    0: read_enb_0 = 0;
                    1: read_enb_1 = 0;
                    2: read_enb_2 = 0;
                endcase
            end
        end
    endtask

endmodule
