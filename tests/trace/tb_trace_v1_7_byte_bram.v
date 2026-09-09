`timescale 1ns/1ps

module tb_trace_v1_7_byte_bram;
    reg clk;
    reg rst;
    integer i;
    integer cycle;
    integer max_cycles;
    integer end_index;
    integer trace_fd;
    integer commit_count;
    integer done_reg;
    integer stop_after;
    reg [31:0] done_value;
    reg [1023:0] hex_file;
    reg [1023:0] trace_file;
    reg [1023:0] trace_name;

    reg        prev_wb_valid;
    reg [31:0] prev_wb_pc4;
    reg [4:0]  prev_wb_rd;
    reg        prev_wb_we;
    reg [31:0] prev_wb_data;
    reg [31:0] prev_wb_instr;

    pipeline_cpu_top uut(
        .clk(clk),
        .rst(rst)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst = 1'b1;
        commit_count = 0;
        max_cycles = 3000;
        end_index = 98;
        done_reg = 31;
        stop_after = 0;
        done_value = 32'd123;
        hex_file = "tests/37_instr/rv32i_37.hex";
        trace_file = "results/traces/v1_7/default.trace";
        trace_name = "trace";

        prev_wb_valid = 1'b0;
        prev_wb_pc4 = 32'b0;
        prev_wb_rd = 5'b0;
        prev_wb_we = 1'b0;
        prev_wb_data = 32'b0;
        prev_wb_instr = 32'b0;

        if (!$value$plusargs("HEX=%s", hex_file))
            hex_file = "tests/37_instr/rv32i_37.hex";
        if (!$value$plusargs("TRACE=%s", trace_file))
            trace_file = "results/traces/v1_7/default.trace";
        if (!$value$plusargs("NAME=%s", trace_name))
            trace_name = "trace";
        if (!$value$plusargs("END=%d", end_index))
            end_index = 98;
        if (!$value$plusargs("MAX_CYCLES=%d", max_cycles))
            max_cycles = 3000;
        if (!$value$plusargs("DONE_REG=%d", done_reg))
            done_reg = 31;
        if (!$value$plusargs("DONE_VALUE=%d", done_value))
            done_value = 32'd123;
        if (!$value$plusargs("STOP_AFTER=%d", stop_after))
            stop_after = 0;

        $display("Load hex: %0s", hex_file);
        trace_fd = $fopen(trace_file, "w");
        if (trace_fd == 0) begin
            $display("FAIL trace: cannot open %0s", trace_file);
            $finish;
        end

        $fdisplay(trace_fd, "# commit pc instr rd we wb_data");

        #1;
        for (i = 0; i < 128; i = i + 1)
            uut.u_instr_mem.mem[i] = 32'h00000013;
        $readmemh(hex_file, uut.u_instr_mem.mem, 0, end_index);

        #19;
        rst = 1'b0;

        begin : run_program
            for (cycle = 0; cycle < max_cycles; cycle = cycle + 1) begin
                @(posedge clk);
                #1;

                if (prev_wb_valid) begin
                    $fdisplay(trace_fd, "%0d %08h %08h %0d %0d %08h",
                              commit_count,
                              prev_wb_pc4 - 32'd4,
                              prev_wb_instr,
                              prev_wb_rd,
                              prev_wb_we,
                              prev_wb_data);
                    commit_count = commit_count + 1;
                    if (stop_after > 0 && commit_count >= stop_after)
                        disable run_program;
                end

                prev_wb_valid = uut.mem2_wb_valid;
                prev_wb_pc4 = uut.mem2_wb_pc4;
                prev_wb_rd = uut.mem2_wb_rd;
                prev_wb_we = uut.mem2_wb_we;
                prev_wb_data = uut.wb_data;

                if ((uut.mem2_wb_pc4 - 32'd4) < 32'd1024)
                    prev_wb_instr = uut.u_instr_mem.mem[(uut.mem2_wb_pc4 - 32'd4) >> 2];
                else
                    prev_wb_instr = 32'b0;

                if (uut.u_reg_file.regs[done_reg] == done_value)
                    disable run_program;
            end
        end

        for (i = 0; i < 64; i = i + 1)
            $fdisplay(trace_fd, "MEM %0d %08h", i, uut.u_data_mem.debug_word(i));
        $fclose(trace_fd);

        if (commit_count == 0)
            $display("FAIL trace: no commits generated.");
        else begin
            $display("TRACE name=%0s commits=%0d file=%0s",
                     trace_name, commit_count, trace_file);
            $display("PASS: trace generated.");
        end

        $finish;
    end
endmodule
