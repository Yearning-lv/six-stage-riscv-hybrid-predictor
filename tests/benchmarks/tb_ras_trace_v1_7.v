`timescale 1ns/1ps

module tb_ras_trace_v1_7;
    reg clk;
    reg rst;
    integer i;
    reg [1023:0] hex_file;

    pipeline_cpu_top #(
        .PRED_INDEX_BITS(5),
        .GHR_BITS(5),
        .RAS_DEPTH(4)
    ) uut (
        .clk(clk),
        .rst(rst),
        .cycle_count(),
        .instret_count(),
        .stall_count(),
        .flush_count(),
        .control_count(),
        .predict_count(),
        .btb_hit_count(),
        .mispredict_count(),
        .ras_hit_count(),
        .debug_x3(),
        .debug_x4(),
        .debug_x5(),
        .debug_x7()
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst = 1'b1;
        hex_file = "tests/benchmarks/call_return.hex";

        if ($value$plusargs("HEX=%s", hex_file))
            $display("Load hex: %0s", hex_file);
        else
            $display("Load hex: %0s", hex_file);

        #1;
        for (i = 0; i < 256; i = i + 1)
            uut.u_instr_mem.mem[i] = 32'h00000013;
        $readmemh(hex_file, uut.u_instr_mem.mem, 0, 127);

        #19;
        rst = 1'b0;

        for (i = 0; i < 120; i = i + 1) begin
            @(posedge clk);
            #1;
            if (uut.pc_f == 32'h0000001c ||
                uut.btb_is_return_f ||
                uut.ras_predict_valid_f ||
                uut.ras_pred_taken_f ||
                uut.ras_push_en ||
                uut.ras_pop_en) begin
                $display("TRACE cycle=%0d pc=%08h btb_hit=%0b is_ret=%0b ras_valid=%0b ras_taken=%0b ras_target=%08h push=%0b pop=%0b pred_taken=%0b pred_target=%08h mis=%0b",
                         i, uut.pc_f, uut.btb_hit_f, uut.btb_is_return_f,
                         uut.ras_predict_valid_f, uut.ras_pred_taken_f,
                         uut.ras_predict_target_f, uut.ras_push_en,
                         uut.ras_pop_en, uut.pred_taken_f,
                         uut.pred_target_f, uut.ex_mispredict);
            end
        end

        $display("FINAL ras_hit=%0d predict=%0d btb_hit=%0d mispredict=%0d",
                 uut.ras_hit_count, uut.predict_count, uut.btb_hit_count,
                 uut.mispredict_count);
        $finish;
    end
endmodule
