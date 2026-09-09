`timescale 1ns/1ps

module tb_benchmark_param_v1_7;
    parameter PRED_INDEX_BITS = 4;
    parameter GHR_BITS = 4;
    parameter RAS_DEPTH = 4;

    reg clk;
    reg rst;
    integer i;
    integer errors;
    integer done;
    integer end_index;
    integer max_cycles;
    reg [1023:0] hex_file;
    reg [1023:0] bench_name;
    reg [31:0] expected;
    wire [31:0] cycle_count;
    wire [31:0] instret_count;
    wire [31:0] stall_count;
    wire [31:0] flush_count;
    wire [31:0] control_count;
    wire [31:0] predict_count;
    wire [31:0] btb_hit_count;
    wire [31:0] mispredict_count;
    wire [31:0] ras_hit_count;

    pipeline_cpu_top #(
        .PRED_INDEX_BITS(PRED_INDEX_BITS),
        .GHR_BITS(GHR_BITS),
        .RAS_DEPTH(RAS_DEPTH)
    ) uut (
        .clk(clk),
        .rst(rst),
        .cycle_count(cycle_count),
        .instret_count(instret_count),
        .stall_count(stall_count),
        .flush_count(flush_count),
        .control_count(control_count),
        .predict_count(predict_count),
        .btb_hit_count(btb_hit_count),
        .mispredict_count(mispredict_count),
        .ras_hit_count(ras_hit_count),
        .debug_x3(),
        .debug_x4(),
        .debug_x5(),
        .debug_x7()
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task check_reg;
        input [4:0] index;
        input [31:0] expected_value;
        begin
            if (uut.u_reg_file.regs[index] !== expected_value) begin
                $display("FAIL reg x%0d: got %08h expected %08h",
                         index, uut.u_reg_file.regs[index], expected_value);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors = 0;
        done = 0;
        rst = 1'b1;
        hex_file = "tests/benchmarks/branch_loop.hex";
        bench_name = "branch_loop";
        end_index = 4;
        max_cycles = 3000;

        if (!$value$plusargs("HEX=%s", hex_file))
            hex_file = "tests/benchmarks/branch_loop.hex";
        if (!$value$plusargs("BENCH=%s", bench_name))
            bench_name = "branch_loop";
        if (!$value$plusargs("END=%d", end_index))
            end_index = 4;
        if (!$value$plusargs("MAX_CYCLES=%d", max_cycles))
            max_cycles = 3000;

        $display("PARAM pred_index_bits=%0d ghr_bits=%0d ras_depth=%0d",
                 PRED_INDEX_BITS, GHR_BITS, RAS_DEPTH);
        $display("Load hex: %0s", hex_file);

        #1;
        for (i = 0; i < 256; i = i + 1)
            uut.u_instr_mem.mem[i] = 32'h00000013;
        $readmemh(hex_file, uut.u_instr_mem.mem, 0, end_index);

        #19;
        rst = 1'b0;

        begin : wait_done
            for (i = 0; i < max_cycles; i = i + 1) begin
                @(posedge clk);
                #1;
                if (uut.u_reg_file.regs[31] == 32'd123) begin
                    done = 1;
                    disable wait_done;
                end
            end
        end

        if (!done) begin
            $display("FAIL benchmark timeout: %0s", bench_name);
            errors = errors + 1;
        end

        check_reg(5'd31, 32'd123);

        if ($value$plusargs("EXP_X1=%d", expected))
            check_reg(5'd1, expected);
        if ($value$plusargs("EXP_X2=%d", expected))
            check_reg(5'd2, expected);
        if ($value$plusargs("EXP_X3=%d", expected))
            check_reg(5'd3, expected);
        if ($value$plusargs("EXP_X4=%d", expected))
            check_reg(5'd4, expected);
        if ($value$plusargs("EXP_X5=%d", expected))
            check_reg(5'd5, expected);
        if ($value$plusargs("EXP_X6=%d", expected))
            check_reg(5'd6, expected);
        if ($value$plusargs("EXP_X7=%d", expected))
            check_reg(5'd7, expected);
        if ($value$plusargs("EXP_X8=%d", expected))
            check_reg(5'd8, expected);
        if ($value$plusargs("EXP_X9=%d", expected))
            check_reg(5'd9, expected);
        if ($value$plusargs("EXP_X10=%d", expected))
            check_reg(5'd10, expected);
        if ($value$plusargs("EXP_X11=%d", expected))
            check_reg(5'd11, expected);
        if ($value$plusargs("EXP_X12=%d", expected))
            check_reg(5'd12, expected);
        if ($value$plusargs("EXP_X13=%d", expected))
            check_reg(5'd13, expected);
        if ($value$plusargs("EXP_X14=%d", expected))
            check_reg(5'd14, expected);
        if ($value$plusargs("EXP_X15=%d", expected))
            check_reg(5'd15, expected);

        $display("BENCH name=%0s cycle=%0d instret=%0d stall=%0d flush=%0d control=%0d predict=%0d btb_hit=%0d mispredict=%0d ras_hit=%0d",
                 bench_name, cycle_count, instret_count, stall_count, flush_count,
                 control_count, predict_count, btb_hit_count, mispredict_count, ras_hit_count);

        if (errors == 0)
            $display("PASS: v1.7 parameter benchmark works.");
        else
            $display("FAIL: v1.7 parameter benchmark has %0d errors.", errors);

        $finish;
    end
endmodule
