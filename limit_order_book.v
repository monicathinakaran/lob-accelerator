// limit_order_book.v
module limit_order_book (
    input  wire        clk,
    input  wire        reset,
    input  wire        order_action, // 0: Buy (Bid), 1: Sell (Ask)
    input  wire [31:0] price,
    input  wire [31:0] quantity,
    input  wire        order_valid,

    output wire [31:0] best_bid_price,
    output wire [31:0] best_ask_price,
    output reg         book_updated
);

    // Arrays for top 5 levels (Flattened Registers, NOT BRAM)
    reg [31:0] bid_prices [0:4];
    reg [31:0] bid_quants [0:4];
    
    reg [31:0] ask_prices [0:4];
    reg [31:0] ask_quants [0:4];

    // Combinational outputs for Top of Book
    assign best_bid_price = bid_prices[0];
    assign best_ask_price = ask_prices[0];

    integer i;

    always @(posedge clk) begin
        if (reset) begin
            book_updated <= 1'b0;
            for (i = 0; i < 5; i = i + 1) begin
                bid_prices[i] <= 32'h0; // Lowest possible bid
                bid_quants[i] <= 32'h0;
                ask_prices[i] <= 32'hFFFFFFFF; // Highest possible ask
                ask_quants[i] <= 32'h0;
            end
        end else begin
            book_updated <= 1'b0;

            if (order_valid) begin
                // --- BID SIDE (Sort High to Low) ---
                if (order_action == 1'b0) begin 
                    if (price >= bid_prices[0]) begin
                        bid_prices[4] <= bid_prices[3]; bid_quants[4] <= bid_quants[3];
                        bid_prices[3] <= bid_prices[2]; bid_quants[3] <= bid_quants[2];
                        bid_prices[2] <= bid_prices[1]; bid_quants[2] <= bid_quants[1];
                        bid_prices[1] <= bid_prices[0]; bid_quants[1] <= bid_quants[0];
                        bid_prices[0] <= price;         bid_quants[0] <= quantity;
                        book_updated <= 1'b1;
                    end else if (price >= bid_prices[1]) begin
                        bid_prices[4] <= bid_prices[3]; bid_quants[4] <= bid_quants[3];
                        bid_prices[3] <= bid_prices[2]; bid_quants[3] <= bid_quants[2];
                        bid_prices[2] <= bid_prices[1]; bid_quants[2] <= bid_quants[1];
                        bid_prices[1] <= price;         bid_quants[1] <= quantity;
                        book_updated <= 1'b1;
                    end else if (price >= bid_prices[2]) begin
                        bid_prices[4] <= bid_prices[3]; bid_quants[4] <= bid_quants[3];
                        bid_prices[3] <= bid_prices[2]; bid_quants[3] <= bid_quants[2];
                        bid_prices[2] <= price;         bid_quants[2] <= quantity;
                        book_updated <= 1'b1;
                    end else if (price >= bid_prices[3]) begin
                        bid_prices[4] <= bid_prices[3]; bid_quants[4] <= bid_quants[3];
                        bid_prices[3] <= price;         bid_quants[3] <= quantity;
                        book_updated <= 1'b1;
                    end else if (price >= bid_prices[4]) begin
                        bid_prices[4] <= price;         bid_quants[4] <= quantity;
                        book_updated <= 1'b1;
                    end
                end 
                // --- ASK SIDE (Sort Low to High) ---
                else begin 
                    if (price <= ask_prices[0]) begin
                        ask_prices[4] <= ask_prices[3]; ask_quants[4] <= ask_quants[3];
                        ask_prices[3] <= ask_prices[2]; ask_quants[3] <= ask_quants[2];
                        ask_prices[2] <= ask_prices[1]; ask_quants[2] <= ask_quants[1];
                        ask_prices[1] <= ask_prices[0]; ask_quants[1] <= ask_quants[0];
                        ask_prices[0] <= price;         ask_quants[0] <= quantity;
                        book_updated <= 1'b1;
                    end else if (price <= ask_prices[1]) begin
                        ask_prices[4] <= ask_prices[3]; ask_quants[4] <= ask_quants[3];
                        ask_prices[3] <= ask_prices[2]; ask_quants[3] <= ask_quants[2];
                        ask_prices[2] <= ask_prices[1]; ask_quants[2] <= ask_quants[1];
                        ask_prices[1] <= price;         ask_quants[1] <= quantity;
                        book_updated <= 1'b1;
                    end else if (price <= ask_prices[2]) begin
                        ask_prices[4] <= ask_prices[3]; ask_quants[4] <= ask_quants[3];
                        ask_prices[3] <= ask_prices[2]; ask_quants[3] <= ask_quants[2];
                        ask_prices[2] <= price;         ask_quants[2] <= quantity;
                        book_updated <= 1'b1;
                    end else if (price <= ask_prices[3]) begin
                        ask_prices[4] <= ask_prices[3]; ask_quants[4] <= ask_quants[3];
                        ask_prices[3] <= price;         ask_quants[3] <= quantity;
                        book_updated <= 1'b1;
                    end else if (price <= ask_prices[4]) begin
                        ask_prices[4] <= price;         ask_quants[4] <= quantity;
                        book_updated <= 1'b1;
                    end
                end
            end
        end
    end
endmodule
