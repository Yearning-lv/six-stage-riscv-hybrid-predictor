`timescale 1ns/1ps

module a7lite_riscv_top_p3_v1_7(
    input  wire clk,
    input  wire rst_n,
    output wire led0,
    output wire led1
);
    wire rst = ~rst_n;

    wire [31:0] cycle_count;
    wire [31:0] instret_count;
    wire [31:0] stall_count;
    wire [31:0] flush_count;
    wire [31:0] control_count;
    wire [31:0] predict_count;
    wire [31:0] btb_hit_count;
    wire [31:0] mispredict_count;
    wire [31:0] ras_hit_count;
    wire [31:0] debug_x3;
    wire [31:0] debug_x4;
    wire [31:0] debug_x5;
    wire [31:0] debug_x7;

    pipeline_cpu_top #(
        .PRED_INDEX_BITS(5),
        .GHR_BITS(5),
        .RAS_DEPTH(4)
    ) u_cpu (
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
        .debug_x3(debug_x3),
        .debug_x4(debug_x4),
        .debug_x5(debug_x5),
        .debug_x7(debug_x7)
    );

    assign led0 = cycle_count[24];
    assign led1 = (debug_x3 == 32'd9) &&
                  (debug_x4 == 32'd18) &&
                  (debug_x5 == 32'd3) &&
                  (debug_x7 == 32'h00000178);

endmodule
