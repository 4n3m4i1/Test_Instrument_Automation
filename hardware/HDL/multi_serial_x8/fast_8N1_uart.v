/*
    Note 01/28/2024 Code used from my own test repository
        Modified 01/28/2024 for variable baudrate settings

    This is a single file UART that's easy to implement in
    portable project that don't need includes.

    Wrapper function or individual modules can be used.

    7/5/2023
*/


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
    input wire [(DIV_W - 1):0] CLKS_PER_BIT
);


    fast_8N1_UART_RX_
    #(
        .SYSCLK_F(SYSCLK_FREQ),
        .DIV_W(DIV_W)
    ) receiver__ (
        .sys_clk(sys_clk),
        .en(enable),
        .CYC_PER_BIT(CLKS_PER_BIT),
        .RX_LINE(RX_LINE),
        .DATA(RX_DATA),
        .DATA_RDY_STROBE(RX_DATA_READY)
    );


    fast_8N1_UART_TX_
    #(
        .SYSCLK_F(SYSCLK_FREQ),
        .DIV_W(DIV_W)
    ) transmitter__ (
        .sys_clk(sys_clk),
        .en(enable),
        .CYC_PER_BIT(CLKS_PER_BIT),
        .TX_LOAD(TX_LOAD),
        .TX_DATA(TX_DATA),
        .LOAD_OK(TX_LOAD_OKAY),
        .TX_LINE(TX_LINE)
    );
endmodule



///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
//      RX
///////////////////////////////////////////////////////////////////////////////
module fast_8N1_UART_RX_
#(
    parameter SYSCLK_F = 24000000,
    parameter BYTE_W = 8,
    parameter DIV_W = 16
)
(
    input sys_clk,
    //input rst,
    input en,

    input [(DIV_W - 1):0] CYC_PER_BIT,

    input RX_LINE,

    output reg [(BYTE_W - 1):0]DATA,

    output reg DATA_RDY_STROBE
);

    // Setup Clock Parameters
    //localparam CYC_PER_BIT      = SYSCLK_F / BAUDRATE;      // cycles per bit
    //localparam START_BIT_OFFSET = 3 * (CYC_PER_BIT / 2);       // cycles to delay fall -> 50%
    //localparam CLK_CT_BITS      = $clog2(START_BIT_OFFSET);

    // NEW Variable Baud
    wire [(DIV_W):0] START_BIT_OFFSET;
    assign START_BIT_OFFSET = (CYC_PER_BIT >> 1) + (CYC_PER_BIT >> 1) + (CYC_PER_BIT >> 1);
    localparam CLK_CT_BITS  = DIV_W + 1;

    // General Constants
    localparam LINE_HI      = 2'b11;
    localparam LINE_LO      = 2'b00;
    localparam RISING_EDGE  = 2'b01;
    localparam FALLING_EDGE = 2'b10;

    localparam FRAME_SIZE   = 8;

    localparam DATA_RDY     = 1'b1;
    localparam DATA_NRDY    = 1'b0;

    // States
    localparam IDLE         = 2'h0;
    localparam STALL_0      = 2'h1;
    localparam READ_DATA    = 2'h2;
    localparam PUBLISH      = 2'h3;

    // Registers
    reg [1:0]oa_state;
    reg [1:0]edge_detect;
    reg [3:0]shift_counter;
    reg [(CLK_CT_BITS - 1):0]cycle_ctr;
    reg [(FRAME_SIZE - 1):0]uarx_shift;

    initial begin
        oa_state        = IDLE;
        edge_detect     = LINE_LO;
        shift_counter   = 4'h0;
        cycle_ctr       = {(CLK_CT_BITS){1'b0}};
        uarx_shift      = {(FRAME_SIZE){1'b0}};
        DATA            = {(BYTE_W){1'b0}};

        DATA_RDY_STROBE = DATA_NRDY;
    end

    always @ (posedge sys_clk) begin
        case (oa_state)
            // 0: Wait for falling start
            IDLE: begin
                DATA_RDY_STROBE <= DATA_NRDY;
                if(en) begin
                    edge_detect     <= {edge_detect[0], RX_LINE};
                    
                    if(edge_detect == FALLING_EDGE) begin
                        oa_state    <= STALL_0;
                        cycle_ctr   <= {(CLK_CT_BITS){1'b0}};
                        shift_counter <= 4'h0;
                    end
                end
            end

            // 1: Stall and skip start bit
            STALL_0: begin
                if(cycle_ctr == START_BIT_OFFSET)begin
                    cycle_ctr   <= CYC_PER_BIT;
                    oa_state    <= READ_DATA;
                end
                else cycle_ctr  <= cycle_ctr + 1;
            end

            // 2: Read Data.. pretty much sums it up
            READ_DATA: begin
                if(cycle_ctr == CYC_PER_BIT) begin
                    cycle_ctr   <= {(CLK_CT_BITS){1'b0}};
                    uarx_shift  <= {RX_LINE, uarx_shift [(FRAME_SIZE - 1):1]};
                    shift_counter   <= shift_counter + 1;
                end
                else cycle_ctr  <= cycle_ctr + 1;

                if(shift_counter == FRAME_SIZE) begin
                    oa_state    <= PUBLISH;
                end
            end

            // 3: Publish data to system with the standard
            //  single cycle DATA READY strobe
            PUBLISH: begin
                DATA            <= uarx_shift[7:0];
                DATA_RDY_STROBE <= DATA_RDY;
                oa_state        <= IDLE;
            end
        endcase
    end
endmodule







///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
//      TX
///////////////////////////////////////////////////////////////////////////////
module fast_8N1_UART_TX_
#(
    parameter SYSCLK_F = 24000000,
    parameter BYTE_W = 8,
    parameter DIV_W = 16
)
(
    input sys_clk,
    //input rst,
    input en,

    input [(DIV_W - 1):0] CYC_PER_BIT,

    input TX_LOAD,
    input [(BYTE_W - 1):0]TX_DATA,

    output reg LOAD_OK,

    output reg TX_LINE
);

    // Setup Clock Parameters
    //localparam CYC_PER_BIT      = SYSCLK_F / BAUDRATE;      // cycles per bit
    //localparam CLK_CT_BITS      = $clog2(CYC_PER_BIT);

    localparam CLK_CT_BITS  = DIV_W + 1;

    // States
    localparam IDLE     = 2'h0;
    localparam TX_GO    = 2'h1;
    localparam CLEANUP  = 3'h3;

    // General Constants
    localparam FRAME_SIZE = BYTE_W + 2;

    reg [1:0]oa_state;
    reg [(FRAME_SIZE - 1):0]uatx_shift;
    reg [(CLK_CT_BITS - 1):0]cycle_ctr;

    initial begin
        oa_state    = IDLE;
        uatx_shift  = {(FRAME_SIZE){1'b0}};
        cycle_ctr   = {CLK_CT_BITS{1'b0}};
        TX_LINE     = 0;
        LOAD_OK     = 0;
        $display(CYC_PER_BIT);
        $display(CLK_CT_BITS);
    end


    always @ (posedge sys_clk) begin
        case (oa_state)
            // 0. Idle...
            IDLE: begin
                if(en && TX_LOAD) begin
                    // Assemble LSBit first frame
                    uatx_shift  <= {1'b1, TX_DATA[7:0], 1'b0};
                    cycle_ctr   <= (CYC_PER_BIT - 1);
                    oa_state    <= TX_GO;
                    LOAD_OK     <= 1'b0;
                end else begin
                    LOAD_OK     <= 1'b1;
                    TX_LINE     <= 1'b1;
                end
            end

            // 1. Transmit bits
            TX_GO: begin
                if(uatx_shift) begin
                    if(cycle_ctr == (CYC_PER_BIT - 1)) begin
                        TX_LINE     <= uatx_shift[0];
                        uatx_shift  <= uatx_shift >> 1;
                        cycle_ctr   <= {(CLK_CT_BITS){1'b0}};
                    end else cycle_ctr  <= cycle_ctr + 1;
                end else oa_state <= IDLE;
            end
        endcase
    end
endmodule