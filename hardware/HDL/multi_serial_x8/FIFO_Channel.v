/*
    Channel Head
    01/28/2024 Joseph A. De Vico
*/

`define CHAN_EMPTY          0       // 0%       full
`define CHAN_LT25_PCT       1       // <25%     full
`define CHAN_25_PCT         2       // 25%      full
`define CHAN_50_PCT         3       // 50%      full
`define CHAN_75_PCT         4       // 75%      full
`define CHAN_925_PCT        5       // 92.5%    full
`define CHAN_FULL           6       // 100%     full
`define CHAN_IDK0           7       // Reserved


/*
    Channel Head

    These modules sit at the interface between the user/primary control
    and the array of RS232 interfaces. This can also be used for GPIB buffering.

    These interfaces are all buffered through 512 byte FIFOs
    A full interface is comprised of 2 channels (TX and RX)

    Each channel has a priority value:
        0       empty
        1       0 < count < 25% full
        2       25% full
        3       50% full
        4       75% full
        5       92.5% full
        6       100% full
        7       RESERVED

    These priorities indicate to the main controller which device should be immediately serviced to
    prevent data loss in both RX and TX cases.
*/
module CHANNEL_HEAD
#(
    parameter DATA_W = 8,
    parameter DATA_CT = 512,
    parameter PRIORITY_LEVELS = 8
)(
    input channel_enable,
    input clk,
    input clear_errors,

    input [(DATA_W - 1):0] channel_data_in,
    input commit_channel_data_in,

    output wire [(DATA_W - 1):0] channel_data_out,
    input commit_channel_data_read,

    output reg [(PRIORITY_W - 1):0] channel_priority,
    output reg write_error,
    output reg read_error
);
    localparam PRIORITY_W = $clog2(PRIORITY_LEVELS);

    localparam DATA_CT_W = $clog2(DATA_CT);
    wire [(DATA_CT_W - 1):0] current_fill_val;
    
    wire fifo_empty;
    wire fifo_full;

    reg write_enable;
    reg read_enable;

    localparam PCT_25_THRESH    =   ({(DATA_CT_W) 1'b1} / 4) - 1;
    localparam PCT_50_THRESH    =   ({(DATA_CT_W) 1'b1} / 2) - 1;
    localparam PCT_75_THRESH    =   (3 * ({(DATA_CT_W) 1'b1} / 4)) - 1;
    localparam PCT_925_THRESH   =   (4 * ({(DATA_CT_W) 1'b1} / 5) + (PCT_25_THRESH / 10)) - 1;
    localparam PCT100_THRESH    =   ({DATA_CT_W}{1'b1});

    wire fill_lt25_pct;
    assign fill_lt25_pct = (current_fill_val < (PCT_25_THRESH + 1)) && (!fifo_empty);

    wire fill_25_pct;
    assign fill_25_pct = current_fill_val > PCT_25_THRESH;

    wire fill_50_pct;
    assign fill_50_pct = current_fill_val > PCT_50_THRESH;

    wire fill_75_pct;
    assign fill_75_pct = current_fill_val > PCT_75_THRESH;

    wire fill_925_pct;
    assign fill_925_pct = current_fill_val > PCT_925_THRESH;



    fifo_512_byte feefifofum
    (
        .en(channel_enable),
        .clk(clk),
        .wr_en(write_enable),
        .wr_data(channel_data_in),
        .rd_en(read_enable),
        .rd_data(channel_data_out),
        .current_fill_ct(current_fill_val),
        .fifo_empty(fifo_empty),
        .fifo_full(fifo_full)
    );

    initial begin
        channel_priority        = CHAN_EMPTY;
        read_error              = 0;
        write_error             = 0;
    end

    always @ (posedge clk) begin
        if(channel_enable) begin
            if(commit_channel_data_read && !fifo_empty) read_enable <= 1;           // NEED TO MAKE THESE RISING DETECT PROBABLY!!!
            else if(commit_channel_data_read && fifo_empty) read_error <= 1;
            else read_enable <= 0;

            if(clear_errors) begin
                read_error  <= 0;
                write_error <= 0;
            end

            if(commit_channel_data_in && !fifo_full) write_enable <= 1;
            else if(commit_channel_data_in && fifo_full) write_error <= 1;
            else write_enable <= 0;


            channel_priority <= {{PRIORITY_W - 1}(1'b0), fill_lt25_pct} + 
                                {{PRIORITY_W - 1}(1'b0), fill_25_pct} + 
                                {{PRIORITY_W - 1}(1'b0), fill_50_pct} +
                                {{PRIORITY_W - 1}(1'b0), fill_75_pct} +
                                {{PRIORITY_W - 1}(1'b0), fill_925_pct} + 
                                {{PRIORITY_W - 1}(1'b0), fifo_full};

        end
    end


endmodule