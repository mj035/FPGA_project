`timescale 1ns / 1ps

module key_assign(
    input        i_rstn     ,
    input        i_clk      ,
    input        i_key_valid,
    input  [4:0] i_key_value,
    output [4:0] o_bcd_data ,
    output       o_key_valid,
    
    // 출력 포트
    output  reg  o_mode_key,   // Mode Switch (Timer <-> Stopwatch)
    output  reg  o_lap_key,    // Lap 저장
    output  reg  o_view_key    // Lap 조회 (추가)
);

reg [4:0] r_bcd_data;
reg       r_key_valid;

always@(posedge i_clk, negedge i_rstn) begin
    if(!i_rstn) begin
        r_bcd_data <= 4'hf;
        o_mode_key <= 0;
        o_lap_key  <= 0;
        o_view_key <= 0;
    end
    else if(i_key_valid) begin
        // 기존 숫자 키 매핑 (Timer 시간 설정용)
             if(i_key_value==5'd12) r_bcd_data <= 5'h1;  // 10min
        else if(i_key_value==5'd13) r_bcd_data <= 5'h2;  // 30min
        else if(i_key_value==5'd14) r_bcd_data <= 5'h3;  // 60min
        else if(i_key_value==5'd7)  r_bcd_data <= 5'h4;  // 10sec
        else if(i_key_value==5'd8)  r_bcd_data <= 5'h5;  // 1min
        else if(i_key_value==5'd9)  r_bcd_data <= 5'h6;  // 5min
        
        // 기능 키 매핑
        else if(i_key_value==5'd20) begin 
            o_mode_key <= 1;         // 모드 전환 (Timer <-> Stopwatch)
            r_bcd_data <= 5'hf;
        end
        else if(i_key_value==5'd15) begin
            o_lap_key <= 1;          // LAP 저장
            r_bcd_data <= 5'hf;
        end
        else if(i_key_value==5'd10) begin
            o_view_key <= 1;         // LAP 조회 (추가)
            r_bcd_data <= 5'hf;
        end
        else begin
            r_bcd_data <= 5'hf;
            o_mode_key <= 0;
            o_lap_key <= 0;
            o_view_key <= 0;
        end
    end
    else begin
        // 키 안 눌렸을 때 신호 끄기
        o_mode_key <= 0;
        o_lap_key <= 0;
        o_view_key <= 0;
    end
end

always@(posedge i_clk, negedge i_rstn) begin
    if(!i_rstn) begin
        r_key_valid <= 1'b0;
    end
    else begin
        r_key_valid <= i_key_valid;
    end
end

assign o_bcd_data = r_bcd_data;
assign o_key_valid = r_key_valid;

endmodule
