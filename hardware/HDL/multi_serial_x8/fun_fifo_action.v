/*
    Fun FIFO Action
    Some cool FIFO buffers to deal with mass block TX/RX.
    The iCE40 UP5k has 30 BRAMs of 512x8b so we can afford to 
    have some big buffers around.
    01/28/2024 - Joseph A. De Vico
*/





// FIFO Logic wrapper for BRAM
module fifo_512_byte
#(
    parameter DATA_W = 8,
    parameter DATA_CT = 512
)
(
    input en,
    input clk,
    input clr,

    input wr_en,                        // RISING only trigger
    input [(DATA_W - 1):0] wr_data,

    input rd_en,
    output wire [(DATA_W - 1):0] rd_data,

    output wire [(DATA_CT_W - 1):0] current_fill_ct,
    output wire fifo_empty,
    output wire fifo_full
);

    localparam DATA_CT_W = $clog2(DATA_CT);

    reg [(DATA_CT_W - 1):0] write_ptr;
    reg [(DATA_CT_W - 1):0] buffered_write_ptr;     // Brams hit on falling edges, need buffer for potential addition conflict
    reg [(DATA_CT_W - 1):0] read_ptr;
    reg [(DATA_CT_W - 1):0] buffered_read_ptr;

    assign fifo_empty = (write_ptr == read_ptr) ? 1 : 0;

    reg write_2_bram;
    reg read_from_bram;

    assign current_fill_ct = (buffered_write_ptr > read_ptr) ? (buffered_write_ptr - read_ptr) : (read_ptr - buffered_write_ptr);

    assign fifo_full = &current_fill_ct;

    bram_512_x8 WEEE 
    (
        .bram_clk(clk),                     // BRAM operates on falling edges
        .bram_we(write_2_bram),
        .bram_wr_addr(buffered_write_ptr),
        .bram_wr_data(wr_data),

        .bram_ce(read_from_bram),
        .bram_rd_addr(buffered_read_ptr),
        .bram_out(rd_data)
    );

    initial begin
        current_fill_ct     = 0;

        write_2_bram        = 0;
        read_from_bram      = 0;

        write_ptr           = 0;
        buffered_write_ptr  = 0;
        read_ptr            = 0;
        buffered_read_ptr   = 0;
    end

    // Write Cycle
    always @ (posedge clk) begin
        if(en && wr_en) begin
            buffered_write_ptr  <= write_ptr;
            write_ptr           <= write_ptr + 1;
            write_2_bram        <= 1;
        end else begin
            write_2_bram        <= 0;
        end
    end

    // Read Cycle
    always @ (posedge clk) begin
        if(en && rd_en) begin
            buffered_read_ptr   <= read_ptr;
            if((read_ptr != buffered_write_ptr)) read_ptr <= read_ptr + 1;
            bram_ce             <= 1;
        end else begin
            bram_ce             <= 0;
        end
    end
endmodule


// 512 x 8b DP BRAM
module bram_512_x8
#(
    parameter DATA_W = 8,
    parameter DATA_CT = 512
)
(
    input bram_clk,
    input bram_we,
    input [(SAMPLE_ADDR_BITS - 1):0]bram_wr_addr,
    input [(DATA_W - 1):0]bram_wr_data,

    input bram_ce,
    input [(SAMPLE_ADDR_BITS - 1):0]bram_rd_addr,
    output reg [(DATA_W - 1):0]bram_out
);
    localparam SAMPLE_ADDR_BITS = $clog2(DATA_CT);

    reg [(DATA_W - 1):0] bytes_n_bobs [(DATA_CT - 1):0];

    integer n;
    initial begin
        for(n = 0; n < DATA_CT; n = n + 1) begin
            bytes_n_bobs[n] = 0;
        end
    end

    always @ (negedge bram_clk) begin
        if(bram_ce) bram_out <= bytes_n_bobs[bram_rd_addr];
        
        if(bram_we) bytes_n_bobs[bram_wr_addr] <= bram_wr_data
    end
endmodule