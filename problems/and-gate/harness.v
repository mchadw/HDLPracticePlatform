// Self-checking testbench for and_gate.
// Compiles against either starter.v or reference.v (same module name/ports).
module tb_and_gate;
    // RNG seed: hardcoded (not time-based). Applied once below via $urandom(SEED).
    localparam [31:0] SEED = 32'hA11D_0001;
    localparam integer NUM_RANDOM = 64;

    reg a;
    reg b;
    wire y;

    integer passed;
    integer total;
    integer i;
    integer seed_sink;

    reg        first_fail_valid;
    reg [1:0]  first_fail_in;
    reg        first_fail_expected;
    reg        first_fail_got;

    and_gate dut (
        .a(a),
        .b(b),
        .y(y)
    );

    task automatic check;
        input expected;
        begin
            total = total + 1;
            #1;
            if (y === expected) begin
                passed = passed + 1;
            end else if (!first_fail_valid) begin
                first_fail_valid = 1'b1;
                first_fail_in = {a, b};
                first_fail_expected = expected;
                first_fail_got = y;
            end
        end
    endtask

    initial begin
        passed = 0;
        total = 0;
        first_fail_valid = 1'b0;

        // Seed set HERE: $urandom(SEED) reseeds the RNG with SEED (32'hA11D_0001).
        seed_sink = $urandom(SEED);

        // Directed edge cases: all 2-input combinations.
        a = 0; b = 0; check(1'b0);
        a = 0; b = 1; check(1'b0);
        a = 1; b = 0; check(1'b0);
        a = 1; b = 1; check(1'b1);

        // Random vectors (reproducible because of SEED above).
        for (i = 0; i < NUM_RANDOM; i = i + 1) begin
            a = $urandom % 2;
            b = $urandom % 2;
            check(a & b);
        end

        if (first_fail_valid) begin
            $display(
                "RESULT {\"passed\":%0d,\"total\":%0d,\"first_fail\":{\"in\":\"a=%0d,b=%0d\",\"expected\":\"%0d\",\"got\":\"%0d\"}}",
                passed,
                total,
                first_fail_in[1],
                first_fail_in[0],
                first_fail_expected,
                first_fail_got
            );
        end else begin
            $display("RESULT {\"passed\":%0d,\"total\":%0d}", passed, total);
        end
        $finish;
    end
endmodule
