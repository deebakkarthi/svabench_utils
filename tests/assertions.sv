// keccak
assert property (@(posedge clk) reset |-> ##1 (state == 1'b0));
assert property (@(posedge clk) (is_last && !reset) |-> ##1 (state == 1'b1));
assert property (@(posedge clk) reset |-> ##1 (i == 11'b0));
assert property (@(posedge clk) !reset |-> ##1 (i[10:1] == $past(i[9:0])));
assert property (@(posedge clk) !reset |-> ##1 (i[0] == $past(state & f_ack)));
assert property (@(posedge clk) reset |-> ##1 (out_ready == 1'b0));
assert property (@(posedge clk) (!reset && i[10]) |-> ##1 (out_ready == 1'b1));
assert property (always (is_last == 1'b0) |-> (byte_num == 3'b000));
assert property (always (in_ready == 1'b0) |-> (is_last == 1'b0));
