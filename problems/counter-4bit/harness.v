// Self-checking testbench for counter_4bit.
// Compiles against either starter.v or reference.v (same module name/ports).
module tb_counter_4bit;
    // RNG seed: hardcoded (not time-based). Applied once below via $urandom(SEED).
    localparam [31:0] SEED = 32'hC0A7_0004;
    localparam integer NUM_RANDOM = 80;

    reg        clk;
    reg        rst;
    wire [3:0] q;

    integer passed;
    integer total;
    integer i;
    integer j;
    integer n;
    integer seed;
    integer seed_sink;

    reg         first_fail_valid;
    reg  [3:0]  model_q;
    reg         first_fail_in_rst;
    reg  [3:0]  first_fail_in_prev_q;
    reg  [3:0]  first_fail_expected;
    reg  [3:0]  first_fail_got;

    counter_4bit dut (
        .clk(clk),
        .rst(rst),
        .q(q)
    );

    // 10 time-unit clock period.
    initial clk = 1'b0;
    always #5 clk = ~clk;

    task automatic check_q;
        input [3:0] expected;
        input       applied_rst;
        input [3:0] prev_q;
        begin
            total = total + 1;
            if (q === expected) begin
                passed = passed + 1;
            end else if (!first_fail_valid) begin
                first_fail_valid = 1'b1;
                first_fail_in_rst = applied_rst;
                first_fail_in_prev_q = prev_q;
                first_fail_expected = expected;
                first_fail_got = q;
            end
        end
    endtask

    task automatic step_with_rst;
        input do_rst;
        reg [3:0] prev_q;
        begin
            prev_q = model_q;
            @(negedge clk);
            rst = do_rst;
            @(posedge clk);
            #1;
            if (do_rst)
                model_q = 4'b0000;
            else
                model_q = model_q + 4'd1;
            check_q(model_q, do_rst, prev_q);
        end
    endtask

    initial begin
        passed = 0;
        total = 0;
        first_fail_valid = 1'b0;
        rst = 1'b1;
        model_q = 4'b0000;

        // Seed set HERE: copy hardcoded SEED into an integer, then $urandom(seed).
        // Icarus requires the seed argument to be an integer/time/reg variable.
        seed = SEED;
        seed_sink = $urandom(seed);

        // Directed: reset, then count through wrap (0..15..0), then mid-sequence reset.
        step_with_rst(1'b1);
        for (i = 0; i < 17; i = i + 1) begin
            step_with_rst(1'b0);
        end
        step_with_rst(1'b1);
        step_with_rst(1'b0);
        step_with_rst(1'b0);
        step_with_rst(1'b1);

        // Random: mix of reset and count cycles (reproducible because of SEED above).
        for (i = 0; i < NUM_RANDOM; i = i + 1) begin
            // Bias toward count so wraparound is exercised; ~1/8 cycles are reset.
            if (($urandom % 8) == 0)
                step_with_rst(1'b1);
            else begin
                n = ($urandom % 4) + 1;
                for (j = 0; j < n; j = j + 1) begin
                    step_with_rst(1'b0);
                end
            end
        end

        if (first_fail_valid) begin
            $display(
                "RESULT {\"passed\":%0d,\"total\":%0d,\"first_fail\":{\"in\":\"rst=%0d,prev_q=%0h\",\"expected\":\"%0h\",\"got\":\"%0h\"}}",
                passed,
                total,
                first_fail_in_rst,
                first_fail_in_prev_q,
                first_fail_expected,
                first_fail_got
            );
        end else begin
            $display("RESULT {\"passed\":%0d,\"total\":%0d}", passed, total);
        end
        $finish;
    end
endmodule
