`timescale 1ns/1ps
// BO-SoC1 Case 07: EDUCATIONAL, FICTIONAL RTL ONLY.
// Single clock; warm_rst_n and periph_rst_n are synchronous active-low reset requests.
// por_n asynchronously asserts; its deassertion must be synchronized upstream.
// DEPTH fixed at 8. No AXI/APB or CDC modeled.
// Simultaneous push/pop are INVALID inputs and must be excluded by integration contract.
module bo_mailbox_fifo_v3 #(
    parameter bit FAULT_INJECTION = 1'b0
)(
    input logic clk,por_n,warm_rst_n,periph_rst_n,
    input logic en_wr,en_val,flush,push,pop,
    input logic [31:0] wr_data,
    output logic [31:0] rd_data,
    output logic [3:0] level,
    output logic empty,full,enabled
);
    localparam integer DEPTH = 8;
    logic [31:0] storage [0:DEPTH-1];
    logic [2:0] read_pointer, write_pointer;
    assign empty = (level == 4'd0);
    assign full  = (level == 4'd8);
    assign rd_data = empty ? 32'h0000_0000 : storage[read_pointer];

    always_ff @(posedge clk or negedge por_n) begin
        if (!por_n) enabled <= 1'b0;
        else if (!warm_rst_n || !periph_rst_n) enabled <= 1'b0;
        else if (en_wr) enabled <= en_val;
    end

    always_ff @(posedge clk or negedge por_n) begin
        if (!por_n) begin
            read_pointer  <= 3'd0;
            write_pointer <= 3'd0;
            level <= 4'd0;
        end else if (!periph_rst_n || flush || (!warm_rst_n && !FAULT_INJECTION)) begin
            read_pointer  <= 3'd0;
            write_pointer <= 3'd0;
            level <= 4'd0;
        end else if (warm_rst_n) begin
            if (enabled && push && !pop && !full) begin
                storage[write_pointer] <= wr_data;
                write_pointer <= write_pointer + 3'd1;
                level <= level + 4'd1;
            end else if (enabled && pop && !push && !empty) begin
                read_pointer <= read_pointer + 3'd1;
                level <= level - 4'd1;
            end
        end
    end
endmodule
