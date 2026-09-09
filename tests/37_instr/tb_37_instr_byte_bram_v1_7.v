`timescale 1ns/1ps

module tb_37_instr_byte_bram_v1_7;
    reg clk;
    reg rst;
    integer i;
    integer errors;
    reg [1023:0] hex_file;

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
        input [7:0] index;
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
        hex_file = "tests/37_instr/rv32i_37.hex";

        if ($value$plusargs("HEX=%s", hex_file))
            $display("Load hex: %0s", hex_file);
        else
            $display("Load hex: %0s", hex_file);

        #1;
        for (i = 0; i < 256; i = i + 1)
            uut.u_instr_mem.mem[i] = 32'h00000013;
        $readmemh(hex_file, uut.u_instr_mem.mem, 0, 98);

        #19;
        rst = 1'b0;

        #1500;

        check_reg(5'd1,  32'd16);
        check_reg(5'd2,  32'd9);
        check_reg(5'd3,  32'd9);
        check_reg(5'd4,  32'd18);
        check_reg(5'd5,  32'd3);
        check_reg(5'd6,  32'd1);
        check_reg(5'd7,  32'h00000178);
        check_reg(5'd8,  32'd0);
        check_reg(5'd9,  32'd1);
        check_reg(5'd10, 32'd5);
        check_reg(5'd11, 32'd8);
        check_reg(5'd12, 32'd13);
        check_reg(5'd13, 32'd21);
        check_reg(5'd14, 32'd9);
        check_reg(5'd15, 32'd14);
        check_reg(5'd16, 32'd9);
        check_reg(5'd17, 32'd9);
        check_reg(5'd18, 32'd1);
        check_reg(5'd19, 32'd27);
        check_reg(5'd20, 32'd9);
        check_reg(5'd21, 32'd18);
        check_reg(5'd22, 32'd17);
        check_reg(5'd23, 32'd18);
        check_reg(5'd24, 32'd9);
        check_reg(5'd25, 32'd36);
        check_reg(5'd26, 32'd9);
        check_reg(5'd27, 32'hfffffff0);
        check_reg(5'd28, 32'hfffffff8);
        check_reg(5'd29, 32'd0);
        check_reg(5'd30, 32'd1);
        check_reg(5'd31, 32'd0);

        check_mem(8'd4,  32'd9);
        check_mem(8'd5,  32'd1);
        check_mem(8'd6,  32'h12345000);
        check_mem(8'd7,  32'h000010c0);
        check_mem(8'd8,  32'h000080ff);
        check_mem(8'd9,  32'hffffffff);
        check_mem(8'd10, 32'hffff80ff);
        check_mem(8'd11, 32'h000080ff);
        check_mem(8'd12, 32'd0);
        check_mem(8'd13, 32'd2);
        check_mem(8'd14, 32'd2);
        check_mem(8'd15, 32'd0);
        check_mem(8'd16, 32'd0);
        check_mem(8'd20, 32'd3);
        check_mem(8'd21, 32'h00000178);

        if (errors == 0)
            $display("PASS: rv32i_37 byte-bram v1.7 test works.");
        else
            $display("FAIL: rv32i_37 byte-bram v1.7 test has %0d errors.", errors);

        $finish;
    end
endmodule
