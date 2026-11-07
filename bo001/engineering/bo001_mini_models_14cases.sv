`timescale 1ns/1ps
// BO-001 miniature RTL teaching models. These ARE NOT complete BO-SoC1 subsystem implementations.
// Each module exposes an independently testable intended-vs-injected fault behavior.
module bo_boot_vector #(parameter FAULT=0)(input logic clk,rst_n,input logic strap_valid, input logic[31:0] strap_addr,output logic[31:0] pc);
  always @(posedge clk or negedge rst_n)
    if(!rst_n) pc<=32'h0001_0000;
    else if(strap_valid) pc<=FAULT ? 32'h0002_0000 : strap_addr;
endmodule
module bo_hart_release #(parameter FAULT=0)(input logic clk,rst_n,write_release,input logic[1:0]target,output logic hart1_running);
  always @(posedge clk or negedge rst_n)
    if(!rst_n)hart1_running<=0;
    else if(write_release && (FAULT ? target==2'd0 : target==2'd1))hart1_running<=1;
endmodule
module bo_reset_clock_order #(parameter FAULT=0)(input logic clk,rst_n,clock_stable,output logic peripheral_ready);
  always @(posedge clk or negedge rst_n)
    if(!rst_n)peripheral_ready<=0;
    else if(FAULT) peripheral_ready<=1;
    else if(clock_stable)peripheral_ready<=1;
endmodule
module bo_sticky_irq #(parameter FAULT=0)(input logic clk,rst_n,subsys_reset,irq_event,output logic pending);
  always @(posedge clk or negedge rst_n)
    if(!rst_n)pending<=0;
    else if(subsys_reset)pending<=FAULT ? pending : 1'b0;
    else if(irq_event)pending<=1;
endmodule
module bo_axi_decode #(parameter FAULT=0)(input logic[31:0] addr,output logic decerr);
  always @* decerr = FAULT ? !((addr & 32'hFFFF_0000)==32'h4001_0000) : !((addr & 32'hFFF0_0000)==32'h4000_0000);
endmodule
module bo_byte_strobes #(parameter FAULT=0)(input logic clk,rst_n,write_en,input logic[3:0] strb,input logic[31:0] wdata,output logic[31:0] reg_value);
  integer j;
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n)reg_value<=0;
    else if(write_en)
      for(j=0;j<4;j=j+1)
        if(FAULT ? (j==0 && strb[0]) : strb[j])reg_value[j*8+:8]<=wdata[j*8+:8];
  end
endmodule
module bo_apb_ready #(parameter FAULT=0)(input logic clk,rst_n,psel,penable,input logic peripheral_ack,output logic pready);
  always @(posedge clk or negedge rst_n)
    if(!rst_n)pready<=0;
    else pready<=FAULT ? (psel && penable && 1'b0) : (psel && penable && peripheral_ack);
endmodule
module bo_w1c #(parameter FAULT=0)(input logic clk,rst_n,event_in,set_write,input logic[3:0] write_bits,output logic[3:0] status);
  always @(posedge clk or negedge rst_n)
    if(!rst_n)status<=0;
    else if(event_in)status<=status|4'b0100;
    else if(set_write)status<=FAULT ? write_bits : (status & ~write_bits);
endmodule
module bo_pll_lock #(parameter FAULT=0)(input logic clk,rst_n,output logic locked);
  reg[2:0]cnt;
  always @(posedge clk or negedge rst_n)
    if(!rst_n)begin locked<=0;cnt<=0;end
    else if(!locked)begin cnt<=cnt+1'b1;if(!FAULT && cnt==3'd3)locked<=1;end
endmodule
module bo_dma_address #(parameter FAULT=0)(input logic[15:0] addr_hi,addr_lo,output logic[31:0] address);
  always @* address=FAULT ? {addr_lo,addr_hi}:{addr_hi,addr_lo};
endmodule
module bo_irq_enable #(parameter FAULT=0)(input logic pending,enabled,output logic core_irq);
  always @* core_irq=FAULT ? pending : (pending && enabled);
endmodule
module bo_privilege #(parameter FAULT=0)(input logic security_mode,privileged,output logic allowed);
  always @* allowed=FAULT ? privileged : (security_mode && privileged);
endmodule
module bo_busy #(parameter FAULT=0)(input logic clk,rst_n,start,complete,output logic busy);
  always @(posedge clk or negedge rst_n)
    if(!rst_n)busy<=0;
    else if(start)busy<=1;
    else if(complete && !FAULT)busy<=0;
endmodule
module bo_dma_irq_order #(parameter FAULT=0)(input logic clk,rst_n,dma_done,data_visible,output logic irq);
  always @(posedge clk or negedge rst_n)
    if(!rst_n)irq<=0;
    else irq<=FAULT ? dma_done : (dma_done && data_visible);
endmodule
