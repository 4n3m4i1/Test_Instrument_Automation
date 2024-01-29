/*
    RS232 Standard Channel for MUXing Purposes
    01/28/2024 - Joseph A. De Vico
*/




module RS232_Channel
#(
    D_W = 8,
    PRIORITY_LEVELS = 8,
    SYSCLK_F = 24000000,
    MAX_DIV_W = 16
) (
    // Internal Controls
    input enable,
    input clk,

    // Pins
    // RX and TX Given from FPGA perspective
    input RS232_RX,
    output RS232_TX,

    // Internal Bux MUX Interface
    input wire  chan_active,
    output wire [3:0] errors,
    input wire  clear_flags,
    output wire [(PRIO_W - 1):0] priority_rx,
    output wire [(PRIO_W - 1):0] priority_tx,
    input wire  [(D_W - 1):0] data_in,
    output wire [(D_W - 1):0] data_out,

    input wire commit_write,
    input wire commit_read,

    input wire [(MAX_DIV_W - 1):0] channel_baud_div
);
    localparam PRIO_W = $clog2(PRIORITY_LEVELS);

    wire tx_rd_err;
    wire tx_wr_err;
    wire rx_rd_err;
    wire rx_wr_err;

    assign errors = {tx_rd_err, tx_wr_err, rx_rd_err, rx_wr_err};

    reg [(MAX_DIV_W - 1):0] baud_div_pipeline;
    wire baud_div_present;
    assign baud_div_present = |baud_div_pipeline;

    // TX Channel
    wire [(D_W - 1):0] ua_tx_dat_from_fifo;
    reg     commit_2_read;
    reg     ua_tx_ld;
    wire    ua_tx_okay_2_ld;
    CHANNEL_HEAD #(
        .DATA_W(D_W),
        .PRIORITY_LEVELS(PRIORITY_LEVELS)
    ) TX_CHANNEL (
        .channel_enable(enable),
        .clk(clk),
        .clear_errors(clear_flags && chan_active),
        .channel_data_in(data_in),
        .commit_channel_data_in(commit_write && chan_active),
        .channel_data_out(ua_tx_dat_from_fifo),
        .commit_channel_data_read(commit_2_read && chan_active),
        .channel_priority(priority_tx),
        .write_error(tx_wr_err),
        .read_error(tx_rd_err)
    );

    // RX Channel
    wire [(D_W - 1):0] ua_rx_dat_2_fifo;
    wire ua_rx_commit;
    CHANNEL_HEAD #(
        .DATA_W(D_W),
        .PRIORITY_LEVELS(PRIORITY_LEVELS)
    ) RX_CHANNEL (
        .channel_enable(enable),
        .clk(clk),
        .clear_errors(clear_flags && chan_active),
        .channel_data_in(ua_rx_dat_2_fifo),
        .commit_channel_data_in(ua_rx_commit && chan_active),
        .channel_data_out(data_out),
        .commit_channel_data_read(commit_read && chan_active),
        .channel_priority(priority_rx),
        .write_error(rx_wr_err),
        .read_error(rx_rd_err)
    );


    uart_controller #(
        .SYSCLK_F(SYSCLK_F),
        .BYTE_W(D_W),
        .DIV_W(MAX_DIV_W)
    ) channel_uart (
        .enable(enable && baud_div_present),
        .sys_clk(clk),

        // RX
        .RX_LINE(RS232_RX),
        .RX_DATA(ua_rx_dat_2_fifo),
        .RX_DATA_READY(ua_rx_commit),

        // TX
        .TX_DATA(ua_tx_dat_from_fifo),
        .TX_LOAD(ua_tx_ld),
        .TX_LOAD_OKAY(ua_tx_okay_2_ld),
        .TX_LINE(RS232_TX),

        .CLKS_PER_BIT(baud_div_pipeline)
    );

    reg [1:0] oa_state;

    initial begin
        baud_val_pipeline = 0;
        ua_tx_ld = 0;
        commit_2_read = 0;
    end

    always @ (posedge clk) begin
        if(enable) baud_val_pipeline <= channel_baud_div;
    end

    always @ (posedge clk) begin
        if(enable) begin
            case (oa_state)
                0: begin
                    if(TX_LOAD_OKAY && |priority_tx) begin
                        commit_2_read   <= 1;
                        oa_state        <= 1;
                    end
                end
                1: begin
                    commit_2_read       <= 0;
                    ua_tx_ld            <= 1;
                    oa_state            <= 2;
                end
                2: begin
                    ua_tx_ld            <= 0;
                    oa_state            <= 0;
                end
            endcase
        end
        else begin
            ua_tx_ld        <= 0;
            commit_2_read   <= 0;
        end
    end

endmodule