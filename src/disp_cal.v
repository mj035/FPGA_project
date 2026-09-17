`timescale 1ns / 1ps

module disp_cal (
    input         i_rstn      ,
    input         i_clk       ,
    input         i_pls_1k    ,
    input         i_key_valid ,
    input         i_start     ,
    input  [ 3:0] i_bcd_data  ,
    output [31:0] o_bcd8d     ,
    output        o_fin       ,
    // 스탑워치용 입력 포트
    input         i_mode_sw   ,   // 0: Timer, 1: Stopwatch
    input         i_lap_sw    ,   // Lap Time 저장 버튼
    input         i_lap_view  ,   // Lap Time 조회 버튼 (추가)
    input         i_pls_10ms  ,   // 10ms pulse
    // 랩타임 LED 출력 (추가)
    output [7:0]  o_lap_led
);

    // 기존 Timer용 wire
    wire [3:0] w_digit_1, w_digit_2, w_digit_3, w_digit_4,
               w_digit_5, w_digit_6, w_digit_7, w_digit_8;
    wire [5:0] w_sec;
    wire [5:0] w_min;
    wire [6:0] w_hour;
    
    // 스탑워치 표시용 wire (추가)
    wire [3:0] w_stop_digit_1, w_stop_digit_2, w_stop_digit_3, w_stop_digit_4,
               w_stop_digit_5, w_stop_digit_6, w_stop_digit_7, w_stop_digit_8;
    wire [6:0] w_stop_ms;    // 10ms 단위 (0~99)
    wire [5:0] w_stop_sec;   // 초 (0~59)
    wire [5:0] w_stop_min;   // 분 (0~59)
    
    // 출력 데이터 선택
    wire [31:0] w_timer_disp;
    wire [31:0] w_stop_disp;
    wire [31:0] w_lap_disp;
    
    // Timer start 관련
    reg r_start_d1;
    reg r_start_d2;
    reg r_start_d3;
    reg r_start;
    reg r_start_en;
    
    reg [19:0] r_cnt_sec;
    reg [26:0] r_time_sec;
    reg        r_fin;
    reg        r_fin_d;
    
    // 스톱워치용 레지스터
    reg [23:0] r_stop_cnt;    // 스톱워치 카운터 (10ms 단위, 최대 약 46시간)
    
    // ========== 다중 랩타임 기능 (추가) ==========
    reg [23:0] r_lap_time [0:7];  // 랩타임 8개 저장
    reg [2:0]  r_lap_count;       // 저장된 랩 개수 (0~7)
    reg [2:0]  r_view_index;      // 조회 중인 인덱스
    reg        r_lap_sw_d;        // LAP 버튼 edge 검출
    reg        r_view_sw_d;       // VIEW 버튼 edge 검출
    reg        r_view_mode;       // 조회 모드 (0: 현재시간, 1: 랩타임)
    
    // LED 출력용 레지스터
    reg [7:0]  r_lap_led;
    
    // ========== Timer Start 로직 (기존) ==========
    always@(posedge i_clk, negedge i_rstn) begin
        if(!i_rstn) begin
            r_start_d1 <= 1'b1;
            r_start_d2 <= 1'b1;
            r_start_d3 <= 1'b1;
        end
        else begin
            r_start_d1 <= i_start;
            r_start_d2 <= r_start_d1;
            r_start_d3 <= r_start_d2;
        end
    end
    
    always@(posedge i_clk, negedge i_rstn) begin 
        if(!i_rstn) begin
            r_start_en <= 1'b0;
            r_start    <= 1'b0;
        end
        else begin
            if(r_start_d2 & (!r_start_d3)) begin 
                r_start_en <= ~r_start_en;
                r_start    <= 1'b1;
            end
        end
    end
    
    // ========== 랩타임 저장 로직 (수정) ==========
    always @(posedge i_clk or negedge i_rstn) begin
        if(!i_rstn) begin
            r_lap_sw_d <= 0;
            r_lap_count <= 0;
            r_lap_time[0] <= 0;
            r_lap_time[1] <= 0;
            r_lap_time[2] <= 0;
            r_lap_time[3] <= 0;
            r_lap_time[4] <= 0;
            r_lap_time[5] <= 0;
            r_lap_time[6] <= 0;
            r_lap_time[7] <= 0;
        end
        else begin
            r_lap_sw_d <= i_lap_sw;
            // LAP 버튼 rising edge 검출
            if (i_lap_sw && !r_lap_sw_d && i_mode_sw) begin
                // 8개 미만일 때만 저장
                if (r_lap_count < 8) begin
                    r_lap_time[r_lap_count] <= r_stop_cnt;
                    r_lap_count <= r_lap_count + 1;
                end
            end
            // 스탑워치 정지 시 (start_en이 0이 되면) 랩 초기화
            if (!r_start_en && i_mode_sw) begin
                r_lap_count <= 0;
            end
        end
    end
    
    // ========== 랩타임 조회 로직 (추가) ==========
    always @(posedge i_clk or negedge i_rstn) begin
        if(!i_rstn) begin
            r_view_sw_d <= 0;
            r_view_index <= 0;
            r_view_mode <= 0;
        end
        else begin
            r_view_sw_d <= i_lap_view;
            // VIEW 버튼 rising edge
            if (i_lap_view && !r_view_sw_d && i_mode_sw) begin
                if (r_lap_count > 0) begin
                    r_view_mode <= 1;
                    // 인덱스 순환 (0 → 1 → 2 → ... → 0)
                    if (r_view_index >= r_lap_count - 1)
                        r_view_index <= 0;
                    else
                        r_view_index <= r_view_index + 1;
                end
            end
            // 2초 후 자동으로 현재 시간으로 복귀 (간단히 LAP 버튼 누르면 복귀)
            if (i_lap_sw && !r_lap_sw_d && r_view_mode) begin
                r_view_mode <= 0;
            end
        end
    end
    
    // ========== LED 표시 로직 (추가) ==========
    always @(posedge i_clk or negedge i_rstn) begin
        if(!i_rstn) begin
            r_lap_led <= 8'b0000_0000;
        end
        else begin
            // 저장된 랩 개수만큼 LED 켜기
            case(r_lap_count)
                3'd0: r_lap_led <= 8'b0000_0000;
                3'd1: r_lap_led <= 8'b0000_0001;
                3'd2: r_lap_led <= 8'b0000_0011;
                3'd3: r_lap_led <= 8'b0000_0111;
                3'd4: r_lap_led <= 8'b0000_1111;
                3'd5: r_lap_led <= 8'b0001_1111;
                3'd6: r_lap_led <= 8'b0011_1111;
                3'd7: r_lap_led <= 8'b0111_1111;
                default: r_lap_led <= 8'b1111_1111;
            endcase
        end
    end
    
    // ========== Timer / Stopwatch 카운터 로직 ==========
    always@(posedge i_clk, negedge i_rstn) begin
        if(!i_rstn) begin
            r_cnt_sec <= 20'd0;
            r_time_sec <= 27'd0;
            r_fin <= 1'b0;
            r_stop_cnt <= 24'd0;
        end
        else if (i_key_valid & (!r_start_en)) begin
            // Timer 모드에서 시간 설정
            if(i_bcd_data==4'd1)      r_cnt_sec <= r_cnt_sec + 600;
            else if(i_bcd_data==4'd2) r_cnt_sec <= r_cnt_sec + 1800;
            else if(i_bcd_data==4'd3) r_cnt_sec <= r_cnt_sec + 3600;
            else if(i_bcd_data==4'd4) r_cnt_sec <= r_cnt_sec + 10;
            else if(i_bcd_data==4'd5) r_cnt_sec <= r_cnt_sec + 60;
            else if(i_bcd_data==4'd6) r_cnt_sec <= r_cnt_sec + 300;
            r_time_sec <= 27'd0;
        end
        else if(!r_start_en) begin
            r_time_sec <= 27'd0;
            r_fin <= 1'b0;
            // 스탑워치 정지 시 리셋
            if(i_mode_sw) begin
                r_stop_cnt <= 24'd0;
            end
        end
        else if (r_start_en) begin
            if(i_mode_sw == 0) begin
                // Timer 모드 (Count Down)
                if(r_cnt_sec == 0) begin
                    r_fin <= 1'b1;
                end
                else begin
                    if(r_time_sec == 27'd9999999) begin
                        r_time_sec <= 27'd0;
                        r_cnt_sec <= r_cnt_sec - 1;
                    end
                    else begin
                        r_time_sec <= r_time_sec + 1;
                    end
                end
            end
            else begin
                // Stopwatch 모드 (Count Up)
                if(i_pls_10ms) begin
                    // 최대값 체크 (99분 59초 99)
                    if(r_stop_cnt < 24'd599999) begin
                        r_stop_cnt <= r_stop_cnt + 1;
                    end
                end
            end
        end
    end
    
    // fin output pulse
    always@(posedge i_clk, negedge i_rstn) begin
        if(!i_rstn) begin
            r_fin_d <= 1'b0;
        end
        else begin
            r_fin_d <= r_fin;
        end
    end
    
    // ========== Timer 시간 계산 (기존) ==========
    assign w_hour = r_cnt_sec / 3600;
    assign w_min = (r_cnt_sec / 60) - (w_hour * 60);
    assign w_sec = r_cnt_sec - (w_hour * 3600) - (w_min * 60);
    
    assign w_digit_1 = w_sec - (w_digit_2 * 10);
    assign w_digit_2 = w_sec / 10;
    assign w_digit_3 = w_min - (w_digit_4 * 10);
    assign w_digit_4 = w_min / 10;
    assign w_digit_5 = w_hour - (w_digit_6 * 10);
    assign w_digit_6 = w_hour / 10;
    assign w_digit_7 = 4'd0;
    assign w_digit_8 = 4'd0;
    
    assign w_timer_disp = {w_digit_8, w_digit_7,
                          w_digit_6, w_digit_5,
                          w_digit_4, w_digit_3,
                          w_digit_2, w_digit_1};
    
    // ========== 스탑워치 시간 계산 (추가) ==========
    // r_stop_cnt: 10ms 단위 카운터
    // 예: r_stop_cnt = 6150 → 1분 1초 50 (61.50초)
    assign w_stop_ms  = r_stop_cnt % 100;                    // 10ms 자리 (0~99)
    assign w_stop_sec = (r_stop_cnt / 100) % 60;             // 초 (0~59)
    assign w_stop_min = (r_stop_cnt / 6000);                 // 분 (0~99)
    
    // 스탑워치 각 자리 계산
    assign w_stop_digit_1 = w_stop_ms % 10;                  // 10ms 1의 자리
    assign w_stop_digit_2 = w_stop_ms / 10;                  // 10ms 10의 자리
    assign w_stop_digit_3 = w_stop_sec % 10;                 // 초 1의 자리
    assign w_stop_digit_4 = w_stop_sec / 10;                 // 초 10의 자리
    assign w_stop_digit_5 = w_stop_min % 10;                 // 분 1의 자리
    assign w_stop_digit_6 = w_stop_min / 10;                 // 분 10의 자리
    assign w_stop_digit_7 = 4'd0;
    assign w_stop_digit_8 = 4'd0;
    
    // 스탑워치 표시 형식: [00][분분][초초][msms]
    assign w_stop_disp = {w_stop_digit_8, w_stop_digit_7,
                         w_stop_digit_6, w_stop_digit_5,
                         w_stop_digit_4, w_stop_digit_3,
                         w_stop_digit_2, w_stop_digit_1};
    
    // ========== 랩타임 표시 계산 (추가) ==========
    wire [23:0] w_view_lap;
    wire [6:0]  w_lap_ms;
    wire [5:0]  w_lap_sec;
    wire [5:0]  w_lap_min;
    wire [3:0]  w_lap_digit_1, w_lap_digit_2, w_lap_digit_3, w_lap_digit_4,
                w_lap_digit_5, w_lap_digit_6, w_lap_digit_7, w_lap_digit_8;
    
    assign w_view_lap = r_lap_time[r_view_index];
    assign w_lap_ms   = w_view_lap % 100;
    assign w_lap_sec  = (w_view_lap / 100) % 60;
    assign w_lap_min  = (w_view_lap / 6000);
    
    assign w_lap_digit_1 = w_lap_ms % 10;
    assign w_lap_digit_2 = w_lap_ms / 10;
    assign w_lap_digit_3 = w_lap_sec % 10;
    assign w_lap_digit_4 = w_lap_sec / 10;
    assign w_lap_digit_5 = w_lap_min % 10;
    assign w_lap_digit_6 = w_lap_min / 10;
    // 조회 모드에서 몇 번째 랩인지 표시 (1~8)
    assign w_lap_digit_7 = r_view_index + 1;
    assign w_lap_digit_8 = 4'd0;
    
    assign w_lap_disp = {w_lap_digit_8, w_lap_digit_7,
                        w_lap_digit_6, w_lap_digit_5,
                        w_lap_digit_4, w_lap_digit_3,
                        w_lap_digit_2, w_lap_digit_1};
    
    // ========== 최종 출력 선택 ==========
    assign o_bcd8d = (i_mode_sw == 0) ? w_timer_disp :      // Timer 모드
                     (r_view_mode)    ? w_lap_disp   :      // 랩타임 조회 모드
                                        w_stop_disp ;       // Stopwatch 진행 모드
    
    assign o_fin = r_fin & (!r_fin_d);
    assign o_lap_led = r_lap_led;

endmodule
