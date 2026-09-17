`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: tb_stopwatch_lap
// Description: 스톱워치 및 랩타임 기능 검증용 테스트벤치
//////////////////////////////////////////////////////////////////////////////////

module tb_stopwatch_lap;

    reg clk;
    reg rstn;
    reg start_sw;
    reg [4:0] key_push;

    wire [3:0] key_out;
    wire [4:0] key_in;
    wire [7:0] led;
    wire [7:0] seg_d;
    wire [7:0] seg_com;
    wire buzzer;

    // ========== 관찰용 내부 신호 ==========
    // 모드 상태
    wire        mode_state   = U_TIMER_TOP.r_mode_state;
    
    // 스톱워치 카운터
    wire [23:0] stop_cnt     = U_TIMER_TOP.U_DISP_CAL.r_stop_cnt;
    
    // 랩타임 관련
    wire [3:0]  lap_count    = U_TIMER_TOP.U_DISP_CAL.r_lap_count;  // 수정됨: 4비트
    wire [2:0]  view_index   = U_TIMER_TOP.U_DISP_CAL.r_view_index;
    wire        view_mode    = U_TIMER_TOP.U_DISP_CAL.r_view_mode;
    wire [23:0] lap_time_0   = U_TIMER_TOP.U_DISP_CAL.r_lap_time[0];
    wire [23:0] lap_time_1   = U_TIMER_TOP.U_DISP_CAL.r_lap_time[1];
    wire [23:0] lap_time_2   = U_TIMER_TOP.U_DISP_CAL.r_lap_time[2];
    wire [23:0] lap_time_3   = U_TIMER_TOP.U_DISP_CAL.r_lap_time[3];
    
    // 디스플레이 출력
    wire [31:0] bcd8d        = U_TIMER_TOP.U_DISP_CAL.o_bcd8d;
    
    // 랩 LED
    wire [7:0]  lap_led      = U_TIMER_TOP.U_DISP_CAL.o_lap_led;
    
    // Start Enable
    wire        start_en     = U_TIMER_TOP.U_DISP_CAL.r_start_en;

    // ========== 클럭 생성 (10MHz, 100ns 주기) ==========
    initial begin
        clk = 0;
        forever #50 clk = ~clk;
    end

    // ========== 리셋 ==========
    initial begin
        rstn = 0;
        #200;
        rstn = 1;
    end

    // ========== 메인 테스트 시퀀스 ==========
    initial begin
        // 초기화
        key_push = 5'd0;
        start_sw = 1;
        
        // 리셋 대기
        #500;
        
        $display("============================================");
        $display("  스톱워치 + 랩타임 기능 검증 시작");
        $display("============================================");
        
        // ========== STEP 1: 모드 전환 (Timer → Stopwatch) ==========
        $display("\n[STEP 1] 모드 전환: Timer -> Stopwatch");
        $display("  - F4 키 (key=20) 입력");
        
        #1_000_000;
        key_push = 5'd20;    // F4: 모드 전환
        #5_000_000;
        key_push = 5'd0;
        #5_000_000;
        
        $display("  - mode_state = %d (1이면 Stopwatch)", mode_state);
        
        // ========== STEP 2: 스톱워치 시작 ==========
        $display("\n[STEP 2] 스톱워치 시작");
        $display("  - Start 버튼 토글");
        
        start_sw = 0;        // Start 버튼 누름
        #1_000_000;
        start_sw = 1;        // Start 버튼 뗌
        #1_000_000;
        
        $display("  - start_en = %d (1이면 동작 중)", start_en);
        
        // ========== STEP 3: 스톱워치 동작 확인 (50ms 대기) ==========
        $display("\n[STEP 3] 스톱워치 카운트 확인");
        
        #50_000_000;  // 50ms 대기
        $display("  - stop_cnt = %d (약 50 예상)", stop_cnt);
        
        // ========== STEP 4: 첫 번째 LAP 저장 ==========
        $display("\n[STEP 4] 첫 번째 LAP 저장");
        $display("  - F3 키 (key=15) 입력");
        
        key_push = 5'd15;    // F3: LAP 저장
        #5_000_000;
        key_push = 5'd0;
        #5_000_000;
        
        $display("  - lap_count = %d", lap_count);
        $display("  - lap_time[0] = %d", lap_time_0);
        $display("  - lap_led = %b", lap_led);
        
        // ========== STEP 5: 추가 LAP 저장 (3개 더) ==========
        $display("\n[STEP 5] 추가 LAP 저장 (총 4개)");
        
        // LAP 2
        #30_000_000;  // 30ms 더 대기
        key_push = 5'd15;
        #5_000_000;
        key_push = 5'd0;
        #5_000_000;
        $display("  - LAP 2 저장: lap_time[1] = %d, lap_count = %d", lap_time_1, lap_count);
        
        // LAP 3
        #30_000_000;
        key_push = 5'd15;
        #5_000_000;
        key_push = 5'd0;
        #5_000_000;
        $display("  - LAP 3 저장: lap_time[2] = %d, lap_count = %d", lap_time_2, lap_count);
        
        // LAP 4
        #30_000_000;
        key_push = 5'd15;
        #5_000_000;
        key_push = 5'd0;
        #5_000_000;
        $display("  - LAP 4 저장: lap_time[3] = %d, lap_count = %d", lap_time_3, lap_count);
        $display("  - lap_led = %b (4개 LED 점등)", lap_led);
        
        // ========== STEP 6: LAP 조회 ==========
        $display("\n[STEP 6] LAP 조회 테스트");
        $display("  - * 키 (key=10) 입력하여 순차 조회");
        
        // VIEW 1
        key_push = 5'd10;    // *: LAP 조회
        #5_000_000;
        key_push = 5'd0;
        #5_000_000;
        $display("  - view_mode = %d, view_index = %d", view_mode, view_index);
        $display("  - 현재 표시 BCD: %h", bcd8d);
        
        // VIEW 2
        #10_000_000;
        key_push = 5'd10;
        #5_000_000;
        key_push = 5'd0;
        #5_000_000;
        $display("  - view_index = %d", view_index);
        
        // VIEW 3
        #10_000_000;
        key_push = 5'd10;
        #5_000_000;
        key_push = 5'd0;
        #5_000_000;
        $display("  - view_index = %d", view_index);
        
        // ========== STEP 7: 스톱워치 정지 ==========
        $display("\n[STEP 7] 스톱워치 정지");
        
        start_sw = 0;
        #1_000_000;
        start_sw = 1;
        #5_000_000;
        
        $display("  - start_en = %d (0이면 정지)", start_en);
        $display("  - 최종 stop_cnt = %d", stop_cnt);
        
        // ========== 완료 ==========
        #10_000_000;
        
        $display("\n============================================");
        $display("  검증 완료!");
        $display("============================================");
        $display("  [요약]");
        $display("  - 모드 전환: %s", mode_state ? "성공" : "실패");
        $display("  - 스톱워치 동작: %s", (stop_cnt > 0) ? "성공" : "실패");
        $display("  - LAP 저장: %d개 저장됨", lap_count);
        $display("============================================\n");
        
        $finish;
    end

    // ========== 키패드 매트릭스 시뮬레이션 ==========
    key_pad U_KEY_MATRIX (
        .rst            (rstn),
        .clk            (clk),
        .key_v          (key_push),
        .key_column_in  (key_out),
        .key_row_out    (key_in)
    );

    // ========== DUT (Device Under Test) ==========
    timer_top U_TIMER_TOP(
        .i_rstn      (rstn),
        .i_clk       (clk),
        .i_start_sw  (start_sw),
        .i_key_in    (key_in),
        .o_key_out   (key_out),
        .o_buzzer    (buzzer),
        .o_led       (led),
        .o_seg_d     (seg_d),
        .o_seg_com   (seg_com)
    );

endmodule