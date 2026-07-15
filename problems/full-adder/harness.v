// Self-checking testbench for full_adder.
// Compiles against either starter.v or reference.v (same module name/ports).
module tb_full_adder;
    // RNG seed: hardcoded (not time-based). Applied once below via $urandom(SEED).
    localparam [31:0] SEED = 32'hFADD_E201;
    localparam integer NUM_RANDOM = 96;

    reg a;
    reg b;
    reg cin;
    wire sum;
    wire cout;

    integer passed;
    integer total;
    integer i;
    integer seed_sink;

    reg         first_fail_valid;
    reg [2:0]   first_fail_in;
    reg [1:0]   first_fail_expected;
    reg [1:0]   first_fail_got;

    reg         expected_sum;
    reg         expected_cout;

    full_adder dut (
        .a(a),
        .b(b),
        .cin(cin),
        .sum(sum),
        .cout(cout)
    );

    task automatic check;
        input exp_sum;
        input exp_cout;
        begin
            total = total + 1;
            #1;
            if ((sum === exp_sum) && (cout === exp_cout)) begin
                passed = passed + 1;
            end else if (!first_fail_valid) begin
                first_fail_valid = 1'b1;
                first_fail_in = {a, b, cin};
                first_fail_expected = {exp_cout, exp_sum};
                first_fail_got = {cout, sum};
            end
        end
    endtask

    task automatic apply_and_check;
        input ta;
        input tb;
        input tcin;
        begin
            a = ta;
            b = tb;
            cin = tcin;
            expected_sum  = ta ^ tb ^ tcin;
            expected_cout = (ta & tb) | (ta & tcin) | (tb & tcin);
            check(expected_sum, expected_cout);
        end
    endtask

    initial begin
        passed = 0;
        total = 0;
        first_fail_valid = 1'b0;

        // Seed set HERE: $urandom(SEED) reseeds the RNG with SEED (32'hFADD_E201).
        seed_sink = $urandom(SEED);

        // Directed edge cases: all 8 input combinations.
        apply_and_check(0, 0, 0);
        apply_and_check(0, 0, 1);
        apply_and_check(0, 1, 0);
        apply_and_check(0, 1, 1);
        apply_and_check(1, 0, 0);
        apply_and_check(1, 0, 1);
        apply_and_check(1, 1, 0);
        apply_and_check(1, 1, 1);

        // Random vectors (reproducible because of SEED above).
        for (i = 0; i < NUM_RANDOM; i = i + 1) begin
            apply_and_check($urandom % 2, $urandom % 2, $urandom % 2);
        end

        if (first_fail_valid) begin
            $display(
                "RESULT {\"passed\":%0d,\"total\":%0d,\"first_fail\":{\"in\":\"a=%0d,b=%0d,cin=%0d\",\"expected\":\"sum=%0d,cout=%0d\",\"got\":\"sum=%0d,cout=%0d\"}}",
                passed,
                total,
                first_fail_in[2],
                first_fail_in[1],
                first_fail_in[0],
                first_fail_expected[0],
                first_fail_expected[1],
                first_fail_got[0],
                first_fail_got[1]
            );
        end else begin
            $display("RESULT {\"passed\":%0d,\"total\":%0d}", passed, total);
        end
        $finish;
    end
endmodule
