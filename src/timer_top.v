`timescale 1ns / 1ps

module timer_top(
    input        i_rstn      ,
    input        i_clk       ,
    input        i_start_sw  ,
    input  [4:0] i_key_in    ,
    output [3:0] o_key_out   ,
    output       o_buzzer    ,
    output [7:0] o_led       ,
    output [7:0] o_seg_d     ,
    output [7:0] o_seg_com   
);

wire        w_pls_1k;
wire        w_pls_10ms;
wire [4:0]  w_bcd_data;
wire [31:0] w_bcd8d;
wire        w_fin;
wire        w_key_valid;

// 기능 키 신호 (pulse)
wire        w_mode_sw;
wire        w_lap_sw;
wire        w_view_sw;

// 랩타임 LED 신호
wire [7:0]  w_lap_led;

// ========== 모드 상태 유지 레지스터 (핵심 수정!) ==========
reg r_mode_state;  // 0: Timer, 1: Stopwatch
always @(posedge i_clk or negedge i_rstn) begin
    if (!i_rstn)
        r_mode_state <= 0;
    else if (w_mode_sw)
        r_mode_state <= ~r_mode_state;  // F4 누르면 토글
end

// ========== 클럭 펄스 생성 ==========
clk_pls U_CLK_PLS(
    .i_clk      (i_clk),
    .i_rstn     (i_rstn),
    .o_pls_1k   (w_pls_1k),
    .o_pls_10ms (w_pls_10ms)
);

// ========== 키패드 처리 ==========
key_func_top U_KEY_FUNC_TOP (
    .i_rstn      (i_rstn     ),
    .i_clk       (i_clk      ),
    .i_pls_1k    (w_pls_1k   ),
    .i_key_in    (i_key_in   ),
    .o_key_out   (o_key_out  ),
    .o_bcd_data  (w_bcd_data ),
    .o_key_valid (w_key_valid),
    .o_mode_sw_p (w_mode_sw  ), 
    .o_lap_sw_p  (w_lap_sw   ),
    .o_view_sw_p (w_view_sw  )
);

// ========== 디스플레이 계산 (Timer + Stopwatch + Lap) ==========
disp_cal U_DISP_CAL (
    .i_rstn      (i_rstn      ),
    .i_clk       (i_clk       ),
    .i_pls_1k    (w_pls_1k    ),
    .i_key_valid (w_key_valid ),
    .i_start     (i_start_sw  ),
    .i_bcd_data  (w_bcd_data  ),
    .o_bcd8d     (w_bcd8d     ),
    .o_fin       (w_fin       ),
    // ★★★ 핵심 수정: r_mode_state로 변경! ★★★
    .i_mode_sw   (r_mode_state),  // pulse 대신 상태값 전달!
    .i_lap_sw    (w_lap_sw    ),
    .i_lap_view  (w_view_sw   ),
    .i_pls_10ms  (w_pls_10ms  ),
    .o_lap_led   (w_lap_led   )
);

// ========== 7세그먼트 출력 ==========
seg8digit U_SEG8D (
    .i_rstn    (i_rstn   ),
    .i_clk     (i_clk    ),
    .i_pls_1k  (w_pls_1k ),
    .i_bcd8d   (w_bcd8d  ),
    .o_seg_d   (o_seg_d  ),
    .o_seg_com (o_seg_com)   
);

// ========== 부저 ==========
buzzer_cnt U_BUZZ (
    .i_rstn   (i_rstn   ),
    .i_clk    (i_clk    ),
    .i_pls_1k (w_pls_1k ),
    .i_go     (w_fin    ),
    .o_buzzer (o_buzzer )
);

// ========== LED 출력 ==========
wire [7:0] w_timer_led;

led_blink U_LED_B (
    .i_rstn   (i_rstn     ),
    .i_clk    (i_clk      ),
    .i_pls_1k (w_pls_1k   ),
    .i_go     (w_fin      ),
    .o_led_on (w_timer_led)
);

// Timer 모드(0): 타이머 LED, Stopwatch 모드(1): 랩 LED
assign o_led = (r_mode_state == 0) ? w_timer_led : ~w_lap_led;

endmodule
