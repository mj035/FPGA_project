`timescale 1ns / 1ps

module clk_pls(
    input i_clk,
    input i_rstn,
    output o_pls_1k,    //1ms pulse
    output o_pls_10ms   //10ms pulse(for stopwatch)
);

reg [13:0] cnt_1k;
reg        pls_1k;
//10ms 생성을 위한 레지스터 (추가)
reg [3:0]  cnt_10ms; // 0~9까지 세기 위해 4bit 필요
reg        pls_10ms; // 10ms

//1ms 펄스 생성
always@(posedge i_clk, negedge i_rstn) begin
    if(!i_rstn) begin
        cnt_1k <= 14'd0;
        pls_1k <= 1'b0;
    end
    else begin
        if(cnt_1k==14'd9999) begin
            cnt_1k <= 14'd0;
            pls_1k <= 1'b1;
        end
        else if(cnt_1k==14'd0) begin
            pls_1k <= 1'b0;
            cnt_1k <= cnt_1k+1;
        end
        else begin
            cnt_1k <= cnt_1k+1;
        end
    end
end

//10ms 펄스 생성
always@(posedge i_clk, negedge i_rstn) begin
    if(!i_rstn) begin
        cnt_10ms <= 4'd0;
        pls_10ms <= 1'b0;
    end
    else begin
        pls_10ms <= 1'b0;
        //1ms 펄스를 10번 count하여 10ms 펄스 생성
        if(pls_1k == 1'b1) begin
            if(cnt_10ms==4'd9) begin
                cnt_10ms <= 4'd0;
                pls_10ms <= 1'b1;
            end
            else begin
                cnt_10ms <= cnt_10ms + 1;
            end
        end
    end
end
assign o_pls_1k   = pls_1k;   //1ms clk
assign o_pls_10ms = pls_10ms; //10ms clk
endmodule