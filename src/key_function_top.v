`timescale 1ns / 1ps

module key_func_top(
    input        i_rstn      ,
    input        i_clk       ,
    input        i_pls_1k    ,
    input  [4:0] i_key_in    ,
    output [3:0] o_key_out   ,
    output [4:0] o_bcd_data  ,
    output       o_key_valid ,
    // 상위 모듈로 보낼 신호
    output       o_mode_sw_p,  // Mode Switch Pulse
    output       o_lap_sw_p,   // Lap 저장 Pulse
    output       o_view_sw_p   // Lap 조회 Pulse (추가)
);

wire       w_key_valid;
wire       w_key_valid_d;
wire [4:0] w_key_value;
    
key_scan U_key_scan (
    .i_rstn      (i_rstn     ),
    .i_clk       (i_clk      ),
    .i_pls_1k    (i_pls_1k   ),
    .i_key_in    (i_key_in   ),
    .o_key_out   (o_key_out  ),
    .o_key_valid (w_key_valid),
    .o_key_value (w_key_value)
);

key_assign U_key_assign (
    .i_rstn      (i_rstn     ),
    .i_clk       (i_clk      ),
    .i_key_valid (w_key_valid),
    .i_key_value (w_key_value),
    .o_bcd_data  (o_bcd_data ),
    .o_key_valid (w_key_valid_d),
    // 기능 키 신호 연결
    .o_mode_key  (o_mode_sw_p),
    .o_lap_key   (o_lap_sw_p),
    .o_view_key  (o_view_sw_p)   // 추가
);

assign o_key_valid = w_key_valid_d;

endmodule
