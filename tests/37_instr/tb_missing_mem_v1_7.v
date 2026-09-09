`timescale 1ns/1ps

module tb_missing_mem_v1_7;
    reg clk;
    reg rst;
    integer i;
    integer errors;

    pipeline_cpu_top uut(
        .clk(clk),
        .rst(rst)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task check_reg;
        input [4:0] index;
        input [31:0] expected;
        begin
            if (uut.u_reg_file.regs[index] !== expected) begin
                $display("FAIL reg x%0d: got %08h expected %08h",
                         index, uut.u_reg_file.regs[index], expected);
                errors = errors + 1;
            end
        end
    endtask

    task check_mem;
        input integer index;
        input [31:0] expected;
        reg [31:0] actual;
        begin
            actual = uut.u_data_mem.debug_word(index);
            if (actual !== expected) begin
                $display("FAIL mem[%0d]: got %08h expected %08h",
                         index, actual, expected);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors = 0;
        rst = 1'b1;

        #1;
        for (i = 0; i < 128; i = i + 1)
            uut.u_instr_mem.mem[i] = 32'h00000013;
        $readmemh("tests/37_instr/rv32i_missing_mem.hex",
                  uut.u_instr_mem.mem, 0, 7);

        #19;
        rst = 1'b0;

        #300;

        check_reg(5'd3, 32'h000000ff);
        check_reg(5'd4, 32'h00008001);
        check_mem(0, 32'h8001ff00);

        if (errors == 0)
            $display("PASS: lbu/lhu/sb/sh v1.7 test works.");
        else
            $display("FAIL: lbu/lhu/sb/sh v1.7 test has %0d errors.", errors);

        $finish;
    end
endmodule
