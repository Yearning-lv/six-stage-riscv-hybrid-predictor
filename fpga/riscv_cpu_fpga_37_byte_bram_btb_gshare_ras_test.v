`timescale 1ns/1ps

// 6-stage BTB+Gshare+RAS predictor
// IF / ID / EX / MEM1 / MEM2 / WB
// RV32I subset: add/sub/and/or/xor/sll/srl/sra/slt/sltu/addi/slti/sltiu/andi/ori/xori/slli/srli/srai/lui/auipc/lb/lh/lw/lbu/lhu/sb/sh/sw/beq/bne/blt/bge/bltu/bgeu/jal/jalr

module pc(
    input clk,
    input rst,
    input [31:0] pc_in,
    output reg [31:0] pc_out
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_out <= 32'b0;
        end else begin
            pc_out <= pc_in;
        end
    end
endmodule

module instr_mem(
    input clk,
    input [31:0] addr,
    output reg [31:0] instr
);
    (* rom_style = "block" *) reg [31:0] mem [0:127];
    integer i;

    initial begin
        for (i = 0; i < 128; i = i + 1)
            mem[i] = 32'b0;

        // addi x1, x0, 16
        mem[0] = 32'h01000093;
        // addi x2, x0, 9
        mem[1] = 32'h00900113;
        // nop
        mem[2] = 32'h00000013;
        // nop
        mem[3] = 32'h00000013;
        // nop
        mem[4] = 32'h00000013;
        // sw x2, 0(x1)
        mem[5] = 32'h0020a023;
        // lw x3, 0(x1)
        mem[6] = 32'h0000a183;
        // nop
        mem[7] = 32'h00000013;
        // nop
        mem[8] = 32'h00000013;
        // nop
        mem[9] = 32'h00000013;
        // add x4, x3, x2
        mem[10] = 32'h00218233;
        // nop
        mem[11] = 32'h00000013;
        // nop
        mem[12] = 32'h00000013;
        // nop
        mem[13] = 32'h00000013;
        // beq x4, x4, 8
        mem[14] = 32'h00420463;
        // addi x5, x0, 99
        mem[15] = 32'h06300293;
        // addi x6, x0, 1
        mem[16] = 32'h00100313;
        // jal x7, 8
        mem[17] = 32'h008003ef;
        // addi x8, x0, 99
        mem[18] = 32'h06300413;
        // addi x9, x0, 1
        mem[19] = 32'h00100493;
        // addi x10, x0, 5
        mem[20] = 32'h00500513;
        // addi x11, x10, 3
        mem[21] = 32'h00350593;
        // add x12, x11, x10
        mem[22] = 32'h00a58633;
        // add x13, x12, x11
        mem[23] = 32'h00b606b3;
        // lw x14, 0(x1)
        mem[24] = 32'h0000a703;
        // add x15, x14, x10
        mem[25] = 32'h00a707b3;
        // sub x16, x4, x2
        mem[26] = 32'h40220833;
        // and x17, x3, x2
        mem[27] = 32'h0021f8b3;
        // andi x18, x17, 3
        mem[28] = 32'h0038f913;
        // or x19, x4, x2
        mem[29] = 32'h002269b3;
        // ori x20, x18, 8
        mem[30] = 32'h00896a13;
        // xor x21, x19, x20
        mem[31] = 32'h0149cab3;
        // xori x22, x21, 3
        mem[32] = 32'h003acb13;
        // sll x23, x2, x6
        mem[33] = 32'h00611bb3;
        // srl x24, x4, x6
        mem[34] = 32'h00625c33;
        // slli x25, x2, 2
        mem[35] = 32'h00211c93;
        // srli x26, x4, 1
        mem[36] = 32'h00125d13;
        // addi x27, x0, -16
        mem[37] = 32'hff000d93;
        // sra x28, x27, x6
        mem[38] = 32'h406dde33;
        // srai x29, x27, 2
        mem[39] = 32'h402dde93;
        // slt x30, x27, x2
        mem[40] = 32'h002daf33;
        // slti x31, x27, -1
        mem[41] = 32'hfffdaf93;
        // nop
        mem[42] = 32'h00000013;
        // nop
        mem[43] = 32'h00000013;
        // nop
        mem[44] = 32'h00000013;
        // sw x31, 4(x1)
        mem[45] = 32'h01f0a223;
        // sltu x31, x27, x2
        mem[46] = 32'h002dbfb3;
        // lui x5, 0x12345
        mem[47] = 32'h123452b7;
        // auipc x6, 0x1
        mem[48] = 32'h00001317;
        // sw x5, 8(x1)
        mem[49] = 32'h0050a423;
        // sw x6, 12(x1)
        mem[50] = 32'h0060a623;
        // addi x5, x0, 0
        mem[51] = 32'h00000293;
        // addi x6, x0, 1
        mem[52] = 32'h00100313;
        // lui x5, 0x8
        mem[53] = 32'h000082b7;
        // ori x5, x5, 0xff
        mem[54] = 32'h0ff2e293;
        // sw x5, 16(x1)
        mem[55] = 32'h0050a823;
        // lb x6, 16(x1)
        mem[56] = 32'h01008303;
        // sw x6, 20(x1)
        mem[57] = 32'h0060aa23;
        // lh x7, 16(x1)
        mem[58] = 32'h01009383;
        // sw x7, 24(x1)
        mem[59] = 32'h0070ac23;
        // lw x8, 16(x1)
        mem[60] = 32'h0100a403;
        // sw x8, 28(x1)
        mem[61] = 32'h0080ae23;
        // restore x5, x6, x7, x8
        mem[62] = 32'h00000293;
        mem[63] = 32'h00100313;
        mem[64] = 32'h04800393;
        mem[65] = 32'h00000413;
        // sltiu x29, x27, 1
        mem[66] = 32'h001dbe93;
        // bne x1, x2, 8
        mem[67] = 32'h00209463;
        // addi x5, x0, 1
        mem[68] = 32'h00100293;
        // nop
        mem[69] = 32'h00000013;
        // sw x5, 32(x1)
        mem[70] = 32'h0250a023;
        // addi x5, x0, 1
        mem[71] = 32'h00100293;
        // blt x1, x2, 8
        mem[72] = 32'h0020c463;
        // addi x5, x0, 2
        mem[73] = 32'h00200293;
        // nop
        mem[74] = 32'h00000013;
        // sw x5, 36(x1)
        mem[75] = 32'h0250a223;
        // addi x5, x0, 1
        mem[76] = 32'h00100293;
        // bltu x27, x2, 8
        mem[77] = 32'h002de463;
        // addi x5, x0, 2
        mem[78] = 32'h00200293;
        // nop
        mem[79] = 32'h00000013;
        // sw x5, 40(x1)
        mem[80] = 32'h0250a423;
        // addi x5, x0, 0
        mem[81] = 32'h00000293;
        // bge x1, x2, 8
        mem[82] = 32'h0020d463;
        // addi x5, x0, 1
        mem[83] = 32'h00100293;
        // nop
        mem[84] = 32'h00000013;
        // sw x5, 44(x1)
        mem[85] = 32'h0250a623;
        // addi x5, x0, 0
        mem[86] = 32'h00000293;
        // bgeu x27, x2, 8
        mem[87] = 32'h002df463;
        // addi x5, x0, 1
        mem[88] = 32'h00100293;
        // nop
        mem[89] = 32'h00000013;
        // sw x5, 48(x1)
        mem[90] = 32'h0250a823;
        // addi x1, x0, 372
        mem[91] = 32'h17400093;
        // nop
        mem[92] = 32'h00000013;
        // jalr x7, 8(x1)
        mem[93] = 32'h008083e7;
        // addi x5, x0, 99
        mem[94] = 32'h06300293;
        // addi x5, x0, 3
        mem[95] = 32'h00300293;
        // sw x5, 80(x0)
        mem[96] = 32'h04502823;
        // sw x7, 84(x0)
        mem[97] = 32'h04702a23;
        // addi x1, x0, 16
        mem[98] = 32'h01000093;
    end

    always @(posedge clk) begin
        instr <= mem[addr[8:2]];
    end
endmodule

module reg_file(
    input clk,
    input rst,
    input we,
    input [4:0] raddr1,
    input [4:0] raddr2,
    input [4:0] waddr,
    input [31:0] wdata,
    output [31:0] rdata1,
    output [31:0] rdata2
    ,output [31:0] debug_x3
    ,output [31:0] debug_x4
    ,output [31:0] debug_x5
    ,output [31:0] debug_x7
);
    reg [31:0] regs [0:31];
    integer i;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1)
                regs[i] <= 32'b0;
        end else if (we && (waddr != 5'b0)) begin
            regs[waddr] <= wdata;
        end
    end

    // WB bypass
    assign rdata1 = (raddr1 == 5'b0) ? 32'b0 :
                    (we && (waddr != 5'b0) && (waddr == raddr1)) ?
                    wdata : regs[raddr1];
    assign rdata2 = (raddr2 == 5'b0) ? 32'b0 :
                    (we && (waddr != 5'b0) && (waddr == raddr2)) ?
                    wdata : regs[raddr2];
    assign debug_x3 = regs[3];
    assign debug_x4 = regs[4];
    assign debug_x5 = regs[5];
    assign debug_x7 = regs[7];
endmodule

module imm_gen(
    input [31:0] instr,
    output reg [31:0] imm
);
    always @(*) begin
        case (instr[6:0])
            7'b0000011: imm = {{20{instr[31]}}, instr[31:20]}; // lb, lh, lw, lbu, lhu
            7'b0010011: imm = {{20{instr[31]}}, instr[31:20]}; // I-type ALU
            7'b1100111: imm = {{20{instr[31]}}, instr[31:20]}; // jalr
            7'b0010111: imm = {instr[31:12], 12'b0}; // auipc
            7'b0100011: imm = {{20{instr[31]}}, instr[31:25], instr[11:7]}; // sb, sh, sw
            7'b0110111: imm = {instr[31:12], 12'b0}; // lui
            7'b1100011: imm = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0}; // branches
            7'b1101111: imm = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0}; // jal, J-type
            default:    imm = 32'b0;
        endcase
    end
endmodule

module data_mem(
    input clk,
    input rst,
    input we,
    input [2:0] store_type,
    input [31:0] addr,
    input [31:0] wdata,
    output reg [31:0] rdata
);
    (* ram_style = "block" *) reg [7:0] mem0 [0:63];
    (* ram_style = "block" *) reg [7:0] mem1 [0:63];
    (* ram_style = "block" *) reg [7:0] mem2 [0:63];
    (* ram_style = "block" *) reg [7:0] mem3 [0:63];
    integer i;

    initial begin
        for (i = 0; i < 64; i = i + 1) begin
            mem0[i] = 8'b0;
            mem1[i] = 8'b0;
            mem2[i] = 8'b0;
            mem3[i] = 8'b0;
        end
        rdata = 32'b0;
    end

`ifdef SIMULATION
    function [31:0] debug_word;
        input integer index;
        begin
            debug_word = {mem3[index], mem2[index], mem1[index], mem0[index]};
        end
    endfunction
`endif

    always @(posedge clk) begin
        if (rst) begin
            rdata <= 32'b0;
        end else begin
            rdata <= {mem3[addr[7:2]], mem2[addr[7:2]], mem1[addr[7:2]], mem0[addr[7:2]]};

            if (we) begin
                case (store_type)
                    3'b001: begin // sb
                        case (addr[1:0])
                            2'b00: mem0[addr[7:2]] <= wdata[7:0];
                            2'b01: mem1[addr[7:2]] <= wdata[7:0];
                            2'b10: mem2[addr[7:2]] <= wdata[7:0];
                            2'b11: mem3[addr[7:2]] <= wdata[7:0];
                        endcase
                    end
                    3'b010: begin // sh
                        case (addr[1:0])
                            2'b00: begin
                                mem0[addr[7:2]] <= wdata[7:0];
                                mem1[addr[7:2]] <= wdata[15:8];
                            end
                            2'b10: begin
                                mem2[addr[7:2]] <= wdata[7:0];
                                mem3[addr[7:2]] <= wdata[15:8];
                            end
                        endcase
                    end
                    3'b011: begin // sw
                        mem0[addr[7:2]] <= wdata[7:0];
                        mem1[addr[7:2]] <= wdata[15:8];
                        mem2[addr[7:2]] <= wdata[23:16];
                        mem3[addr[7:2]] <= wdata[31:24];
                    end
                endcase
            end
        end
    end
endmodule

module alu(
    input [31:0] a,
    input [31:0] b,
    input [3:0] alu_ctrl,
    output reg [31:0] result,
    output zero
);
    always @(*) begin
        case (alu_ctrl)
            4'b0000: result = a + b; // add
            4'b0001: result = a - b; // sub
            4'b0010: result = a & b; // and
            4'b0011: result = a | b; // or
            4'b0100: result = a ^ b; // xor
            4'b0101: result = a << b[4:0]; // sll
            4'b0110: result = a >> b[4:0]; // srl
            4'b0111: result = $signed(a) >>> b[4:0]; // sra
            4'b1000: result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0; // slt
            4'b1001: result = (a < b) ? 32'd1 : 32'd0; // sltu
            4'b1010: result = b; // lui
            default: result = 32'b0;
        endcase
    end

    assign zero = (result == 32'b0);
endmodule

module pipeline_control(
    input [6:0] opcode,
    input [2:0] funct3,
    input [6:0] funct7,
    output reg we,
    output reg [3:0] alu_ctrl,
    output reg alu_src,
    output reg mem_we,
    output reg mem_to_reg,
    output reg branch,
    output reg branch_ne,
    output reg branch_lt,
    output reg branch_ge,
    output reg branch_ltu,
    output reg branch_geu,
    output reg jal,
    output reg jalr,
    output reg uses_rs1,
    output reg uses_rs2,
    output reg auipc,
    output reg [2:0] load_type,
    output reg [2:0] store_type
);
    always @(*) begin
        we         = 1'b0;
        alu_ctrl   = 4'b0000;
        alu_src    = 1'b0;
        mem_we     = 1'b0;
        mem_to_reg = 1'b0;
        branch     = 1'b0;
        branch_ne  = 1'b0;
        branch_lt  = 1'b0;
        branch_ge  = 1'b0;
        branch_ltu = 1'b0;
        branch_geu = 1'b0;
        jal        = 1'b0;
        jalr       = 1'b0;
        uses_rs1   = 1'b0;
        uses_rs2   = 1'b0;
        auipc      = 1'b0;
        load_type  = 3'b000;
        store_type = 3'b000;

        case (opcode)
            7'b0000011: begin // load
                we         = 1'b1;
                alu_ctrl   = 4'b0000;
                alu_src    = 1'b1;
                mem_we     = 1'b0;
                mem_to_reg = 1'b1;
                branch     = 1'b0;
                uses_rs1   = 1'b1;
                uses_rs2   = 1'b0;
                case (funct3)
                    3'b000: load_type = 3'b001; // lb
                    3'b001: load_type = 3'b010; // lh
                    3'b010: load_type = 3'b011; // lw
                    3'b100: load_type = 3'b100; // lbu
                    3'b101: load_type = 3'b101; // lhu
                    default: begin
                        we         = 1'b0;
                        mem_to_reg = 1'b0;
                        uses_rs1   = 1'b0;
                    end
                endcase
            end
            7'b0010011: begin // I-type ALU
                we         = 1'b1;
                alu_src    = 1'b1;
                uses_rs1   = 1'b1;
                uses_rs2   = 1'b0;
                case (funct3)
                    3'b000: alu_ctrl = 4'b0000; // addi
                    3'b111: alu_ctrl = 4'b0010; // andi
                    3'b110: alu_ctrl = 4'b0011; // ori
                    3'b100: alu_ctrl = 4'b0100; // xori
                    3'b001: begin
                        if (funct7 == 7'b0000000)
                            alu_ctrl = 4'b0101; // slli
                        else
                            we = 1'b0;
                    end
                    3'b101: begin
                        if (funct7 == 7'b0000000)
                            alu_ctrl = 4'b0110; // srli
                        else if (funct7 == 7'b0100000)
                            alu_ctrl = 4'b0111; // srai
                        else
                            we = 1'b0;
                    end
                    3'b010: alu_ctrl = 4'b1000; // slti
                    3'b011: alu_ctrl = 4'b1001; // sltiu
                    default: begin
                        we       = 1'b0;
                        alu_src  = 1'b0;
                        uses_rs1 = 1'b0;
                    end
                endcase
            end
            7'b0010111: begin // auipc
                we       = 1'b1;
                alu_ctrl = 4'b0000;
                alu_src  = 1'b1;
                auipc    = 1'b1;
            end
            7'b0100011: begin // store
                we         = 1'b0;
                alu_ctrl   = 4'b0000;
                alu_src    = 1'b1;
                mem_we     = 1'b1;
                mem_to_reg = 1'b0;
                branch     = 1'b0;
                uses_rs1   = 1'b1;
                uses_rs2   = 1'b1;
                case (funct3)
                    3'b000: store_type = 3'b001; // sb
                    3'b001: store_type = 3'b010; // sh
                    3'b010: store_type = 3'b011; // sw
                    default: begin
                        mem_we   = 1'b0;
                        alu_src  = 1'b0;
                        uses_rs1 = 1'b0;
                        uses_rs2 = 1'b0;
                    end
                endcase
            end
            7'b0110011: begin // R-type ALU
                we         = 1'b1;
                alu_src    = 1'b0;
                uses_rs1   = 1'b1;
                uses_rs2   = 1'b1;
                case ({funct7, funct3})
                    {7'b0000000, 3'b000}: alu_ctrl = 4'b0000; // add
                    {7'b0100000, 3'b000}: alu_ctrl = 4'b0001; // sub
                    {7'b0000000, 3'b111}: alu_ctrl = 4'b0010; // and
                    {7'b0000000, 3'b110}: alu_ctrl = 4'b0011; // or
                    {7'b0000000, 3'b100}: alu_ctrl = 4'b0100; // xor
                    {7'b0000000, 3'b001}: alu_ctrl = 4'b0101; // sll
                    {7'b0000000, 3'b101}: alu_ctrl = 4'b0110; // srl
                    {7'b0100000, 3'b101}: alu_ctrl = 4'b0111; // sra
                    {7'b0000000, 3'b010}: alu_ctrl = 4'b1000; // slt
                    {7'b0000000, 3'b011}: alu_ctrl = 4'b1001; // sltu
                    default: begin
                        we       = 1'b0;
                        uses_rs1 = 1'b0;
                        uses_rs2 = 1'b0;
                    end
                endcase
            end
            7'b0110111: begin // lui
                we       = 1'b1;
                alu_ctrl = 4'b1010;
                alu_src  = 1'b1;
            end
            7'b1100011: begin // branch
                we         = 1'b0;
                alu_ctrl   = 4'b0001;
                alu_src    = 1'b0;
                mem_we     = 1'b0;
                mem_to_reg = 1'b0;
                branch     = 1'b1;
                uses_rs1   = 1'b1;
                uses_rs2   = 1'b1;
                case (funct3)
                    3'b000: branch_ne  = 1'b0; // beq
                    3'b001: branch_ne  = 1'b1; // bne
                    3'b100: branch_lt  = 1'b1; // blt
                    3'b101: branch_ge  = 1'b1; // bge
                    3'b110: branch_ltu = 1'b1; // bltu
                    3'b111: branch_geu = 1'b1; // bgeu
                    default: begin
                        branch   = 1'b0;
                        uses_rs1 = 1'b0;
                        uses_rs2 = 1'b0;
                    end
                endcase
            end
            7'b1101111: begin // jal
                we         = 1'b1;
                alu_ctrl   = 4'b0000;
                alu_src    = 1'b0;
                mem_we     = 1'b0;
                mem_to_reg = 1'b0;
                branch     = 1'b0;
                jal        = 1'b1;
                uses_rs1   = 1'b0;
                uses_rs2   = 1'b0;
            end
            7'b1100111: begin // jalr
                if (funct3 == 3'b000) begin
                    we         = 1'b1;
                    alu_ctrl   = 4'b0000;
                    alu_src    = 1'b1;
                    mem_we     = 1'b0;
                    mem_to_reg = 1'b0;
                    branch     = 1'b0;
                    jalr       = 1'b1;
                    uses_rs1   = 1'b1;
                    uses_rs2   = 1'b0;
                end
            end
            default: begin
                we         = 1'b0;
                alu_ctrl   = 4'b0000;
                alu_src    = 1'b0;
                mem_we     = 1'b0;
                mem_to_reg = 1'b0;
                branch     = 1'b0;
                jal        = 1'b0;
                jalr       = 1'b0;
                uses_rs1   = 1'b0;
                uses_rs2   = 1'b0;
            end
        endcase
    end
endmodule

// forwarding
// 00: regfile
// 10: EX/MEM1
// 11: MEM1/MEM2
// 01: MEM2/WB
module forward_unit(
    input [4:0] id_ex_rs1,
    input [4:0] id_ex_rs2,
    input [4:0] ex_mem1_rd,
    input       ex_mem1_we,
    input       ex_mem1_mem_to_reg,
    input [4:0] mem1_mem2_rd,
    input       mem1_mem2_we,
    input       mem1_mem2_mem_to_reg,
    input       mem1_mem2_jal,
    input [4:0] mem2_wb_rd,
    input       mem2_wb_we,
    output reg [1:0] forward_a,
    output reg [1:0] forward_b
);
    always @(*) begin
        forward_a = 2'b00;
        forward_b = 2'b00;

        // load data not ready
        if (ex_mem1_we && !ex_mem1_mem_to_reg &&
            (ex_mem1_rd != 5'b0) && (ex_mem1_rd == id_ex_rs1)) begin
            forward_a = 2'b10;
        end else if (mem1_mem2_we &&
                     (mem1_mem2_rd != 5'b0) && (mem1_mem2_rd == id_ex_rs1)) begin
            forward_a = 2'b11;
        end else if (mem2_wb_we &&
                     (mem2_wb_rd != 5'b0) && (mem2_wb_rd == id_ex_rs1)) begin
            forward_a = 2'b01;
        end

        if (ex_mem1_we && !ex_mem1_mem_to_reg &&
            (ex_mem1_rd != 5'b0) && (ex_mem1_rd == id_ex_rs2)) begin
            forward_b = 2'b10;
        end else if (mem1_mem2_we &&
                     (mem1_mem2_rd != 5'b0) && (mem1_mem2_rd == id_ex_rs2)) begin
            forward_b = 2'b11;
        end else if (mem2_wb_we &&
                     (mem2_wb_rd != 5'b0) && (mem2_wb_rd == id_ex_rs2)) begin
            forward_b = 2'b01;
        end
    end
endmodule

// load-use stall
module hazard_unit(
    input       id_ex_mem_to_reg,
    input [4:0] id_ex_rd,
    input       ex_mem1_mem_to_reg,
    input [4:0] ex_mem1_rd,
    input [4:0] id_rs1,
    input [4:0] id_rs2,
    input       id_uses_rs1,
    input       id_uses_rs2,
    output      stall
);
    assign stall =
        (id_ex_mem_to_reg &&
         (id_ex_rd != 5'b0) &&
         ((id_uses_rs1 && (id_ex_rd == id_rs1)) ||
          (id_uses_rs2 && (id_ex_rd == id_rs2)))) ||
        (ex_mem1_mem_to_reg &&
         (ex_mem1_rd != 5'b0) &&
         ((id_uses_rs1 && (ex_mem1_rd == id_rs1)) ||
          (id_uses_rs2 && (ex_mem1_rd == id_rs2))));
endmodule

module btb(
    input        clk,
    input        rst,
    input [31:0] query_pc,
    output       hit,
    output [31:0] target,
    output       is_return,
    input        update_en,
    input [31:0] update_pc,
    input [31:0] update_target,
    input        update_is_return
);
    localparam ENTRY_COUNT = 16;
    reg        valid  [0:ENTRY_COUNT-1];
    reg [25:0] tags   [0:ENTRY_COUNT-1];
    reg [31:0] targets[0:ENTRY_COUNT-1];
    reg        returns[0:ENTRY_COUNT-1];
    integer i;

    wire [3:0]  query_index = query_pc[5:2];
    wire [25:0] query_tag   = query_pc[31:6];

    assign hit    = valid[query_index] && (tags[query_index] == query_tag);
    assign target = targets[query_index];
    assign is_return = hit && returns[query_index];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < ENTRY_COUNT; i = i + 1) begin
                valid[i]   <= 1'b0;
                tags[i]    <= 26'b0;
                targets[i] <= 32'b0;
                returns[i] <= 1'b0;
            end
        end else if (update_en) begin
            valid[update_pc[5:2]]   <= 1'b1;
            tags[update_pc[5:2]]    <= update_pc[31:6];
            targets[update_pc[5:2]] <= update_target;
            returns[update_pc[5:2]] <= update_is_return;
        end
    end
endmodule

module gshare_predictor(
    input        clk,
    input        rst,
    input [31:0] query_pc,
    output       predict_taken,
    output [3:0] ghr_value,
    output [3:0] query_index,
    input        update_en,
    input [3:0]  update_index,
    input        update_taken
);
    localparam ENTRY_COUNT = 16;
    reg [1:0] counters[0:ENTRY_COUNT-1];
    reg [3:0] ghr;
    integer i;

    assign ghr_value = ghr;
    assign query_index = query_pc[5:2] ^ ghr;

    assign predict_taken = counters[query_index][1];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ghr <= 4'b0000;
            for (i = 0; i < ENTRY_COUNT; i = i + 1)
                counters[i] <= 2'b01;
        end else if (update_en) begin
            if (update_taken) begin
                if (counters[update_index] != 2'b11)
                    counters[update_index] <= counters[update_index] + 2'b01;
            end else begin
                if (counters[update_index] != 2'b00)
                    counters[update_index] <= counters[update_index] - 2'b01;
            end
            ghr <= {ghr[2:0], update_taken};
        end
    end
endmodule

module ras(
    input        clk,
    input        rst,
    output       predict_valid,
    output [31:0] predict_target,
    input        push_en,
    input [31:0] push_data,
    input        pop_en
);
    localparam DEPTH = 4;
    reg [31:0] stack [0:DEPTH-1];
    reg [2:0]  sp;
    integer i;

    assign predict_valid = (sp != 0);
    assign predict_target = predict_valid ? stack[sp - 1'b1] : 32'b0;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sp <= 3'b0;
            for (i = 0; i < DEPTH; i = i + 1)
                stack[i] <= 32'b0;
        end else begin
            if (push_en && (sp < DEPTH)) begin
                stack[sp[1:0]] <= push_data;
                sp <= sp + 1'b1;
            end else if (pop_en && (sp != 0)) begin
                sp <= sp - 1'b1;
            end
        end
    end
endmodule

module pipeline_cpu_top(
    input clk,
    input rst,
    output reg [31:0] cycle_count,
    output reg [31:0] instret_count,
    output reg [31:0] stall_count,
    output reg [31:0] flush_count,
    output reg [31:0] control_count,
    output reg [31:0] predict_count,
    output reg [31:0] btb_hit_count,
    output reg [31:0] mispredict_count,
    output reg [31:0] ras_hit_count,
    output [31:0] debug_x3,
    output [31:0] debug_x4,
    output [31:0] debug_x5,
    output [31:0] debug_x7
);
    // IF
    wire [31:0] pc_f;
    wire [31:0] pc_next_f;
    wire [31:0] pc4_f;
    wire [31:0] instr_f;
    wire        btb_hit_f;
    wire [31:0] btb_target_f;
    wire        btb_is_return_f;
    wire        gshare_predict_taken_f;
    wire [3:0]  gshare_ghr_f;
    wire [3:0]  gshare_index_f;
    wire        dir_pred_taken_f;
    wire        ras_pred_taken_f;
    wire        ras_predict_valid_f;
    wire [31:0] ras_predict_target_f;
    wire        pred_taken_f;
    wire [31:0] pred_target_f;
    wire [31:0] predicted_next_pc_f;
    reg  [31:0] pc4_fetch_q;
    reg         pred_taken_fetch_q;
    reg  [31:0] pred_target_fetch_q;
    reg  [3:0]  gshare_index_fetch_q;
    reg         fetch_valid_q;
    reg         fetch_flush_q;
    reg         stall_q;
    reg  [31:0] stall_instr_q;
    reg  [31:0] stall_pc4_q;
    reg         stall_pred_taken_q;
    reg  [31:0] stall_pred_target_q;
    reg  [3:0]  stall_gshare_index_q;
    reg         stall_valid_q;

    // IF/ID
    reg [31:0] if_id_pc4;
    reg [31:0] if_id_instr;
    reg        if_id_pred_taken;
    reg [31:0] if_id_pred_target;
    reg [3:0]  if_id_gshare_index;
    reg        if_id_valid;

    // ID
    wire [6:0]  id_opcode;
    wire [2:0]  id_funct3;
    wire [6:0]  id_funct7;
    wire [4:0]  id_rs1;
    wire [4:0]  id_rs2;
    wire [4:0]  id_rd;
    wire [31:0] id_rdata1;
    wire [31:0] id_rdata2;
    wire [31:0] id_imm;
    wire        id_we;
    wire [3:0]  id_alu_ctrl;
    wire        id_alu_src;
    wire        id_mem_we;
    wire        id_mem_to_reg;
    wire        id_branch;
    wire        id_branch_ne;
    wire        id_branch_lt;
    wire        id_branch_ge;
    wire        id_branch_ltu;
    wire        id_branch_geu;
    wire        id_jal;
    wire        id_jalr;
    wire        id_uses_rs1;
    wire        id_uses_rs2;
    wire        stall;
    wire        id_auipc;
    wire [2:0]  id_load_type;
    wire [2:0]  id_store_type;

    // ID/EX
    reg [31:0] id_ex_pc4;
    reg [31:0] id_ex_rdata1;
    reg [31:0] id_ex_rdata2;
    reg [31:0] id_ex_imm;
    reg [4:0]  id_ex_rs1;
    reg [4:0]  id_ex_rs2;
    reg [4:0]  id_ex_rd;
    reg        id_ex_we;
    reg [3:0]  id_ex_alu_ctrl;
    reg        id_ex_alu_src;
    reg        id_ex_mem_we;
    reg        id_ex_mem_to_reg;
    reg        id_ex_branch;
    reg        id_ex_branch_ne;
    reg        id_ex_branch_lt;
    reg        id_ex_branch_ge;
    reg        id_ex_branch_ltu;
    reg        id_ex_branch_geu;
    reg        id_ex_jal;
    reg        id_ex_jalr;
    reg        id_ex_auipc;
    reg [2:0]  id_ex_load_type;
    reg [2:0]  id_ex_store_type;
    reg        id_ex_pred_taken;
    reg [31:0] id_ex_pred_target;
    reg [3:0]  id_ex_gshare_index;
    reg        id_ex_valid;

    // EX
    wire [1:0]  forward_a;
    wire [1:0]  forward_b;
    wire [31:0] ex_alu_a;
    wire [31:0] ex_rs2_value;
    wire [31:0] ex_alu_b;
    wire [31:0] ex_alu_result;
    wire        ex_zero;
    wire        ex_branch_lt_signed;
    wire        ex_branch_ge_signed;
    wire        ex_branch_ltu_unsigned;
    wire        ex_branch_geu_unsigned;
    wire [31:0] ex_branch_target;
    wire [31:0] ex_jalr_target;
    wire [31:0] ex_control_target;
    wire        ex_branch_taken;
    wire        ex_control_taken;
    wire [31:0] ex_actual_next_pc;
    wire        ex_mispredict;
    wire        btb_update_en;
    wire [31:0] btb_update_pc;
    wire [31:0] btb_update_target;
    wire        btb_update_is_return;
    wire        ras_push_en;
    wire [31:0] ras_push_data;
    wire        ras_pop_en;

    // EX/MEM1
    reg [31:0] ex_mem1_alu_result;
    reg [31:0] ex_mem1_pc4;
    reg [31:0] ex_mem1_wdata;
    reg [4:0]  ex_mem1_rd;
    reg        ex_mem1_we;
    reg        ex_mem1_mem_we;
    reg        ex_mem1_mem_to_reg;
    reg        ex_mem1_jal;
    reg [2:0]  ex_mem1_load_type;
    reg [2:0]  ex_mem1_store_type;
    reg        ex_mem1_valid;

    // MEM1/MEM2
    reg [31:0] mem1_mem2_alu_result;
    reg [31:0] mem1_mem2_pc4;
    wire [31:0] mem1_mem2_mem_rdata;
    reg [4:0]  mem1_mem2_rd;
    reg        mem1_mem2_we;
    reg        mem1_mem2_mem_to_reg;
    reg        mem1_mem2_jal;
    reg [2:0]  mem1_mem2_load_type;
    reg        mem1_mem2_valid;
    wire [31:0] mem_rdata;
    reg  [31:0] load_data;

    // MEM2/WB
    reg [31:0] mem2_wb_alu_result;
    reg [31:0] mem2_wb_pc4;
    reg [31:0] mem2_wb_mem_rdata;
    reg [4:0]  mem2_wb_rd;
    reg        mem2_wb_we;
    reg        mem2_wb_mem_to_reg;
    reg        mem2_wb_jal;
    reg        mem2_wb_valid;

    wire [31:0] wb_data;
    wire        flush_event;
    wire [31:0] ex_mem1_forward_data;
    wire [31:0] mem1_mem2_forward_data;

    pc u_pc(
        .clk(clk),
        .rst(rst),
        .pc_in(pc_next_f),
        .pc_out(pc_f)
    );

    assign pc4_f = pc_f + 32'd4;
    assign flush_event = ex_mispredict;
    assign dir_pred_taken_f = btb_hit_f && gshare_predict_taken_f;
    assign ras_pred_taken_f = btb_hit_f && btb_is_return_f && ras_predict_valid_f;
    assign pred_taken_f = ras_pred_taken_f || dir_pred_taken_f;
    assign pred_target_f = ras_pred_taken_f ? ras_predict_target_f : btb_target_f;
    assign predicted_next_pc_f = pred_taken_f ? pred_target_f : pc4_f;
    assign pc_next_f = ex_mispredict ? ex_actual_next_pc :
                       (stall ? pc_f : predicted_next_pc_f);

    instr_mem u_instr_mem(
        .clk(clk),
        .addr(pc_f),
        .instr(instr_f)
    );

    btb u_btb(
        .clk(clk),
        .rst(rst),
        .query_pc(pc_f),
        .hit(btb_hit_f),
        .target(btb_target_f),
        .is_return(btb_is_return_f),
        .update_en(btb_update_en),
        .update_pc(btb_update_pc),
        .update_target(btb_update_target),
        .update_is_return(btb_update_is_return)
    );

    gshare_predictor u_gshare(
        .clk(clk),
        .rst(rst),
        .query_pc(pc_f),
        .predict_taken(gshare_predict_taken_f),
        .ghr_value(gshare_ghr_f),
        .query_index(gshare_index_f),
        .update_en(btb_update_en),
        .update_index(id_ex_gshare_index),
        .update_taken(ex_control_taken)
    );

    ras u_ras(
        .clk(clk),
        .rst(rst),
        .predict_valid(ras_predict_valid_f),
        .predict_target(ras_predict_target_f),
        .push_en(ras_push_en),
        .push_data(ras_push_data),
        .pop_en(ras_pop_en)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc4_fetch_q   <= 32'b0;
            pred_taken_fetch_q <= 1'b0;
            pred_target_fetch_q <= 32'b0;
            gshare_index_fetch_q <= 4'b0;
            fetch_valid_q <= 1'b0;
            fetch_flush_q <= 1'b0;
            stall_q       <= 1'b0;
            stall_instr_q <= 32'b0;
            stall_pc4_q   <= 32'b0;
            stall_pred_taken_q <= 1'b0;
            stall_pred_target_q <= 32'b0;
            stall_gshare_index_q <= 4'b0;
            stall_valid_q <= 1'b0;
        end else begin
            stall_q <= stall;

            if (!stall) begin
                pc4_fetch_q   <= pc4_f;
                pred_taken_fetch_q <= pred_taken_f;
                pred_target_fetch_q <= pred_target_f;
                gshare_index_fetch_q <= gshare_index_f;
                fetch_valid_q <= 1'b1;
            end

            if (stall && !stall_q) begin
                stall_instr_q <= instr_f;
                stall_pc4_q   <= pc4_fetch_q;
                stall_pred_taken_q <= pred_taken_fetch_q;
                stall_pred_target_q <= pred_target_fetch_q;
                stall_gshare_index_q <= gshare_index_fetch_q;
                stall_valid_q <= fetch_valid_q && (instr_f != 32'h00000013) && (instr_f != 32'b0);
            end else if (stall_q && !stall) begin
                stall_valid_q <= 1'b0;
            end

            if (ex_mispredict) begin
                fetch_flush_q <= 1'b1;
                stall_valid_q <= 1'b0;
            end else if (fetch_flush_q && !stall) begin
                fetch_flush_q <= 1'b0;
            end
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            if_id_pc4   <= 32'b0;
            if_id_instr <= 32'b0;
            if_id_pred_taken <= 1'b0;
            if_id_pred_target <= 32'b0;
            if_id_gshare_index <= 4'b0;
            if_id_valid <= 1'b0;
        end else if (ex_mispredict) begin
            if_id_pc4   <= 32'b0;
            if_id_instr <= 32'b0;
            if_id_pred_taken <= 1'b0;
            if_id_pred_target <= 32'b0;
            if_id_gshare_index <= 4'b0;
            if_id_valid <= 1'b0;
        end else if (fetch_flush_q) begin
            if_id_pc4   <= 32'b0;
            if_id_instr <= 32'b0;
            if_id_pred_taken <= 1'b0;
            if_id_pred_target <= 32'b0;
            if_id_gshare_index <= 4'b0;
            if_id_valid <= 1'b0;
        end else if (stall) begin
            if_id_pc4   <= if_id_pc4;
            if_id_instr <= if_id_instr;
            if_id_pred_taken <= if_id_pred_taken;
            if_id_pred_target <= if_id_pred_target;
            if_id_gshare_index <= if_id_gshare_index;
            if_id_valid <= if_id_valid;
        end else if (stall_q) begin
            if_id_pc4   <= stall_pc4_q;
            if_id_instr <= stall_instr_q;
            if_id_pred_taken <= stall_pred_taken_q;
            if_id_pred_target <= stall_pred_target_q;
            if_id_gshare_index <= stall_gshare_index_q;
            if_id_valid <= stall_valid_q;
        end else begin
            if_id_pc4   <= pc4_fetch_q;
            if_id_instr <= fetch_valid_q ? instr_f : 32'h00000013;
            if_id_pred_taken <= pred_taken_fetch_q;
            if_id_pred_target <= pred_target_fetch_q;
            if_id_gshare_index <= gshare_index_fetch_q;
            if_id_valid <= fetch_valid_q && (instr_f != 32'h00000013) && (instr_f != 32'b0);
        end
    end

    assign id_opcode = if_id_instr[6:0];
    assign id_funct3 = if_id_instr[14:12];
    assign id_funct7 = if_id_instr[31:25];
    assign id_rs1    = if_id_instr[19:15];
    assign id_rs2    = if_id_instr[24:20];
    assign id_rd     = if_id_instr[11:7];

    reg_file u_reg_file(
        .clk(clk),
        .rst(rst),
        .we(mem2_wb_we),
        .raddr1(id_rs1),
        .raddr2(id_rs2),
        .waddr(mem2_wb_rd),
        .wdata(wb_data),
        .rdata1(id_rdata1),
        .rdata2(id_rdata2),
        .debug_x3(debug_x3),
        .debug_x4(debug_x4),
        .debug_x5(debug_x5),
        .debug_x7(debug_x7)
    );

    imm_gen u_imm_gen(
        .instr(if_id_instr),
        .imm(id_imm)
    );

    pipeline_control u_control(
        .opcode(id_opcode),
        .funct3(id_funct3),
        .funct7(id_funct7),
        .we(id_we),
        .alu_ctrl(id_alu_ctrl),
        .alu_src(id_alu_src),
        .mem_we(id_mem_we),
        .mem_to_reg(id_mem_to_reg),
        .branch(id_branch),
        .branch_ne(id_branch_ne),
        .branch_lt(id_branch_lt),
        .branch_ge(id_branch_ge),
        .branch_ltu(id_branch_ltu),
        .branch_geu(id_branch_geu),
        .jal(id_jal),
        .jalr(id_jalr),
        .uses_rs1(id_uses_rs1),
        .uses_rs2(id_uses_rs2),
        .auipc(id_auipc),
        .load_type(id_load_type),
        .store_type(id_store_type)
    );

    hazard_unit u_hazard_unit(
        .id_ex_mem_to_reg(id_ex_mem_to_reg),
        .id_ex_rd(id_ex_rd),
        .ex_mem1_mem_to_reg(ex_mem1_mem_to_reg),
        .ex_mem1_rd(ex_mem1_rd),
        .id_rs1(id_rs1),
        .id_rs2(id_rs2),
        .id_uses_rs1(id_uses_rs1),
        .id_uses_rs2(id_uses_rs2),
        .stall(stall)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            id_ex_pc4      <= 32'b0;
            id_ex_rdata1   <= 32'b0;
            id_ex_rdata2   <= 32'b0;
            id_ex_imm      <= 32'b0;
            id_ex_rs1      <= 5'b0;
            id_ex_rs2      <= 5'b0;
            id_ex_rd       <= 5'b0;
            id_ex_we       <= 1'b0;
            id_ex_alu_ctrl <= 4'b0;
            id_ex_alu_src  <= 1'b0;
            id_ex_mem_we     <= 1'b0;
            id_ex_mem_to_reg <= 1'b0;
            id_ex_branch     <= 1'b0;
            id_ex_branch_ne  <= 1'b0;
            id_ex_branch_lt  <= 1'b0;
            id_ex_branch_ge  <= 1'b0;
            id_ex_branch_ltu <= 1'b0;
            id_ex_branch_geu <= 1'b0;
            id_ex_jal        <= 1'b0;
            id_ex_jalr       <= 1'b0;
            id_ex_auipc      <= 1'b0;
            id_ex_load_type  <= 3'b000;
            id_ex_store_type <= 3'b000;
            id_ex_pred_taken <= 1'b0;
            id_ex_pred_target <= 32'b0;
            id_ex_gshare_index <= 4'b0;
            id_ex_valid      <= 1'b0;
        end else if (ex_mispredict) begin
            id_ex_pc4      <= 32'b0;
            id_ex_rdata1   <= 32'b0;
            id_ex_rdata2   <= 32'b0;
            id_ex_imm      <= 32'b0;
            id_ex_rs1      <= 5'b0;
            id_ex_rs2      <= 5'b0;
            id_ex_rd       <= 5'b0;
            id_ex_we       <= 1'b0;
            id_ex_alu_ctrl <= 4'b0;
            id_ex_alu_src  <= 1'b0;
            id_ex_mem_we     <= 1'b0;
            id_ex_mem_to_reg <= 1'b0;
            id_ex_branch     <= 1'b0;
            id_ex_branch_ne  <= 1'b0;
            id_ex_branch_lt  <= 1'b0;
            id_ex_branch_ge  <= 1'b0;
            id_ex_branch_ltu <= 1'b0;
            id_ex_branch_geu <= 1'b0;
            id_ex_jal        <= 1'b0;
            id_ex_jalr       <= 1'b0;
            id_ex_auipc      <= 1'b0;
            id_ex_load_type  <= 3'b000;
            id_ex_store_type <= 3'b000;
            id_ex_pred_taken <= 1'b0;
            id_ex_pred_target <= 32'b0;
            id_ex_gshare_index <= 4'b0;
            id_ex_valid      <= 1'b0;
        end else if (stall) begin
            id_ex_pc4      <= 32'b0;
            id_ex_rdata1   <= 32'b0;
            id_ex_rdata2   <= 32'b0;
            id_ex_imm      <= 32'b0;
            id_ex_rs1      <= 5'b0;
            id_ex_rs2      <= 5'b0;
            id_ex_rd       <= 5'b0;
            id_ex_we       <= 1'b0;
            id_ex_alu_ctrl <= 4'b0;
            id_ex_alu_src  <= 1'b0;
            id_ex_mem_we     <= 1'b0;
            id_ex_mem_to_reg <= 1'b0;
            id_ex_branch     <= 1'b0;
            id_ex_branch_ne  <= 1'b0;
            id_ex_branch_lt  <= 1'b0;
            id_ex_branch_ge  <= 1'b0;
            id_ex_branch_ltu <= 1'b0;
            id_ex_branch_geu <= 1'b0;
            id_ex_jal        <= 1'b0;
            id_ex_jalr       <= 1'b0;
            id_ex_auipc      <= 1'b0;
            id_ex_load_type  <= 3'b000;
            id_ex_store_type <= 3'b000;
            id_ex_pred_taken <= 1'b0;
            id_ex_pred_target <= 32'b0;
            id_ex_gshare_index <= 4'b0;
            id_ex_valid      <= 1'b0;
        end else begin
            id_ex_pc4      <= if_id_pc4;
            id_ex_rdata1   <= id_rdata1;
            id_ex_rdata2   <= id_rdata2;
            id_ex_imm      <= id_imm;
            id_ex_rs1      <= id_rs1;
            id_ex_rs2      <= id_rs2;
            id_ex_rd       <= id_rd;
            id_ex_we       <= id_we;
            id_ex_alu_ctrl <= id_alu_ctrl;
            id_ex_alu_src  <= id_alu_src;
            id_ex_mem_we     <= id_mem_we;
            id_ex_mem_to_reg <= id_mem_to_reg;
            id_ex_branch     <= id_branch;
            id_ex_branch_ne  <= id_branch_ne;
            id_ex_branch_lt  <= id_branch_lt;
            id_ex_branch_ge  <= id_branch_ge;
            id_ex_branch_ltu <= id_branch_ltu;
            id_ex_branch_geu <= id_branch_geu;
            id_ex_jal        <= id_jal;
            id_ex_jalr       <= id_jalr;
            id_ex_auipc      <= id_auipc;
            id_ex_load_type  <= id_load_type;
            id_ex_store_type <= id_store_type;
            id_ex_pred_taken <= if_id_pred_taken;
            id_ex_pred_target <= if_id_pred_target;
            id_ex_gshare_index <= if_id_gshare_index;
            id_ex_valid      <= if_id_valid;
        end
    end

    forward_unit u_forward_unit(
        .id_ex_rs1(id_ex_rs1),
        .id_ex_rs2(id_ex_rs2),
        .ex_mem1_rd(ex_mem1_rd),
        .ex_mem1_we(ex_mem1_we),
        .ex_mem1_mem_to_reg(ex_mem1_mem_to_reg),
        .mem1_mem2_rd(mem1_mem2_rd),
        .mem1_mem2_we(mem1_mem2_we),
        .mem1_mem2_mem_to_reg(mem1_mem2_mem_to_reg),
        .mem1_mem2_jal(mem1_mem2_jal),
        .mem2_wb_rd(mem2_wb_rd),
        .mem2_wb_we(mem2_wb_we),
        .forward_a(forward_a),
        .forward_b(forward_b)
    );

    assign ex_mem1_forward_data =
        ex_mem1_jal ? ex_mem1_pc4 : ex_mem1_alu_result;
    assign mem1_mem2_forward_data =
        mem1_mem2_jal ? mem1_mem2_pc4 :
        (mem1_mem2_mem_to_reg ? load_data :
                                mem1_mem2_alu_result);

    assign ex_alu_a = id_ex_auipc ? (id_ex_pc4 - 32'd4) :
                      (forward_a == 2'b10) ? ex_mem1_forward_data :
                      (forward_a == 2'b11) ? mem1_mem2_forward_data :
                      (forward_a == 2'b01) ? wb_data :
                                               id_ex_rdata1;

    assign ex_rs2_value = (forward_b == 2'b10) ? ex_mem1_forward_data :
                          (forward_b == 2'b11) ? mem1_mem2_forward_data :
                          (forward_b == 2'b01) ? wb_data :
                                                   id_ex_rdata2;

    assign ex_alu_b = id_ex_alu_src ? id_ex_imm : ex_rs2_value;
    assign ex_branch_target = (id_ex_pc4 - 32'd4) + id_ex_imm;
    assign ex_jalr_target = (ex_alu_a + id_ex_imm) & 32'hffff_fffe;
    assign ex_control_target = id_ex_jalr ? ex_jalr_target : ex_branch_target;
    assign ex_branch_lt_signed = ($signed(ex_alu_a) < $signed(ex_rs2_value));
    assign ex_branch_ge_signed = ($signed(ex_alu_a) >= $signed(ex_rs2_value));
    assign ex_branch_ltu_unsigned = (ex_alu_a < ex_rs2_value);
    assign ex_branch_geu_unsigned = (ex_alu_a >= ex_rs2_value);
    assign ex_branch_taken = id_ex_branch && (
        id_ex_branch_ne ? ~ex_zero :
        id_ex_branch_lt ? ex_branch_lt_signed :
        id_ex_branch_ge ? ex_branch_ge_signed :
        id_ex_branch_ltu ? ex_branch_ltu_unsigned :
        id_ex_branch_geu ? ex_branch_geu_unsigned :
                          ex_zero
    );
    assign ex_control_taken = id_ex_jal || id_ex_jalr || ex_branch_taken;
    assign ex_actual_next_pc = ex_control_taken ? ex_control_target : id_ex_pc4;
    assign ex_mispredict =
        id_ex_valid && (id_ex_branch || id_ex_jal || id_ex_jalr) &&
        ((!id_ex_pred_taken && ex_control_taken) ||
         (id_ex_pred_taken &&
          (!ex_control_taken ||
           (id_ex_pred_target != ex_control_target))));
    assign btb_update_en = id_ex_valid && (id_ex_branch || id_ex_jal || id_ex_jalr);
    assign btb_update_pc = id_ex_pc4 - 32'd4;
    assign btb_update_target = ex_control_target;
    assign btb_update_is_return = id_ex_jalr && ((id_ex_rs1 == 5'd1) || (id_ex_rs1 == 5'd5));
    assign ras_push_en = id_ex_valid && id_ex_jal && ((id_ex_rd == 5'd1) || (id_ex_rd == 5'd5));
    assign ras_push_data = id_ex_pc4;
    assign ras_pop_en = id_ex_valid && id_ex_jalr && ((id_ex_rs1 == 5'd1) || (id_ex_rs1 == 5'd5));

    alu u_alu(
        .a(ex_alu_a),
        .b(ex_alu_b),
        .alu_ctrl(id_ex_alu_ctrl),
        .result(ex_alu_result),
        .zero(ex_zero)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ex_mem1_alu_result <= 32'b0;
            ex_mem1_pc4        <= 32'b0;
            ex_mem1_wdata      <= 32'b0;
            ex_mem1_rd         <= 5'b0;
            ex_mem1_we         <= 1'b0;
            ex_mem1_mem_we     <= 1'b0;
            ex_mem1_mem_to_reg <= 1'b0;
            ex_mem1_jal        <= 1'b0;
            ex_mem1_load_type  <= 3'b000;
            ex_mem1_store_type <= 3'b000;
            ex_mem1_valid      <= 1'b0;
        end else begin
            ex_mem1_alu_result <= ex_alu_result;
            ex_mem1_pc4        <= id_ex_pc4;
            ex_mem1_wdata      <= ex_rs2_value;
            ex_mem1_rd         <= id_ex_rd;
            ex_mem1_we         <= id_ex_we;
            ex_mem1_mem_we     <= id_ex_mem_we;
            ex_mem1_mem_to_reg <= id_ex_mem_to_reg;
            ex_mem1_jal        <= id_ex_jal || id_ex_jalr;
            ex_mem1_load_type  <= id_ex_load_type;
            ex_mem1_store_type <= id_ex_store_type;
            ex_mem1_valid      <= id_ex_valid;
        end
    end

    data_mem u_data_mem(
        .clk(clk),
        .rst(rst),
        .we(ex_mem1_mem_we),
        .store_type(ex_mem1_store_type),
        .addr(ex_mem1_alu_result),
        .wdata(ex_mem1_wdata),
        .rdata(mem_rdata)
    );

    // 同步 BRAM 的读数据与 MEM1/MEM2 中的请求保持对齐
    assign mem1_mem2_mem_rdata = mem_rdata;

    always @(*) begin
        load_data = 32'b0;
        case (mem1_mem2_load_type)
            3'b001: begin // lb
                case (mem1_mem2_alu_result[1:0])
                    2'b00: load_data = {{24{mem1_mem2_mem_rdata[7]}},  mem1_mem2_mem_rdata[7:0]};
                    2'b01: load_data = {{24{mem1_mem2_mem_rdata[15]}}, mem1_mem2_mem_rdata[15:8]};
                    2'b10: load_data = {{24{mem1_mem2_mem_rdata[23]}}, mem1_mem2_mem_rdata[23:16]};
                    2'b11: load_data = {{24{mem1_mem2_mem_rdata[31]}}, mem1_mem2_mem_rdata[31:24]};
                endcase
            end
            3'b010: begin // lh
                case (mem1_mem2_alu_result[1:0])
                    2'b00: load_data = {{16{mem1_mem2_mem_rdata[15]}}, mem1_mem2_mem_rdata[15:0]};
                    2'b10: load_data = {{16{mem1_mem2_mem_rdata[31]}}, mem1_mem2_mem_rdata[31:16]};
                    default: load_data = 32'b0;
                endcase
            end
            3'b011: load_data = mem1_mem2_mem_rdata; // lw
            3'b100: begin // lbu
                case (mem1_mem2_alu_result[1:0])
                    2'b00: load_data = {24'b0, mem1_mem2_mem_rdata[7:0]};
                    2'b01: load_data = {24'b0, mem1_mem2_mem_rdata[15:8]};
                    2'b10: load_data = {24'b0, mem1_mem2_mem_rdata[23:16]};
                    2'b11: load_data = {24'b0, mem1_mem2_mem_rdata[31:24]};
                endcase
            end
            3'b101: begin // lhu
                case (mem1_mem2_alu_result[1:0])
                    2'b00: load_data = {16'b0, mem1_mem2_mem_rdata[15:0]};
                    2'b10: load_data = {16'b0, mem1_mem2_mem_rdata[31:16]};
                    default: load_data = 32'b0;
                endcase
            end
            default: load_data = 32'b0;
        endcase
    end

    // MEM1/MEM2
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mem1_mem2_alu_result <= 32'b0;
            mem1_mem2_pc4        <= 32'b0;
            mem1_mem2_rd         <= 5'b0;
            mem1_mem2_we         <= 1'b0;
            mem1_mem2_mem_to_reg <= 1'b0;
            mem1_mem2_jal        <= 1'b0;
            mem1_mem2_load_type  <= 3'b000;
            mem1_mem2_valid      <= 1'b0;
        end else begin
            mem1_mem2_alu_result <= ex_mem1_alu_result;
            mem1_mem2_pc4        <= ex_mem1_pc4;
            mem1_mem2_rd         <= ex_mem1_rd;
            mem1_mem2_we         <= ex_mem1_we;
            mem1_mem2_mem_to_reg <= ex_mem1_mem_to_reg;
            mem1_mem2_jal        <= ex_mem1_jal;
            mem1_mem2_load_type  <= ex_mem1_load_type;
            mem1_mem2_valid      <= ex_mem1_valid;
        end
    end

    // MEM2/WB
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mem2_wb_alu_result <= 32'b0;
            mem2_wb_pc4        <= 32'b0;
            mem2_wb_mem_rdata  <= 32'b0;
            mem2_wb_rd         <= 5'b0;
            mem2_wb_we         <= 1'b0;
            mem2_wb_mem_to_reg <= 1'b0;
            mem2_wb_jal        <= 1'b0;
            mem2_wb_valid      <= 1'b0;
        end else begin
            mem2_wb_alu_result <= mem1_mem2_alu_result;
            mem2_wb_pc4        <= mem1_mem2_pc4;
            mem2_wb_mem_rdata  <= load_data;
            mem2_wb_rd         <= mem1_mem2_rd;
            mem2_wb_we         <= mem1_mem2_we;
            mem2_wb_mem_to_reg <= mem1_mem2_mem_to_reg;
            mem2_wb_jal        <= mem1_mem2_jal;
            mem2_wb_valid      <= mem1_mem2_valid;
        end
    end

    assign wb_data = mem2_wb_jal ? mem2_wb_pc4 :
                     (mem2_wb_mem_to_reg ? mem2_wb_mem_rdata : mem2_wb_alu_result);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cycle_count   <= 32'b0;
            instret_count <= 32'b0;
            stall_count   <= 32'b0;
            flush_count   <= 32'b0;
            control_count <= 32'b0;
            predict_count <= 32'b0;
            btb_hit_count <= 32'b0;
            mispredict_count <= 32'b0;
            ras_hit_count <= 32'b0;
        end else begin
            cycle_count <= cycle_count + 32'd1;
            if (mem2_wb_valid)
                instret_count <= instret_count + 32'd1;
            if (stall)
                stall_count <= stall_count + 32'd1;
            if (flush_event)
                flush_count <= flush_count + 32'd1;
            if (id_ex_valid && (id_ex_branch || id_ex_jal || id_ex_jalr))
                control_count <= control_count + 32'd1;
            if (pred_taken_f)
                predict_count <= predict_count + 32'd1;
            if (btb_hit_f)
                btb_hit_count <= btb_hit_count + 32'd1;
            if (ras_pred_taken_f)
                ras_hit_count <= ras_hit_count + 32'd1;
            if (flush_event)
                mispredict_count <= mispredict_count + 32'd1;
        end
    end

endmodule

`ifdef SIMULATION
module tb_pipeline_cpu;
    reg clk;
    reg rst;
    integer cycle;
    real cpi_value;
    real ipc_value;
    real bench_cpi_value;
    real bench_ipc_value;
    reg bench_active;
    reg bench_done;
    integer bench_cycle_count;
    integer bench_instret_count;
    integer bench_stall_count;
    integer bench_flush_count;
    localparam [31:0] BENCH_START_PC = 32'h00000000;
    localparam [31:0] BENCH_END_PC   = 32'h00000184;
    wire [31:0] wb_retire_pc;

    pipeline_cpu_top uut(
        .clk(clk),
        .rst(rst)
    );

    assign wb_retire_pc = uut.mem2_wb_pc4 - 32'd4;

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        cycle = 0;
        bench_active = 1'b0;
        bench_done = 1'b0;
        bench_cycle_count = 0;
        bench_instret_count = 0;
        bench_stall_count = 0;
        bench_flush_count = 0;
        rst = 1'b1;
        #12;
        rst = 1'b0;
        $display("cycle | pc_f     st | IF instr | ID instr | EX rd we alu_result br jal take target fA fB | MEM1 rd we mem_we addr     wdata    rdata    | MEM2 rd we m2r alu_result rdata    | WB rd we wb_data | x1 x2 x3 x4 x5 x6 x7 x8 x9 x10 x11 x12 x13 x14 x15 mem4");
        #1500;

        $display("x1 = %0d", uut.u_reg_file.regs[1]);
        $display("x2 = %0d", uut.u_reg_file.regs[2]);
        $display("x3 = %0d", uut.u_reg_file.regs[3]);
        $display("x4 = %0d", uut.u_reg_file.regs[4]);
        $display("x5 = %0d", uut.u_reg_file.regs[5]);
        $display("x6 = %0d", uut.u_reg_file.regs[6]);
        $display("x7 = %0d", uut.u_reg_file.regs[7]);
        $display("x8 = %0d", uut.u_reg_file.regs[8]);
        $display("x9 = %0d", uut.u_reg_file.regs[9]);
        $display("x10 = %0d", uut.u_reg_file.regs[10]);
        $display("x11 = %0d", uut.u_reg_file.regs[11]);
        $display("x12 = %0d", uut.u_reg_file.regs[12]);
        $display("x13 = %0d", uut.u_reg_file.regs[13]);
        $display("x14 = %0d", uut.u_reg_file.regs[14]);
        $display("x15 = %0d", uut.u_reg_file.regs[15]);
        $display("x16 = %0d", uut.u_reg_file.regs[16]);
        $display("x17 = %0d", uut.u_reg_file.regs[17]);
        $display("x18 = %0d", uut.u_reg_file.regs[18]);
        $display("x19 = %0d", uut.u_reg_file.regs[19]);
        $display("x20 = %0d", uut.u_reg_file.regs[20]);
        $display("x21 = %0d", uut.u_reg_file.regs[21]);
        $display("x22 = %0d", uut.u_reg_file.regs[22]);
        $display("x23 = %0d", uut.u_reg_file.regs[23]);
        $display("x24 = %0d", uut.u_reg_file.regs[24]);
        $display("x25 = %0d", uut.u_reg_file.regs[25]);
        $display("x26 = %0d", uut.u_reg_file.regs[26]);
        $display("x27 = %0d", $signed(uut.u_reg_file.regs[27]));
        $display("x28 = %0d", $signed(uut.u_reg_file.regs[28]));
        $display("x29 = %0d", $signed(uut.u_reg_file.regs[29]));
        $display("x30 = %0d", uut.u_reg_file.regs[30]);
        $display("x31 = %0d", uut.u_reg_file.regs[31]);
        $display("mem[4] = %0d", uut.u_data_mem.debug_word(4));
        $display("mem[5] = %0d", uut.u_data_mem.debug_word(5));
        $display("mem[6] = %08h", uut.u_data_mem.debug_word(6));
        $display("mem[7] = %08h", uut.u_data_mem.debug_word(7));
        $display("mem[8] = %08h", uut.u_data_mem.debug_word(8));
        $display("mem[9] = %08h", uut.u_data_mem.debug_word(9));
        $display("mem[10] = %08h", uut.u_data_mem.debug_word(10));
        $display("mem[11] = %08h", uut.u_data_mem.debug_word(11));
        $display("mem[12] = %08h", uut.u_data_mem.debug_word(12));
        $display("mem[13] = %08h", uut.u_data_mem.debug_word(13));
        $display("mem[14] = %08h", uut.u_data_mem.debug_word(14));
        $display("mem[15] = %08h", uut.u_data_mem.debug_word(15));
        $display("mem[16] = %08h", uut.u_data_mem.debug_word(16));
        $display("mem[20] = %08h", uut.u_data_mem.debug_word(20));
        $display("mem[21] = %08h", uut.u_data_mem.debug_word(21));

        if (uut.instret_count != 0) begin
            cpi_value = uut.cycle_count * 1.0 / uut.instret_count;
            ipc_value = uut.instret_count * 1.0 / uut.cycle_count;
        end else begin
            cpi_value = 0.0;
            ipc_value = 0.0;
        end

        $display("PERF: cycle_count = %0d", uut.cycle_count);
        $display("PERF: instret_count = %0d", uut.instret_count);
        $display("PERF: stall_count = %0d", uut.stall_count);
        $display("PERF: flush_count = %0d", uut.flush_count);
        $display("PERF: control_count = %0d", uut.control_count);
        $display("PERF: mispredict_count = %0d", uut.mispredict_count);
        $display("PERF: CPI = %.4f", cpi_value);
        $display("PERF: IPC = %.4f", ipc_value);

        if (bench_instret_count != 0) begin
            bench_cpi_value = bench_cycle_count * 1.0 / bench_instret_count;
            bench_ipc_value = bench_instret_count * 1.0 / bench_cycle_count;
        end else begin
            bench_cpi_value = 0.0;
            bench_ipc_value = 0.0;
        end

        $display("BENCH: start_pc = %08h", BENCH_START_PC);
        $display("BENCH: end_pc = %08h", BENCH_END_PC);
        $display("BENCH: done = %0d", bench_done);
        $display("BENCH: cycle_count = %0d", bench_cycle_count);
        $display("BENCH: instret_count = %0d", bench_instret_count);
        $display("BENCH: stall_count = %0d", bench_stall_count);
        $display("BENCH: flush_count = %0d", bench_flush_count);
        $display("BENCH: CPI = %.4f", bench_cpi_value);
        $display("BENCH: IPC = %.4f", bench_ipc_value);

        if (uut.u_reg_file.regs[1] == 32'd16 &&
            uut.u_reg_file.regs[2] == 32'd9 &&
            uut.u_reg_file.regs[3] == 32'd9 &&
            uut.u_reg_file.regs[4] == 32'd18 &&
            uut.u_reg_file.regs[5] == 32'd3 &&
            uut.u_reg_file.regs[6] == 32'd1 &&
            uut.u_reg_file.regs[7] == 32'h178 &&
            uut.u_reg_file.regs[8] == 32'd0 &&
            uut.u_reg_file.regs[9] == 32'd1 &&
            uut.u_reg_file.regs[10] == 32'd5 &&
            uut.u_reg_file.regs[11] == 32'd8 &&
            uut.u_reg_file.regs[12] == 32'd13 &&
            uut.u_reg_file.regs[13] == 32'd21 &&
            uut.u_reg_file.regs[14] == 32'd9 &&
            uut.u_reg_file.regs[15] == 32'd14 &&
            uut.u_reg_file.regs[16] == 32'd9 &&
            uut.u_reg_file.regs[17] == 32'd9 &&
            uut.u_reg_file.regs[18] == 32'd1 &&
            uut.u_reg_file.regs[19] == 32'd27 &&
            uut.u_reg_file.regs[20] == 32'd9 &&
            uut.u_reg_file.regs[21] == 32'd18 &&
            uut.u_reg_file.regs[22] == 32'd17 &&
            uut.u_reg_file.regs[23] == 32'd18 &&
            uut.u_reg_file.regs[24] == 32'd9 &&
            uut.u_reg_file.regs[25] == 32'd36 &&
            uut.u_reg_file.regs[26] == 32'd9 &&
            uut.u_reg_file.regs[27] == 32'hfffffff0 &&
            uut.u_reg_file.regs[28] == 32'hfffffff8 &&
            uut.u_reg_file.regs[29] == 32'd0 &&
            uut.u_reg_file.regs[30] == 32'd1 &&
            uut.u_reg_file.regs[31] == 32'd0 &&
            uut.u_data_mem.debug_word(4) == 32'd9 &&
            uut.u_data_mem.debug_word(5) == 32'd1 &&
            uut.u_data_mem.debug_word(6) == 32'h12345000 &&
            uut.u_data_mem.debug_word(7) == 32'h000010c0 &&
            uut.u_data_mem.debug_word(8) == 32'h000080ff &&
            uut.u_data_mem.debug_word(9) == 32'hffffffff &&
            uut.u_data_mem.debug_word(10) == 32'hffff80ff &&
            uut.u_data_mem.debug_word(11) == 32'h000080ff &&
            uut.u_data_mem.debug_word(12) == 32'd0 &&
            uut.u_data_mem.debug_word(13) == 32'd2 &&
            uut.u_data_mem.debug_word(14) == 32'd2 &&
            uut.u_data_mem.debug_word(15) == 32'd0 &&
            uut.u_data_mem.debug_word(16) == 32'd0 &&
            uut.u_data_mem.debug_word(20) == 32'd3 &&
            uut.u_data_mem.debug_word(21) == 32'h178) begin
            $display("PASS: FPGA 37-instruction test works.");
        end else begin
            $display("FAIL: pipeline result is wrong.");
        end

        $finish;
    end

    // trace
    always @(posedge clk) begin
        #1;
        if (!rst) begin
            cycle = cycle + 1;

            if (!bench_done) begin
                if (!bench_active && uut.mem2_wb_valid && (wb_retire_pc == BENCH_START_PC))
                    bench_active = 1'b1;

                if (bench_active || (uut.mem2_wb_valid && (wb_retire_pc == BENCH_START_PC))) begin
                    bench_cycle_count = bench_cycle_count + 1;
                    if (uut.mem2_wb_valid)
                        bench_instret_count = bench_instret_count + 1;
                    if (uut.stall)
                        bench_stall_count = bench_stall_count + 1;
                    if (uut.flush_event)
                        bench_flush_count = bench_flush_count + 1;

                    if (uut.mem2_wb_valid && (wb_retire_pc == BENCH_END_PC)) begin
                        bench_done = 1'b1;
                        bench_active = 1'b0;
                    end
                end
            end

            $display("%5d | %08h %1b | %08h | %08h | x%-2d %1b  %08h %1b  %1b  %1b  %08h %1b %1b | x%-2d %1b %1b %08h %08h %08h | x%-2d %1b %1b %08h %08h | x%-2d %1b %08h | %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d",
                cycle,
                uut.pc_f,
                uut.stall,
                uut.instr_f,
                uut.if_id_instr,
                uut.id_ex_rd,
                uut.id_ex_we,
                uut.ex_alu_result,
                uut.ex_branch_taken,
                uut.id_ex_jal,
                uut.ex_control_taken,
                uut.ex_branch_target,
                uut.forward_a,
                uut.forward_b,
                uut.ex_mem1_rd,
                uut.ex_mem1_we,
                uut.ex_mem1_mem_we,
                uut.ex_mem1_alu_result,
                uut.ex_mem1_wdata,
                uut.mem_rdata,
                uut.mem1_mem2_rd,
                uut.mem1_mem2_we,
                uut.mem1_mem2_mem_to_reg,
                uut.mem1_mem2_alu_result,
                uut.mem1_mem2_mem_rdata,
                uut.mem2_wb_rd,
                uut.mem2_wb_we,
                uut.wb_data,
                uut.u_reg_file.regs[1],
                uut.u_reg_file.regs[2],
                uut.u_reg_file.regs[3],
                uut.u_reg_file.regs[4],
                uut.u_reg_file.regs[5],
                uut.u_reg_file.regs[6],
                uut.u_reg_file.regs[7],
                uut.u_reg_file.regs[8],
                uut.u_reg_file.regs[9],
                uut.u_reg_file.regs[10],
                uut.u_reg_file.regs[11],
                uut.u_reg_file.regs[12],
                uut.u_reg_file.regs[13],
                uut.u_reg_file.regs[14],
                uut.u_reg_file.regs[15],
                uut.u_data_mem.debug_word(4)
            );
        end
    end

    initial begin
        $dumpfile("tb_pipeline_cpu.vcd");
        $dumpvars(0, tb_pipeline_cpu);
    end
endmodule
`endif
