/*
    Interface Group
        - Protocol agnostic, as long as it's just streams of bytes :)
        - Default in this example:
            - 8x RS232 / UART

    Handles assigning channel baudrates and the channel mux procedure
*/




module interface_group
#(
    parameter D_W = 8,
    parameter SYSCLK_F = 24000000,
    parameter BAUD_CLK_DIV_W = 16;
) (
    input enable,
    input clk,

    input wire  [(D_W - 1):0] ctrl_rx_dat,
    output wire [(D_W - 1):0] ctrl_tx_dat,
    input wire  ctrl_tx_ok_2_ld,
    output reg  ctrl_tx_load,


    input wire  RS232_0_RX,
    output wire RS232_0_TX,
    
    input wire  RS232_1_RX,
    output wire RS232_1_TX,
    
    input wire  RS232_2_RX,
    output wire RS232_2_TX,
    
    input wire  RS232_3_RX,
    output wire RS232_3_TX,
    
    input wire  RS232_4_RX,
    output wire RS232_4_TX,
    
    input wire  RS232_5_RX,
    output wire RS232_5_TX,
    
    input wire  RS232_6_RX,
    output wire RS232_6_TX,

    input wire  RS232_7_RX,
    output wire RS232_7_TX
);


    wire [(D_W - 1):0] dbus0;       // CTRL TX, RS232 RX
    wire [(D_W - 1):0] dbus1;       // CTRL RX, RS232 TX

    localparam PRIORITY_LEVELS = 8;
    localparam PRIO_BUS_W = $clog2(PRIORITY_LEVELS);
    
    localparam NUM_CHANNELS = 8;

    reg [(NUM_CHANNELS - 1):0]ACTIVE_CHAN_BF;
    reg write_2_chan;
    reg read_from_chan;
    
    
    wire [(PRIO_BUS_W - 1):0] prio_0_rx;
    wire [(PRIO_BUS_W - 1):0] prio_0_tx;
    wire [(D_W - 1):0] rs232_ch0_dbus_rx;
    wire [(D_W - 1):0] rs232_ch0_dbus_tx;
    reg  [(BAUD_CLK_DIV_W - 1):0] rs232_ch0_baud_div;
    RS232_Channel #(
        .D_W(D_W),
        .PRIORITY_LEVELS(PRIORITY_LEVELS),
        .SYSCLK_F(SYSCLK_F),
        .MAX_DIV_W(16)
    ) RS232_CH0 (
        .enable(enable),
        .clk(clk),
        .RS232_RX(RS232_0_RX),
        .RS232_TX(RS232_0_TX),
        .chan_active(ACTIVE_CHAN_BF[0]),
        //.errors(),
        //.clear_flags(),
        .priority_rx(prio_0_rx),
        .priority_tx(prio_0_tx),
        .data_in(rs232_ch0_dbus_rx),
        .data_out(rs232_ch0_dbus_tx),
        .commit_write(write_2_chan),
        .commit_read(read_from_chan),
        .channel_baud_div(rs232_ch0_baud_div)
    );

    wire [(PRIO_BUS_W - 1):0] prio_1_rx;
    wire [(PRIO_BUS_W - 1):0] prio_1_tx;
    wire [(D_W - 1):0] rs232_ch1_dbus_rx;
    wire [(D_W - 1):0] rs232_ch1_dbus_tx;
    reg  [(BAUD_CLK_DIV_W - 1):0] rs232_ch1_baud_div;
    RS232_Channel #(
        .D_W(D_W),
        .PRIORITY_LEVELS(PRIORITY_LEVELS),
        .SYSCLK_F(SYSCLK_F),
        .MAX_DIV_W(16)
    ) RS232_CH1 (
        .enable(enable),
        .clk(clk),
        .RS232_RX(RS232_1_RX),
        .RS232_TX(RS232_1_TX),
        .chan_active(ACTIVE_CHAN_BF[1]),
        //.errors(),
        //.clear_flags(),
        .priority_rx(prio_1_rx),
        .priority_tx(prio_1_tx),
        .data_in(rs232_ch1_dbus_rx),
        .data_out(rs232_ch1_dbus_tx),
        .commit_write(write_2_chan),
        .commit_read(read_from_chan),
        .channel_baud_div(rs232_ch1_baud_div)
    );

    wire [(PRIO_BUS_W - 1):0] prio_2_rx;
    wire [(PRIO_BUS_W - 1):0] prio_2_tx;
    wire [(D_W - 1):0] rs232_ch2_dbus_rx;
    wire [(D_W - 1):0] rs232_ch2_dbus_tx;
    reg  [(BAUD_CLK_DIV_W - 1):0] rs232_ch2_baud_div;
    RS232_Channel #(
        .D_W(D_W),
        .PRIORITY_LEVELS(PRIORITY_LEVELS),
        .SYSCLK_F(SYSCLK_F),
        .MAX_DIV_W(16)
    ) RS232_CH2 (
        .enable(enable),
        .clk(clk),
        .RS232_RX(RS232_2_RX),
        .RS232_TX(RS232_2_TX),
        .chan_active(ACTIVE_CHAN_BF[2]),
        //.errors(),
        //.clear_flags(),
        .priority_rx(prio_2_rx),
        .priority_tx(prio_2_tx),
        .data_in(rs232_ch2_dbus_rx),
        .data_out(rs232_ch2_dbus_tx),
        .commit_write(write_2_chan),
        .commit_read(read_from_chan),
        .channel_baud_div(rs232_ch2_baud_div)
    );

    wire [(PRIO_BUS_W - 1):0] prio_3_rx;
    wire [(PRIO_BUS_W - 1):0] prio_3_tx;
    wire [(D_W - 1):0] rs232_ch3_dbus_rx;
    wire [(D_W - 1):0] rs232_ch3_dbus_tx;
    reg  [(BAUD_CLK_DIV_W - 1):0] rs232_ch3_baud_div;
    RS232_Channel #(
        .D_W(D_W),
        .PRIORITY_LEVELS(PRIORITY_LEVELS),
        .SYSCLK_F(SYSCLK_F),
        .MAX_DIV_W(16)
    ) RS232_CH3 (
        .enable(enable),
        .clk(clk),
        .RS232_RX(RS232_3_RX),
        .RS232_TX(RS232_3_TX),
        .chan_active(ACTIVE_CHAN_BF[3]),
        //.errors(),
        //.clear_flags(),
        .priority_rx(prio_3_rx),
        .priority_tx(prio_3_tx),
        .data_in(rs232_ch3_dbus_rx),
        .data_out(rs232_ch3_dbus_tx),
        .commit_write(write_2_chan),
        .commit_read(read_from_chan),
        .channel_baud_div(rs232_ch3_baud_div)
    );

    wire [(PRIO_BUS_W - 1):0] prio_4_rx;
    wire [(PRIO_BUS_W - 1):0] prio_4_tx;
    wire [(D_W - 1):0] rs232_ch4_dbus_rx;
    wire [(D_W - 1):0] rs232_ch4_dbus_tx;
    reg  [(BAUD_CLK_DIV_W - 1):0] rs232_ch4_baud_div;
    RS232_Channel #(
        .D_W(D_W),
        .PRIORITY_LEVELS(PRIORITY_LEVELS),
        .SYSCLK_F(SYSCLK_F),
        .MAX_DIV_W(16)
    ) RS232_CH4 (
        .enable(enable),
        .clk(clk),
        .RS232_RX(RS232_4_RX),
        .RS232_TX(RS232_4_TX),
        .chan_active(ACTIVE_CHAN_BF[4]),
        //.errors(),
        //.clear_flags(),
        .priority_rx(prio_4_rx),
        .priority_tx(prio_4_tx),
        .data_in(rs232_ch4_dbus_rx),
        .data_out(rs232_ch4_dbus_tx),
        .commit_write(write_2_chan),
        .commit_read(read_from_chan),
        .channel_baud_div(rs232_ch4_baud_div)
    );

    wire [(PRIO_BUS_W - 1):0] prio_5_rx;
    wire [(PRIO_BUS_W - 1):0] prio_5_tx;
    wire [(D_W - 1):0] rs232_ch5_dbus_rx;
    wire [(D_W - 1):0] rs232_ch5_dbus_tx;
    reg  [(BAUD_CLK_DIV_W - 1):0] rs232_ch5_baud_div;
    RS232_Channel #(
        .D_W(D_W),
        .PRIORITY_LEVELS(PRIORITY_LEVELS),
        .SYSCLK_F(SYSCLK_F),
        .MAX_DIV_W(16)
    ) RS232_CH5 (
        .enable(enable),
        .clk(clk),
        .RS232_RX(RS232_5_RX),
        .RS232_TX(RS232_5_TX),
        .chan_active(ACTIVE_CHAN_BF[5]),
        //.errors(),
        //.clear_flags(),
        .priority_rx(prio_5_rx),
        .priority_tx(prio_5_tx),
        .data_in(rs232_ch5_dbus_rx),
        .data_out(rs232_ch5_dbus_tx),
        .commit_write(write_2_chan),
        .commit_read(read_from_chan),
        .channel_baud_div(rs232_ch5_baud_div)
    );

    wire [(PRIO_BUS_W - 1):0] prio_6_rx;
    wire [(PRIO_BUS_W - 1):0] prio_6_tx;
    wire [(D_W - 1):0] rs232_ch6_dbus_rx;
    wire [(D_W - 1):0] rs232_ch6_dbus_tx;
    reg  [(BAUD_CLK_DIV_W - 1):0] rs232_ch6_baud_div;
    RS232_Channel #(
        .D_W(D_W),
        .PRIORITY_LEVELS(PRIORITY_LEVELS),
        .SYSCLK_F(SYSCLK_F),
        .MAX_DIV_W(16)
    ) RS232_CH6 (
        .enable(enable),
        .clk(clk),
        .RS232_RX(RS232_6_RX),
        .RS232_TX(RS232_6_TX),
        .chan_active(ACTIVE_CHAN_BF[6]),
        //.errors(),
        //.clear_flags(),
        .priority_rx(prio_6_rx),
        .priority_tx(prio_6_tx),
        .data_in(rs232_ch6_dbus_rx),
        .data_out(rs232_ch6_dbus_tx),
        .commit_write(write_2_chan),
        .commit_read(read_from_chan),
        .channel_baud_div(rs232_ch6_baud_div)
    );

    wire [(PRIO_BUS_W - 1):0] prio_7_rx;
    wire [(PRIO_BUS_W - 1):0] prio_7_tx;
    wire [(D_W - 1):0] rs232_ch7_dbus_rx;
    wire [(D_W - 1):0] rs232_ch7_dbus_tx;
    reg  [(BAUD_CLK_DIV_W - 1):0] rs232_ch7_baud_div;
    RS232_Channel #(
        .D_W(D_W),
        .PRIORITY_LEVELS(PRIORITY_LEVELS),
        .SYSCLK_F(SYSCLK_F),
        .MAX_DIV_W(16)
    ) RS232_CH7 (
        .enable(enable),
        .clk(clk),
        .RS232_RX(RS232_7_RX),
        .RS232_TX(RS232_7_TX),
        .chan_active(ACTIVE_CHAN_BF[7]),
        //.errors(),
        //.clear_flags(),
        .priority_rx(prio_7_rx),
        .priority_tx(prio_7_tx),
        .data_in(rs232_ch7_dbus_rx),
        .data_out(rs232_ch7_dbus_tx),
        .commit_write(write_2_chan),
        .commit_read(read_from_chan),
        .channel_baud_div(rs232_ch7_baud_div)
    );


    initial begin
        write_2_chan        = 0;
        read_from_chan      = 0;

        rs232_ch0_baud_div  = 0;
        rs232_ch1_baud_div  = 0;
        rs232_ch2_baud_div  = 0;
        rs232_ch3_baud_div  = 0;
        rs232_ch4_baud_div  = 0;
        rs232_ch5_baud_div  = 0;
        rs232_ch6_baud_div  = 0;
        rs232_ch7_baud_div  = 0;
    end


endmodule