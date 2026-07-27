module module_i2c_assert #(
    parameter integer DWIDTH = 32,
    parameter integer AWIDTH = 14
) (
    input PCLK,
    input PRESETn,
    input fifo_tx_f_full,
    input fifo_tx_f_empty,
    input [DWIDTH-1:0] fifo_tx_data_out,
    input fifo_rx_f_full,
    input fifo_rx_f_empty,
    input fifo_rx_wr_en,
    input [DWIDTH-1:0] fifo_rx_data_in,
    input [AWIDTH-1:0] DATA_CONFIG_REG,
    input [AWIDTH-1:0] TIMEOUT_TX,
    input fifo_tx_rd_en,
    input TX_EMPTY,
    input RX_EMPTY,
    input ERROR,
    input ENABLE_SDA,
    input ENABLE_SCL,
    input SDA,
    input SCL
);

  // Local parameter definitions mirroring the DUT
  localparam [5:0] IDLE            = 6'd0,
                     START           = 6'd1,
                     CONTROLIN_1     = 6'd2,
                     CONTROLIN_2     = 6'd3,
                     CONTROLIN_3     = 6'd4,
                     CONTROLIN_4     = 6'd5,
                     CONTROLIN_5     = 6'd6,
                     CONTROLIN_6     = 6'd7,
                     CONTROLIN_7     = 6'd8,
                     CONTROLIN_8     = 6'd9,
                     RESPONSE_CIN    = 6'd10,
                     ADDRESS_1       = 6'd11,
                     ADDRESS_2       = 6'd12,
                     ADDRESS_3       = 6'd13,
                     ADDRESS_4       = 6'd14,
                     ADDRESS_5       = 6'd15,
                     ADDRESS_6       = 6'd16,
                     ADDRESS_7       = 6'd17,
                     ADDRESS_8       = 6'd18,
                     RESPONSE_ADDRESS= 6'd19,
                     DATA0_1         = 6'd20,
                     DATA0_2         = 6'd21,
                     DATA0_3         = 6'd22,
                     DATA0_4         = 6'd23,
                     DATA0_5         = 6'd24,
                     DATA0_6         = 6'd25,
                     DATA0_7         = 6'd26,
                     DATA0_8         = 6'd27,
                     RESPONSE_DATA0_1= 6'd28,
                     DATA1_1         = 6'd29,
                     DATA1_2         = 6'd30,
                     DATA1_3         = 6'd31,
                     DATA1_4         = 6'd32,
                     DATA1_5         = 6'd33,
                     DATA1_6         = 6'd34,
                     DATA1_7         = 6'd35,
                     DATA1_8         = 6'd36,
                     RESPONSE_DATA1_1= 6'd37,
                     DELAY_BYTES     = 6'd38,
                     NACK            = 6'd39,
                     STOP            = 6'd40;

  // -------------------------------------------------------------------
  // Output signal correctness
  // -------------------------------------------------------------------

  tx_empty_reflects_fifo :
  assert property (@(posedge PCLK) TX_EMPTY == fifo_tx_f_empty);

  rx_empty_reflects_fifo :
  assert property (@(posedge PCLK) RX_EMPTY == fifo_rx_f_empty);

  error_when_both_config_bits_set :
  assert property (
        @(posedge PCLK)
        (DATA_CONFIG_REG[0] == 1'b1 && DATA_CONFIG_REG[1] == 1'b1) |-> (ERROR == 1'b1)
    );

  no_error_when_config_bits_not_both_set :
  assert property (
        @(posedge PCLK)
        !(DATA_CONFIG_REG[0] == 1'b1 && DATA_CONFIG_REG[1] == 1'b1) |-> (ERROR == 1'b0)
    );

  // -------------------------------------------------------------------
  // Reset behavior - TX state machine
  // -------------------------------------------------------------------

  tx_state_reset_to_idle :
  assert property (@(posedge PCLK) $fell(PRESETn) |=> (module_i2c.state_tx == IDLE));

  tx_count_send_data_reset :
  assert property (@(posedge PCLK) $fell(PRESETn) |=> (module_i2c.count_send_data == 12'd0));

  tx_count_tx_reset :
  assert property (@(posedge PCLK) $fell(PRESETn) |=> (module_i2c.count_tx == 2'd0));

  tx_fifo_rd_en_deasserted_on_reset :
  assert property (@(posedge PCLK) $fell(PRESETn) |=> (fifo_tx_rd_en == 1'b0));

  tx_br_clk_high_on_reset :
  assert property (@(posedge PCLK) $fell(PRESETn) |=> (module_i2c.BR_CLK_O == 1'b1));

  // -------------------------------------------------------------------
  // Reset behavior - RX state machine
  // -------------------------------------------------------------------

  rx_state_reset_to_idle :
  assert property (@(posedge PCLK) $fell(PRESETn) |=> (module_i2c.state_rx == IDLE));

  rx_count_receive_data_reset :
  assert property (@(posedge PCLK) $fell(PRESETn) |=> (module_i2c.count_receive_data == 12'd0));

  rx_count_rx_reset :
  assert property (@(posedge PCLK) $fell(PRESETn) |=> (module_i2c.count_rx == 2'd0));

  rx_fifo_wr_en_deasserted_on_reset :
  assert property (@(posedge PCLK) $fell(PRESETn) |=> (fifo_rx_wr_en == 1'b0));

  rx_br_clk_low_on_reset :
  assert property (@(posedge PCLK) $fell(PRESETn) |=> (module_i2c.BR_CLK_O_RX == 1'b0));

  // -------------------------------------------------------------------
  // Timeout counter reset on reset
  // -------------------------------------------------------------------

  timeout_counter_reset :
  assert property (@(posedge PCLK) $fell(PRESETn) |=> (module_i2c.count_timeout == 12'd0));

  // -------------------------------------------------------------------
  // TX FSM valid state encoding
  // -------------------------------------------------------------------

  tx_state_valid_encoding :
  assert property (@(posedge PCLK) disable iff (!PRESETn) (module_i2c.state_tx <= STOP));

  // -------------------------------------------------------------------
  // RX FSM valid state encoding
  // -------------------------------------------------------------------

  rx_state_valid_encoding :
  assert property (@(posedge PCLK) disable iff (!PRESETn) (module_i2c.state_rx <= STOP));

  // -------------------------------------------------------------------
  // TX FSM: START only reachable from IDLE
  // -------------------------------------------------------------------

  tx_start_only_from_idle :
  assert property (@(posedge PCLK) disable iff (!PRESETn) (module_i2c.state_tx == START) |-> $past(
      module_i2c.state_tx == IDLE || module_i2c.state_tx == START
  ));

  // -------------------------------------------------------------------
  // TX FSM: STOP transitions back to IDLE
  // -------------------------------------------------------------------

  tx_stop_transitions_to_idle :
  assert property (
        @(posedge PCLK) disable iff (!PRESETn)
        (module_i2c.state_tx == STOP && module_i2c.count_send_data == DATA_CONFIG_REG[13:2])
        |=> (module_i2c.state_tx == IDLE)
    );

  // -------------------------------------------------------------------
  // RX FSM: STOP transitions back to IDLE
  // -------------------------------------------------------------------

  rx_stop_transitions_to_idle :
  assert property (
        @(posedge PCLK) disable iff (!PRESETn)
        (module_i2c.state_rx == STOP && module_i2c.count_receive_data == DATA_CONFIG_REG[13:2])
        |=> (module_i2c.state_rx == IDLE)
    );

  // -------------------------------------------------------------------
  // TX FSM: IDLE stays IDLE when config bit 0 is deasserted
  // -------------------------------------------------------------------

  tx_idle_stays_idle_when_disabled :
  assert property (
        @(posedge PCLK) disable iff (!PRESETn)
        (module_i2c.state_tx == IDLE && DATA_CONFIG_REG[0] == 1'b0 &&
         DATA_CONFIG_REG[1] == 1'b0 &&
         (fifo_tx_f_full == 1'b1 || fifo_tx_f_empty == 1'b0))
        |=> (module_i2c.state_tx == IDLE)
    );

  // -------------------------------------------------------------------
  // TX FSM: error config keeps FSM in IDLE
  // -------------------------------------------------------------------

  tx_idle_stays_idle_when_error_config :
  assert property (
        @(posedge PCLK) disable iff (!PRESETn)
        (module_i2c.state_tx == IDLE && DATA_CONFIG_REG[0] == 1'b1 &&
         DATA_CONFIG_REG[1] == 1'b1 &&
         (fifo_tx_f_full == 1'b1 || fifo_tx_f_empty == 1'b0))
        |=> (module_i2c.state_tx == IDLE)
    );

  // -------------------------------------------------------------------
  // TX FSM: CONTROLIN sequence is monotonically ordered
  // -------------------------------------------------------------------

  tx_controlin1_to_2 :
  assert property (
        @(posedge PCLK) disable iff (!PRESETn)
        (module_i2c.state_tx == CONTROLIN_1 && module_i2c.count_send_data == DATA_CONFIG_REG[13:2])
        |=> (module_i2c.state_tx == CONTROLIN_2)
    );

  tx_controlin2_to_3 :
  assert property (
        @(posedge PCLK) disable iff (!PRESETn)
        (module_i2c.state_tx == CONTROLIN_2 && module_i2c.count_send_data == DATA_CONFIG_REG[13:2])
        |=> (module_i2c.state_tx == CONTROLIN_3)
    );

  tx_controlin3_to_4 :
  assert property (
        @(posedge PCLK) disable iff (!PRESETn)
        (module_i2c.state_tx == CONTROLIN_3 && module_i2c.count_send_data == DATA_CONFIG_REG[13:2])
        |=> (module_i2c.state_tx == CONTROLIN_4)
    );

  tx_controlin4_to_5 :
  assert property (
        @(posedge PCLK) disable iff (!PRESETn)
        (module_i2c.state_tx == CONTROLIN_4 && module_i2c.count_send_data == DATA_CONFIG_REG[13:2])
        |=> (module_i2c.state_tx == CONTROLIN_5)
    );

  tx_controlin5_to_6 :
  assert property (
        @(posedge PCLK) disable iff (!PRESETn)
        (module_i2c.state_tx == CONTROLIN_5 && module_i2c.count_send_data == DATA_CONFIG_REG[13:2])
        |=> (module_i2c.state_tx == CONTROLIN_6)
    );

  tx_controlin6_to_7 :
  assert property (
        @(posedge PCLK) disable iff (!PRESETn)
        (module_i2c.state_tx == CONTROLIN_6 && module_i2c.count_send_data == DATA_CONFIG_REG[13:2])
        |=> (module_i2c.state_tx == CONTROLIN_7)
    );

  tx_controlin7_to_8 :
  assert property (
        @(posedge PCLK) disable iff (!PRESETn)
        (module_i2c.state_tx == CONTROLIN_7 && module_i2c.count_send_data == DATA_CONFIG_REG[13:2])
        |=> (module_i2c.state_tx == CONTROLIN_8)
    );

  tx_controlin8_to_response_cin :
  assert property (
        @(posedge PCLK) disable iff (!PRESETn)
        (module_i2c.state_tx == CONTROLIN_8 && module_i2c.count_send_data == DATA_CONFIG_REG[13:2])
        |=> (module_i2c.state_tx == RESPONSE_CIN)
    );

  // -------------------------------------------------------------------
  // TX FSM: ADDRESS sequence ordering
  // -------------------------------------------------------------------

  tx_address1_to_2 :
  assert property (
        @(posedge PCLK) disable iff (!PRESETn)
        (module_i2c.state_tx == ADDRESS_1 && module_i2c.count_send_data == DATA_CONFIG_REG[13:2])
        |=> (module_i2c.state_tx == ADDRESS_2)
    );

  tx_address8_to_response_address :
  assert property (
        @(posedge PCLK) disable iff (!PRESETn)
        (module_i2c.state_tx == ADDRESS_8 && module_i2c.count_send_data == DATA_CONFIG_REG[13:2])
        |=> (module_i2c.state_tx == RESPONSE_ADDRESS)
    );

  // -------------------------------------------------------------------
  // TX FSM: RESPONSE_CIN ACK leads to DELAY_BYTES
  // -------------------------------------------------------------------

  tx_response_cin_ack_to_delay :
  assert property (
        @(posedge PCLK) disable iff (!PRESETn)
        (module_i2c.state_tx == RESPONSE_CIN &&
         module_i2c.count_send_data == DATA_CONFIG_REG[13:2] &&
         module_i2c.RESPONSE == 1'b0)
        |=> (module_i2c.state_tx == DELAY_BYTES)
    );

  // -------------------------------------------------------------------
  // TX FSM: RESPONSE_CIN NACK leads to NACK state
  // -------------------------------------------------------------------

  tx_response_cin_nack_to_nack :
  assert property (
        @(posedge PCLK) disable iff (!PRESETn)
        (module_i2c.state_tx == RESPONSE_CIN &&
         module_i2c.count_send_data == DATA_CONFIG_REG[13:2] &&
         module_i2c.RESPONSE == 1'b1)
        |=> (module_i2c.state_tx == NACK)
    );

  // -------------------------------------------------------------------
  // TX FSM: RESPONSE_ADDRESS ACK leads to DELAY_BYTES
  // -------------------------------------------------------------------

  tx_response_address_ack_to_delay :
  assert property (
        @(posedge PCLK) disable iff (!PRESETn)
        (module_i2c.state_tx == RESPONSE_ADDRESS &&
         module_i2c.count_send_data == DATA_CONFIG_REG[13:2] &&
         module_i2c.RESPONSE == 1'b0)
        |=> (module_i2c.state_tx == DELAY_BYTES)
    );

  // -------------------------------------------------------------------
  // TX FSM: DATA0 sequence ordering
  // -------------------------------------------------------------------

  tx_data0_8_to_response_data0 :
  assert property (
        @(posedge PCLK) disable iff (!PRESETn)
        (module_i2c.state_tx == DATA0_8 && module_i2c.count_send_data == DATA_CONFIG_REG[13:2])
        |=> (module_i2c.state_tx == RESPONSE_DATA0_1)
    );

  // -------------------------------------------------------------------
  // TX FSM: DATA1 sequence ordering
  // -------------------------------------------------------------------

  tx_data1_8_to_response_data1 :
  assert property (
        @(posedge PCLK) disable iff (!PRESETn)
        (module_i2c.state_tx == DATA1_8 && module_i2c.count_send_data == DATA_CONFIG_REG[13:2])
        |=> (module_i2c.state_tx == RESPONSE_DATA1_1)
    );

  // -------------------------------------------------------------------
  // TX FSM: DELAY_BYTES with count_tx==3 goes to STOP
  // -------------------------------------------------------------------

  tx_delay_bytes_count3_to_stop :
  assert property (
        @(posedge PCLK) disable iff (!PRESETn)
        (module_i2c.state_tx == DELAY_BYTES &&
         module_i2c.count_send_data == DATA_CONFIG_REG[13:2] &&
         module_i2c.count_tx == 2'd3)
        |=> (module_i2c.state_tx == STOP)
    );

  // -------------------------------------------------------------------
  // TX FSM: DELAY_BYTES with count_tx==0 goes to ADDRESS_1
  // -------------------------------------------------------------------

  tx_delay_bytes_count0_to_address1 :
  assert property (
        @(posedge PCLK) disable iff (!PRESETn)
        (module_i2c.state_tx == DELAY_BYTES &&
         module_i2c.count_send_data == DATA_CONFIG_REG[13:2] &&
         module_i2c.count_tx == 2'd0)
        |=> (module_i2c.state_tx == ADDRESS_1)
    );

  // -------------------------------------------------------------------
  // TX FSM: DELAY_BYTES with count_tx==1 goes to DATA0_1
  // -------------------------------------------------------------------

  tx_delay_bytes_count1_to_data0_1 :
  assert property (
        @(posedge PCLK) disable iff (!PRESETn)
        (module_i2c.state_tx == DELAY_BYTES &&
         module_i2c.count_send_data == DATA_CONFIG_REG[13:2] &&
         module_i2c.count_tx == 2'd1)
        |=> (module_i2c.state_tx == DATA0_1)
    );

  // -------------------------------------------------------------------
  // TX FSM: DELAY_BYTES with count_tx==2 goes to DATA1_1
  // -------------------------------------------------------------------

  tx_delay_bytes_count2_to_data1_1 :
  assert property (
        @(posedge PCLK) disable iff (!PRESETn)
        (module_i2c.state_tx == DELAY_BYTES &&
         module_i2c.count_send_data == DATA_CONFIG_REG[13:2] &&
         module_i2c.count_tx == 2'd2)
        |=> (module_i2c.state_tx == DATA1_1)
    );

  // -------------------------------------------------------------------
  // RX FSM: IDLE stays IDLE when both config bits clear
  // -------------------------------------------------------------------

  rx_idle_stays_idle_when_both_config_clear :
  assert property (
        @(posedge PCLK) disable iff (!PRESETn)
        (module_i2c.state_rx == IDLE &&
         DATA_CONFIG_REG[0] == 1'b0 && DATA_CONFIG_REG[1] == 1'b0)
        |=> (module_i2c.state_rx == IDLE)
    );

  // -------------------------------------------------------------------
  // RX FSM: CONTROLIN sequence ordering
  // -------------------------------------------------------------------

  rx_controlin1_to_2 :
  assert property (
        @(posedge PCLK) disable iff (!PRESETn)
        (module_i2c.state_rx == CONTROLIN_1 && module_i2c.count_receive_data == DATA_CONFIG_REG[13:2])
        |=> (module_i2c.state_rx == CONTROLIN_2)
    );

  rx_controlin8_to_response_cin :
  assert property (
        @(posedge PCLK) disable iff (!PRESETn)
        (module_i2c.state_rx == CONTROLIN_8 && module_i2c.count_receive_data == DATA_CONFIG_REG[13:2])
        |=> (module_i2c.state_rx == RESPONSE_CIN)
    );

  // -------------------------------------------------------------------
  // RX FSM: ADDRESS sequence ordering
  // -------------------------------------------------------------------

  rx_address8_to_response_address :
  assert property (
        @(posedge PCLK) disable iff (!PRESETn)
        (module_i2c.state_rx == ADDRESS_8 && module_i2c.count_receive_data == DATA_CONFIG_REG[13:2])
        |=> (module_i2c.state_rx == RESPONSE_ADDRESS)
    );

  // -------------------------------------------------------------------
  // RX FSM: DATA0 sequence ordering
  // -------------------------------------------------------------------

  rx_data0_8_to_response_data0 :
  assert property (
        @(posedge PCLK) disable iff (!PRESETn)
        (module_i2c.state_rx == DATA0_8 && module_i2c.count_receive_data == DATA_CONFIG_REG[13:2])
        |=> (module_i2c.state_rx == RESPONSE_DATA0_1)
    );

  // -------------------------------------------------------------------
  // RX FSM: DATA1 sequence ordering
  // -------------------------------------------------------------------

  rx_data1_8_to_response_data1 :
  assert property (
        @(posedge PCLK) disable iff (!PRESETn)
        (module_i2c.state_rx == DATA1_8 && module_i2c.count_receive_data == DATA_CONFIG_REG[13:2])
        |=> (module_i2c.state_rx == RESPONSE_DATA1_1)
    );

  // -------------------------------------------------------------------
  // RX FSM: DELAY_BYTES count_rx==3 goes to STOP
  // -------------------------------------------------------------------

  rx_delay_bytes_count3_to_stop :
  assert property (
        @(posedge PCLK) disable iff (!PRESETn)
        (module_i2c.state_rx == DELAY_BYTES &&
         module_i2c.count_receive_data == DATA_CONFIG_REG[13:2] &&
         module_i2c.count_rx == 2'd3)
        |=> (module_i2c.state_rx == STOP)
    );

  // -------------------------------------------------------------------
  // ENABLE_SDA is high in TX response states (slave drives SDA)
  // -------------------------------------------------------------------

  enable_sda_low_in_tx_response_states :
  assert property (
        @(posedge PCLK) disable iff (!PRESETn)
        (module_i2c.state_rx != RESPONSE_CIN &&
         module_i2c.state_rx != RESPONSE_ADDRESS &&
         module_i2c.state_rx != RESPONSE_DATA0_1 &&
         module_i2c.state_rx != RESPONSE_DATA1_1 &&
         (module_i2c.state_tx == RESPONSE_CIN ||
          module_i2c.state_tx == RESPONSE_ADDRESS ||
          module_i2c.state_tx == RESPONSE_DATA0_1 ||
          module_i2c.state_tx == RESPONSE_DATA1_1))
        |-> (ENABLE_SDA == 1'b0)
    );

  // -------------------------------------------------------------------
  // ENABLE_SDA is high in RX response states
  // -------------------------------------------------------------------

  enable_sda_high_in_rx_response_states :
  assert property (
        @(posedge PCLK) disable iff (!PRESETn)
        (module_i2c.state_rx == RESPONSE_CIN ||
         module_i2c.state_rx == RESPONSE_ADDRESS ||
         module_i2c.state_rx == RESPONSE_DATA0_1 ||
         module_i2c.state_rx == RESPONSE_DATA1_1)
        |-> (ENABLE_SDA == 1'b1)
    );

  // -------------------------------------------------------------------
  // ENABLE_SCL is high in TX response states
  // -------------------------------------------------------------------

  enable_scl_high_in_tx_response_states :
  assert property (
        @(posedge PCLK) disable iff (!PRESETn)
        (module_i2c.state_rx != RESPONSE_CIN &&
         module_i2c.state_rx != RESPONSE_ADDRESS &&
         module_i2c.state_rx != RESPONSE_DATA0_1 &&
         module_i2c.state_rx != RESPONSE_DATA1_1 &&
         (module_i2c.state_tx == RESPONSE_CIN ||
          module_i2c.state_tx == RESPONSE_ADDRESS ||
          module_i2c.state_tx == RESPONSE_DATA0_1 ||
          module_i2c.state_tx == RESPONSE_DATA1_1))
        |-> (ENABLE_SCL == 1'b1)
    );

  // -------------------------------------------------------------------
  // ENABLE_SCL is high in RX response states
  // -------------------------------------------------------------------

  enable_scl_high_in_rx_response_states :
  assert property (
        @(posedge PCLK) disable iff (!PRESETn)
        (module_i2c.state_rx == RESPONSE_CIN ||
         module_i2c.state_rx == RESPONSE_ADDRESS ||
         module_i2c.state_rx == RESPONSE_DATA0_1 ||
         module_i2c.state_rx == RESPONSE_DATA1_1)
        |-> (ENABLE_SCL == 1'b1)
    );

  // -------------------------------------------------------------------
  // count_send_data does not exceed its max value on normal operation
  // -------------------------------------------------------------------

  count_send_data_bounded :
  assert property (@(posedge PCLK) disable iff (!PRESETn) module_i2c.count_send_data <= 12'd4095);

  // -------------------------------------------------------------------
  // count_receive_data does not exceed its max value on normal operation
  // -------------------------------------------------------------------

  count_receive_data_bounded :
  assert property (
        @(posedge PCLK) disable iff (!PRESETn)
        module_i2c.count_receive_data <= 12'd4095
    );

  // -------------------------------------------------------------------
  // count_tx should be within valid range (0 to 3)
  // -------------------------------------------------------------------

  count_tx_valid_range :
  assert property (@(posedge PCLK) disable iff (!PRESETn) module_i2c.count_tx <= 2'd3);

  // -------------------------------------------------------------------
  // count_rx should be within valid range (0 to 3)
  // -------------------------------------------------------------------

  count_rx_valid_range :
  assert property (@(posedge PCLK) disable iff (!PRESETn) module_i2c.count_rx <= 2'd3);

  // -------------------------------------------------------------------
  // TX FSM: fifo_tx_rd_en deasserted in IDLE
  // -------------------------------------------------------------------

  fifo_tx_rd_en_low_in_idle :
  assert property (
        @(posedge PCLK) disable iff (!PRESETn)
        (module_i2c.state_tx == IDLE) |-> (fifo_tx_rd_en == 1'b0)
    );

  // -------------------------------------------------------------------
  // TX FSM: fifo_tx_rd_en deasserted in DELAY_BYTES
  // -------------------------------------------------------------------

  fifo_tx_rd_en_low_in_delay_bytes :
  assert property (
        @(posedge PCLK) disable iff (!PRESETn)
        (module_i2c.state_tx == DELAY_BYTES) |-> (fifo_tx_rd_en == 1'b0)
    );

  // -------------------------------------------------------------------
  // RX FSM: fifo_rx_wr_en deasserted in STOP
  // -------------------------------------------------------------------

  fifo_rx_wr_en_low_in_stop :
  assert property (
        @(posedge PCLK) disable iff (!PRESETn)
        (module_i2c.state_rx == STOP) |-> (fifo_rx_wr_en == 1'b0)
    );

  // -------------------------------------------------------------------
  // TX FSM: START state only entered when config reg bit0=1, bit1=0
  // -------------------------------------------------------------------

  tx_start_requires_proper_config :
  assert property (@(posedge PCLK) disable iff (!PRESETn) $rose(
      module_i2c.state_tx == START
  ) |-> $past(
      DATA_CONFIG_REG[0] == 1'b1 && DATA_CONFIG_REG[1] == 1'b0
  ));

  // -------------------------------------------------------------------
  // TX FSM: START state entered only when TX FIFO has data
  // -------------------------------------------------------------------

  tx_start_requires_fifo_data :
  assert property (@(posedge PCLK) disable iff (!PRESETn) $rose(
      module_i2c.state_tx == START
  ) |-> $past(
      fifo_tx_f_full == 1'b1 || fifo_tx_f_empty == 1'b0
  ));

  // -------------------------------------------------------------------
  // count_send_data increments by 1 each clock in non-terminal condition
  // -------------------------------------------------------------------

  count_send_data_increments :
  assert property (
        @(posedge PCLK) disable iff (!PRESETn)
        (module_i2c.state_tx != IDLE && module_i2c.state_tx != NACK &&
         module_i2c.count_send_data < DATA_CONFIG_REG[13:2])
        |=> (module_i2c.count_send_data == $past(
      module_i2c.count_send_data
  ) + 12'd1 || module_i2c.count_send_data == 12'd0));

  // -------------------------------------------------------------------
  // count_receive_data increments by 1 each clock in non-terminal condition
  // -------------------------------------------------------------------

  count_receive_data_increments :
  assert property (
        @(posedge PCLK) disable iff (!PRESETn)
        (module_i2c.state_rx != IDLE &&
         module_i2c.count_receive_data < DATA_CONFIG_REG[13:2])
        |=> (module_i2c.count_receive_data == $past(
      module_i2c.count_receive_data
  ) + 12'd1 || module_i2c.count_receive_data == 12'd0));

  // -------------------------------------------------------------------
  // TX FSM state stays same while count_send_data has not reached threshold
  // (spot check on one state)
  // -------------------------------------------------------------------

  tx_state_stable_while_counting_start :
  assert property (
        @(posedge PCLK) disable iff (!PRESETn)
        (module_i2c.state_tx == START &&
         module_i2c.count_send_data != DATA_CONFIG_REG[13:2])
        |=> (module_i2c.state_tx == START)
    );

  tx_state_stable_while_counting_controlin1 :
  assert property (
        @(posedge PCLK) disable iff (!PRESETn)
        (module_i2c.state_tx == CONTROLIN_1 &&
         module_i2c.count_send_data != DATA_CONFIG_REG[13:2])
        |=> (module_i2c.state_tx == CONTROLIN_1)
    );

  tx_state_stable_while_counting_stop :
  assert property (
        @(posedge PCLK) disable iff (!PRESETn)
        (module_i2c.state_tx == STOP &&
         module_i2c.count_send_data != DATA_CONFIG_REG[13:2])
        |=> (module_i2c.state_tx == STOP)
    );

  // -------------------------------------------------------------------
  // RX FSM state stable while counting (spot check)
  // -------------------------------------------------------------------

  rx_state_stable_while_counting_start :
  assert property (
        @(posedge PCLK) disable iff (!PRESETn)
        (module_i2c.state_rx == START &&
         module_i2c.count_receive_data != DATA_CONFIG_REG[13:2])
        |=> (module_i2c.state_rx == START)
    );

  rx_state_stable_while_counting_stop :
  assert property (
        @(posedge PCLK) disable iff (!PRESETn)
        (module_i2c.state_rx == STOP &&
         module_i2c.count_receive_data != DATA_CONFIG_REG[13:2])
        |=> (module_i2c.state_rx == STOP)
    );

  // -------------------------------------------------------------------
  // TX FSM: BR_CLK_O should be 1 at reset
  // -------------------------------------------------------------------

  tx_br_clk_high_at_reset_deassert :
  assert property (@(posedge PCLK) (!PRESETn) |-> ##1 (module_i2c.BR_CLK_O == 1'b1));

  // -------------------------------------------------------------------
  // TX FSM: SDA_OUT high at reset
  // -------------------------------------------------------------------

  tx_sda_out_high_at_reset :
  assert property (@(posedge PCLK) (!PRESETn) |-> ##1 (module_i2c.SDA_OUT == 1'b1));

  // -------------------------------------------------------------------
  // Timeout counter only increments in IDLE with SDA and SCL both low
  // -------------------------------------------------------------------

  timeout_counter_increments_only_in_idle :
  assert property (
        @(posedge PCLK) disable iff (!PRESETn)
        (module_i2c.state_tx != IDLE) |=>
        (module_i2c.count_timeout == 12'd0)
    );

  // -------------------------------------------------------------------
  // TX FSM: START state transition from IDLE requires timeout not exceeded
  // -------------------------------------------------------------------

  tx_idle_to_start_timeout_not_exceeded :
  assert property (
        @(posedge PCLK) disable iff (!PRESETn)
        (module_i2c.state_tx == IDLE && DATA_CONFIG_REG[0] == 1'b1 &&
         DATA_CONFIG_REG[1] == 1'b0 &&
         (fifo_tx_f_full == 1'b1 || (fifo_tx_f_empty == 1'b0 && fifo_tx_f_full == 1'b0)) &&
         module_i2c.count_timeout < TIMEOUT_TX)
        |=> (module_i2c.state_tx == START)
    );

endmodule

bind module_i2c module_i2c_assert module_i2c_assert_instance (.*);
