/*
    RS232 Standard Channel for MUXing Purposes
    01/28/2024 - Joseph A. De Vico
*/




module RS232_Channel
#(
    D_W = 8,
    PRIORITY_LEVELS = 8,
    SYSCLK_F = 24000000
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
    input wire commit_read
);
    localparam PRIO_W = $clog2(PRIORITY_LEVELS);

    wire tx_rd_err;
    wire tx_wr_err;
    wire rx_rd_err;
    wire rx_wr_err;

    assign errors = {tx_rd_err, tx_wr_err, rx_rd_err, rx_wr_err};


    // TX Channel
    CHANNEL_HEAD #(
        .DATA_W(D_W),
        .PRIORITY_LEVELS(PRIORITY_LEVELS)
    ) TX_CHANNEL (
        .channel_enable(enable),
        .clk(clk),
        .clear_errors(clear_flags),
        .channel_data_in(data_in),
        .commit_channel_data_in(commit_write),
        .channel_data_out(),
        .commit_channel_data_read(),
        .write_error(tx_wr_err),
        .read_error(tx_rd_err)
    );

    // RX Channel
    CHANNEL_HEAD #(
        .DATA_W(D_W),
        .PRIORITY_LEVELS(PRIORITY_LEVELS)
    ) RX_CHANNEL (
        .channel_enable(enable),
        .clk(clk),
        .clear_errors(clear_flags),
        .channel_data_in(),
        .commit_channel_data_in(),
        .channel_data_out(data_out),
        .commit_channel_data_read(commit_read),
        .write_error(rx_wr_err),
        .read_error(rx_rd_err)
    );

/*
module uart_controller
#(
    parameter SYSCLK_FREQ = 24000000,
    parameter BYTE_W = 8,
    parameter DIV_W = 16
)
(
    input enable,
    input sys_clk,

    // RX
    input wire RX_LINE,
    output wire [(BYTE_W - 1):0]RX_DATA,
    output wire RX_DATA_READY,


    // TX
    input wire [(BYTE_W - 1):0]TX_DATA,
    input wire TX_LOAD,
    output wire TX_LOAD_OKAY,
    output wire TX_LINE,

    // Parametric Divider
    input [(DIV_W - 1):0] CLKS_PER_BIT
);
*/
    uart_controller #(
        .SYSCLK_F(SYSCLK_F),
        .BYTE_W(D_W),
        .DIV_W(16)
    ) channel_uart (
        .enable(enable),
        .sys_clk(clk),

        // RX
        .RX_LINE(),
        .RX_DATA(),
        .RX_DATA_READY(),

        // TX
        .TX_DATA(),
        .TX_LOAD(),
        .TX_LOAD_OKAY(),
        .TX_LINE(),

        .CLKS_PER_BIT()
    );


endmodule