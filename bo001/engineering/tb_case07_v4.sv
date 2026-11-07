`timescale 1ns/1ps
// BO-SoC1 Case07 educational healthy vs injected fault testbench.
// All assertions and PASS markers must come from a real RTL simulator.
module tb_case07_v4;
  logic clk=0; always #5 clk=~clk;
  logic por_n=0, warm_rst_n=1, periph_rst_n=1;
  logic en_wr=0,en_val=0,flush=0,push=0,pop=0;
  logic [31:0] wr_data=0;
  wire [31:0] rd_ok,rd_bad;
  wire [3:0] lvl_ok,lvl_bad;
  wire empty_ok,full_ok,en_ok,empty_bad,full_bad,en_bad;

  bo_mailbox_fifo_v4 #(.FAULT_INJECTION(1'b0)) healthy (
   .clk,.por_n,.warm_rst_n,.periph_rst_n,.en_wr,.en_val,.flush,.push,.pop,.wr_data,
   .rd_data(rd_ok),.level(lvl_ok),.empty(empty_ok),.full(full_ok),.enabled(en_ok));
  bo_mailbox_fifo_v4 #(.FAULT_INJECTION(1'b1)) faulty (
   .clk,.por_n,.warm_rst_n,.periph_rst_n,.en_wr,.en_val,.flush,.push,.pop,.wr_data,
   .rd_data(rd_bad),.level(lvl_bad),.empty(empty_bad),.full(full_bad),.enabled(en_bad));

  task automatic por_reset;
    @(negedge clk);por_n=0;warm_rst_n=1;periph_rst_n=1;
    repeat(2) @(negedge clk);por_n=1;
    @(negedge clk);
  endtask
  task automatic enable_fifo;
    @(negedge clk);en_wr=1;en_val=1;
    @(negedge clk);en_wr=0;
  endtask
  task automatic enqueue(input logic [31:0] value);
    @(negedge clk);push=1;wr_data=value;
    @(negedge clk);push=0;
  endtask
  task automatic dequeue;
    @(negedge clk);pop=1;
    @(negedge clk);pop=0;
  endtask
  task automatic warm_reset;
    @(negedge clk);warm_rst_n=0;
    @(negedge clk);warm_rst_n=1;
  endtask
  task automatic peripheral_reset;
    @(negedge clk);periph_rst_n=0;
    @(negedge clk);periph_rst_n=1;
  endtask
  task automatic software_flush;
    @(negedge clk);flush=1;
    @(negedge clk);flush=0;
  endtask
  task automatic assert_levels(input integer expected_ok,input integer expected_bad);
    if(lvl_ok !== expected_ok || lvl_bad !== expected_bad)
      $fatal(1,"Unexpected fifo levels ok=%0d bad=%0d expected=(%0d,%0d)",lvl_ok,lvl_bad,expected_ok,expected_bad);
    if(empty_ok !== (expected_ok==0) || empty_bad !== (expected_bad==0))
      $fatal(1,"EMPTY flags inconsistent with occupancy");
    if(full_ok !== (expected_ok==8) || full_bad !== (expected_bad==8))
      $fatal(1,"FULL flags inconsistent with occupancy");
  endtask

  integer n,i;
  initial begin
    $dumpfile("case07_v4.vcd");$dumpvars(0,tb_case07_v4);
    #1;
    for(n=0;n<=8;n=n+1)begin
      por_reset();
      assert_levels(0,0);
      enable_fifo();
      for(i=0;i<n;i=i+1)enqueue(i+32'hA5);
      assert_levels(n,n);
      warm_reset();
      assert_levels(0,n);
      if(en_ok !== 0 || en_bad !== 0)$fatal(1,"Warm reset control state not cleared");
      software_flush();
      assert_levels(0,0);
      $display("PASS occupancy=%0d warm reset healthy/fault and software flush",n);
    end
    por_reset();enable_fifo();
    for(i=0;i<8;i=i+1)enqueue(i);
    enqueue(32'hDEAD);
    assert_levels(8,8);
    dequeue();assert_levels(7,7);
    peripheral_reset();assert_levels(0,0);
    if(en_ok !== 0 || en_bad !== 0)$fatal(1,"Peripheral reset failed to clear enable");
    $display("PASS Case 07 v4: levels 0..8, warm resets, flush, FIFO full boundary and peripheral reset");
    $finish;
  end
  initial begin #20000;$fatal(1,"Testbench watchdog timeout");end
endmodule
