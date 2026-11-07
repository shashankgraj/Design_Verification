`timescale 1ns/1ps
// Distinct, minimal, directed RTL teaching checks for 14 BO-001 failure patterns.
// A PASS here verifies ONLY this miniature model, not a complete AXI, DRAM, PLL,
// RISC-V core, DMA engine, clock-domain crossing or hardware emulation platform.
module tb_bo001_mini14;
reg clk=0; always #5 clk=~clk;
reg rst_n=0, strap_valid=0, write_release=0, clock_stable=0,
    subsys_reset=0, irq_event=0, wr_en=0,psel=0,penable=0,
    ack=0,event_in=0,w1c_wr=0,start=0,complete=0,dma_done=0,data_visible=0;
reg [31:0] strap_addr=32'h00010000,decode_addr=0,wdata=0;
reg [1:0]target=0;
reg[3:0]strb=0,clear_bits=0;
reg[15:0]addr_hi=0,addr_lo=0;
reg irq_pending=0,irq_enabled=0,security_mode=0,privileged=0;
wire[31:0] pc_good,pc_bad,reg_good,reg_bad,dma_good,dma_bad;
wire hart_good,hart_bad,clk_good,clk_bad,sticky_good,sticky_bad;
wire dec_good,dec_bad,pready_good,pready_bad,lock_good,lock_bad;
wire irq_good,irq_bad,allow_good,allow_bad,busy_good,busy_bad,order_good,order_bad;
wire[3:0]status_good,status_bad;
bo_boot_vector #(0) c01g(clk,rst_n,strap_valid,strap_addr,pc_good);
bo_boot_vector #(1) c01b(clk,rst_n,strap_valid,strap_addr,pc_bad);
bo_hart_release #(0) c04g(clk,rst_n,write_release,target,hart_good);
bo_hart_release #(1) c04b(clk,rst_n,write_release,target,hart_bad);
bo_reset_clock_order #(0) c06g(clk,rst_n,clock_stable,clk_good);
bo_reset_clock_order #(1) c06b(clk,rst_n,clock_stable,clk_bad);
bo_sticky_irq #(0) c08g(clk,rst_n,subsys_reset,irq_event,sticky_good);
bo_sticky_irq #(1) c08b(clk,rst_n,subsys_reset,irq_event,sticky_bad);
bo_axi_decode #(0) c11g(decode_addr,dec_good);
bo_axi_decode #(1) c11b(decode_addr,dec_bad);
bo_byte_strobes #(0) c12g(clk,rst_n,wr_en,strb,wdata,reg_good);
bo_byte_strobes #(1) c12b(clk,rst_n,wr_en,strb,wdata,reg_bad);
bo_apb_ready #(0) c13g(clk,rst_n,psel,penable,ack,pready_good);
bo_apb_ready #(1) c13b(clk,rst_n,psel,penable,ack,pready_bad);
bo_w1c #(0) c15g(clk,rst_n,event_in,w1c_wr,clear_bits,status_good);
bo_w1c #(1) c15b(clk,rst_n,event_in,w1c_wr,clear_bits,status_bad);
bo_pll_lock #(0) c17g(clk,rst_n,lock_good);
bo_pll_lock #(1) c17b(clk,rst_n,lock_bad);
bo_dma_address #(0) c22g(addr_hi,addr_lo,dma_good);
bo_dma_address #(1) c22b(addr_hi,addr_lo,dma_bad);
bo_irq_enable #(0) c26g(irq_pending,irq_enabled,irq_good);
bo_irq_enable #(1) c26b(irq_pending,irq_enabled,irq_bad);
bo_privilege #(0) c28g(security_mode,privileged,allow_good);
bo_privilege #(1) c28b(security_mode,privileged,allow_bad);
bo_busy #(0) c30g(clk,rst_n,start,complete,busy_good);
bo_busy #(1) c30b(clk,rst_n,start,complete,busy_bad);
bo_dma_irq_order #(0) c38g(clk,rst_n,dma_done,data_visible,order_good);
bo_dma_irq_order #(1) c38b(clk,rst_n,dma_done,data_visible,order_bad);
task automatic tick; @(negedge clk); #1; endtask
initial begin
  $dumpfile("bo001_mini14.vcd"); $dumpvars(0,tb_bo001_mini14);
  repeat(2) tick(); rst_n=1; tick();
  strap_addr=32'h00010000;strap_valid=1;tick();
  if(pc_good!==32'h00010000||pc_bad!==32'h00020000)$fatal(1,"C01 bootvector");$display("PASS MINI C01");
  strap_valid=0;write_release=1;target=2'd1;tick();
  if(hart_good!==1||hart_bad!==0)$fatal(1,"C04 hart");$display("PASS MINI C04");
  write_release=0;clock_stable=0;tick();
  if(clk_good!==0||clk_bad!==1)$fatal(1,"C06 reset clock");$display("PASS MINI C06");
  irq_event=1;tick();irq_event=0;subsys_reset=1;tick();
  if(sticky_good!==0||sticky_bad!==1)$fatal(1,"C08 sticky");$display("PASS MINI C08");
  subsys_reset=0;decode_addr=32'h40002000;#1;
  if(dec_good!==0||dec_bad!==1)$fatal(1,"C11 AXI decode");$display("PASS MINI C11");
  wdata=32'h00CC0000;strb=4'b0100;wr_en=1;tick();
  if(reg_good!==32'h00CC0000||reg_bad!==0)$fatal(1,"C12 byte strobe");$display("PASS MINI C12");
  wr_en=0;psel=1;penable=1;ack=1;tick();
  if(pready_good!==1||pready_bad!==0)$fatal(1,"C13 APB ready");$display("PASS MINI C13");
  psel=0;penable=0;ack=0;event_in=1;tick();event_in=0;w1c_wr=1;clear_bits=4'b0100;tick();
  if(status_good!==0||status_bad!==4'b0100)$fatal(1,"C15 W1C");$display("PASS MINI C15");
  w1c_wr=0;repeat(4)tick();
  if(lock_good!==1||lock_bad!==0)$fatal(1,"C17 PLL lock");$display("PASS MINI C17");
  addr_hi=16'h1000;addr_lo=16'h0080;#1;
  if(dma_good!==32'h10000080||dma_bad!==32'h00801000)$fatal(1,"C22 DMA address");$display("PASS MINI C22");
  irq_pending=1;irq_enabled=0;#1;
  if(irq_good!==0||irq_bad!==1)$fatal(1,"C26 irq mask");$display("PASS MINI C26");
  security_mode=0;privileged=1;#1;
  if(allow_good!==0||allow_bad!==1)$fatal(1,"C28 privilege");$display("PASS MINI C28");
  start=1;tick();start=0;complete=1;tick();
  if(busy_good!==0||busy_bad!==1)$fatal(1,"C30 busy flag");$display("PASS MINI C30");
  complete=0;dma_done=1;data_visible=0;tick();
  if(order_good!==0||order_bad!==1)$fatal(1,"C38 IRQ before data");$display("PASS MINI C38");
  $display("PASS ALL 14 DISTINCT MINIATURE RTL DEMONSTRATIONS");
  $finish;
end
initial begin #20000;$fatal(1,"watchdog");end
endmodule
