`timescale 1ns/1ps
// BO-001 original, fictional, limited-scope educational micro-models.
// These are not BO-SoC1 integration or commercial protocol-compliance models.
// FAULT=1 intentionally injects a specific misbehavior; no real IP is reproduced.
module bo_uart_observe #(parameter FAULT=0)(input logic clk,rst_n,cpu_active,uart_clk_ok,send,output logic tx_valid);
always @(posedge clk or negedge rst_n) if(!rst_n)tx_valid<=0;else tx_valid<=send&&cpu_active&&(FAULT?1'b0:uart_clk_ok);
endmodule
module bo_dram_training #(parameter FAULT=0)(input logic clk,rst_n,training_start,output logic training_done);
reg[2:0]count;
always @(posedge clk or negedge rst_n)if(!rst_n)begin count<=0;training_done<=0;end
else if(training_start&&!training_done)begin count<=count+1'b1;if(count==3 && !FAULT)training_done<=1;end
endmodule
module bo_image_bounds #(parameter FAULT=0)(input logic[15:0]image_bytes,output logic image_valid);
always @* image_valid=FAULT ? (image_bytes <= 16'd2048) : (image_bytes <=16'd4096);
endmodule
module bo_axi_reset_outstanding #(parameter FAULT=0)(input logic clk,rst_n,start_txn,warm_reset,output logic pending);
always @(posedge clk or negedge rst_n)if(!rst_n)pending<=0;
else if(warm_reset)pending<=FAULT?pending:1'b0;
else if(start_txn)pending<=1;
endmodule
module bo_short_reset_capture #(parameter FAULT=0)(input logic clk,por_n,short_reset_n,clear_seen,output logic reset_seen);
generate if(FAULT)begin
  always @(posedge clk or negedge por_n)if(!por_n)reset_seen<=0;else if(!short_reset_n)reset_seen<=1;else if(clear_seen)reset_seen<=0;
end else begin
  always @(posedge clk or negedge por_n or negedge short_reset_n)
    if(!por_n)reset_seen<=0;else if(!short_reset_n)reset_seen<=1;else if(clear_seen)reset_seen<=0;
end endgenerate
endmodule
module bo_status_shadow #(parameter FAULT=0)(input logic clk,rst_n,completion_event,output logic status_done);
always @(posedge clk or negedge rst_n)if(!rst_n)status_done<=0;else if(completion_event && !FAULT)status_done<=1;
endmodule
module bo_gate_outstanding #(parameter FAULT=0)(input logic gate_req,outstanding,output logic allow_gate);
always @* allow_gate=FAULT?gate_req:(gate_req&&!outstanding);
endmodule
module bo_freq_timeout #(parameter FAULT=0)(input logic frequency_changed,input logic[7:0]elapsed_cycles,output logic timeout);
always @* timeout=FAULT ? (elapsed_cycles>8'd4) : (elapsed_cycles>(frequency_changed?8'd8:8'd4));
endmodule
module bo_isolation #(parameter FAULT=0)(input logic clk,rst_n,power_good,output logic isolation_active);
always @(posedge clk or negedge rst_n)if(!rst_n)isolation_active<=1;
else if(power_good && !FAULT)isolation_active<=0;
endmodule
module bo_wake_latch #(parameter FAULT=0)(input logic clk,rst_n,sleeping,wake_pulse,output logic wake_pending);
always @(posedge clk or negedge rst_n)if(!rst_n)wake_pending<=0;else if(wake_pulse && (FAULT ? !sleeping : 1'b1))wake_pending<=1;
endmodule
module bo_dram_mapping #(parameter FAULT=0)(input logic[7:0]offset,output logic[31:0]mapped_addr);
always @* mapped_addr=FAULT ? (32'h8000_0000+({24'b0,offset}<<4)) : (32'h8000_0000+{24'b0,offset});
endmodule
module bo_cache_dma #(parameter FAULT=0)(input logic clk,rst_n,cpu_fill,dma_write,output logic cache_valid);
always @(posedge clk or negedge rst_n)if(!rst_n)cache_valid<=0;
else if(dma_write&&!FAULT)cache_valid<=0;
else if(cpu_fill)cache_valid<=1;
endmodule
module bo_ecc_classify #(parameter FAULT=0)(input logic single_bit,double_bit,output logic correctable,uncorrectable);
always @* begin correctable=FAULT?double_bit:single_bit;uncorrectable=FAULT?single_bit:double_bit;end
endmodule
module bo_arbiter #(parameter FAULT=0)(input logic clk,rst_n,req0,req1,output logic grant0,grant1);
reg turn;
always @(posedge clk or negedge rst_n)if(!rst_n)turn<=0;else if(req0&&req1&&!FAULT)turn<=!turn;
always @* begin
grant0=req0&&(!req1 || (FAULT?1'b1:!turn));
grant1=req1&&(!req0 || (FAULT?1'b0:turn));
end
endmodule
module bo_irq_affinity #(parameter FAULT=0)(input logic request,input logic target_hart1,output logic irq0,irq1);
always @* begin irq0=request&&(FAULT||!target_hart1);irq1=request&&!FAULT&&target_hart1;end
endmodule
module bo_auth_image #(parameter FAULT=0)(input logic test_mode,valid_prod_signer,valid_test_signer,output logic accepted);
always @* accepted=FAULT?valid_prod_signer:((test_mode&&valid_test_signer)||(!test_mode&&valid_prod_signer));
endmodule
module bo_transactor #(parameter FAULT=0)(input logic clk,rst_n,host_valid,target_ready,output logic accepted);
always @(posedge clk or negedge rst_n)if(!rst_n)accepted<=0;else accepted<=host_valid&&target_ready&&!FAULT;
endmodule
module bo_shared_reset #(parameter FAULT=0)(input logic clk,rst_n,warm_reset,mailbox_enq,irq_pulse,output logic[1:0]fifo_level,output logic irq_pending);
always @(posedge clk or negedge rst_n)if(!rst_n)begin fifo_level<=0;irq_pending<=0;end
else if(warm_reset)begin if(!FAULT)begin fifo_level<=0;irq_pending<=0;end end
else begin if(mailbox_enq&&fifo_level<3)fifo_level<=fifo_level+1'b1;if(irq_pulse)irq_pending<=1;end
endmodule
module bo_secure_transition #(parameter FAULT=0)(input logic clk,rst_n,switch_secure,policy_approved,output logic secure_mode,reset_loop);
always @(posedge clk or negedge rst_n)if(!rst_n)begin secure_mode<=0;reset_loop<=0;end
else if(switch_secure&&policy_approved)begin secure_mode<=1;reset_loop<=FAULT;end
endmodule
