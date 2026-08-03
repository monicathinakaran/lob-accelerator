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

    reg [31:0] bid_prices [0:4];
    reg [31:0] bid_quants [0:4];
    
    reg [31:0] ask_prices [0:4];
    reg [31:0] ask_quants [0:4];

    assign best_bid_price = bid_prices[0];
    assign best_ask_price = ask_prices[0];

    // -------------------------------------------------------------------------
    // 1. PARALLEL COMBINATIONAL COMPARATORS (The Thermometer Mask)
    // -------------------------------------------------------------------------
    wire [4:0] bid_match;
    wire [4:0] ask_match;

    // Evaluates instantly: 1 if the incoming price beats/matches this level
    assign bid_match[0] = (price >= bid_prices[0]);
    assign bid_match[1] = (price >= bid_prices[1]);
    assign bid_match[2] = (price >= bid_prices[2]);
    assign bid_match[3] = (price >= bid_prices[3]);
    assign bid_match[4] = (price >= bid_prices[4]);

    assign ask_match[0] = (price <= ask_prices[0]);
    assign ask_match[1] = (price <= ask_prices[1]);
    assign ask_match[2] = (price <= ask_prices[2]);
    assign ask_match[3] = (price <= ask_prices[3]);
    assign ask_match[4] = (price <= ask_prices[4]);

    integer i;

    // -------------------------------------------------------------------------
    // 2. FLAT INSERTION LOGIC 
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        if (reset) begin
            book_updated <= 1'b0;
            for (i = 0; i < 5; i = i + 1) begin
                bid_prices[i] <= 32'h0; 
                bid_quants[i] <= 32'h0;
                ask_prices[i] <= 32'hFFFFFFFF; 
                ask_quants[i] <= 32'h0;
            end
        end else begin
            book_updated <= 1'b0;

            if (order_valid) begin
                if (order_action == 1'b0) begin 
                    // --- BID SIDE ---
                    book_updated <= 1'b1;
                    
                    // Level 0: Gets new order if mask is 1. Otherwise stays.
                    if (bid_match[0]) begin
                        bid_prices[0] <= price; bid_quants[0] <= quantity;
                    end

                    // Level 1: Gets new order if it beats L1 but NOT L0. Gets shifted order if L0 was beaten.
                    if (bid_match[1] && !bid_match[0]) begin
                        bid_prices[1] <= price; bid_quants[1] <= quantity;
                    end else if (bid_match[0]) begin
                        bid_prices[1] <= bid_prices[0]; bid_quants[1] <= bid_quants[0];
                    end

                    // Level 2
                    if (bid_match[2] && !bid_match[1]) begin
                        bid_prices[2] <= price; bid_quants[2] <= quantity;
                    end else if (bid_match[1]) begin
                        bid_prices[2] <= bid_prices[1]; bid_quants[2] <= bid_quants[1];
                    end

                    // Level 3
                    if (bid_match[3] && !bid_match[2]) begin
                        bid_prices[3] <= price; bid_quants[3] <= quantity;
                    end else if (bid_match[2]) begin
                        bid_prices[3] <= bid_prices[2]; bid_quants[3] <= bid_quants[2];
                    end

                    // Level 4
                    if (bid_match[4] && !bid_match[3]) begin
                        bid_prices[4] <= price; bid_quants[4] <= quantity;
                    end else if (bid_match[3]) begin
                        bid_prices[4] <= bid_prices[3]; bid_quants[4] <= bid_quants[3];
                    end

                end else begin 
                    // --- ASK SIDE ---
                    book_updated <= 1'b1;

                    // Level 0
                    if (ask_match[0]) begin
                        ask_prices[0] <= price; ask_quants[0] <= quantity;
                    end

                    // Level 1
                    if (ask_match[1] && !ask_match[0]) begin
                        ask_prices[1] <= price; ask_quants[1] <= quantity;
                    end else if (ask_match[0]) begin
                        ask_prices[1] <= ask_prices[0]; ask_quants[1] <= ask_quants[0];
                    end

                    // Level 2
                    if (ask_match[2] && !ask_match[1]) begin
                        ask_prices[2] <= price; ask_quants[2] <= quantity;
                    end else if (ask_match[1]) begin
                        ask_prices[2] <= ask_prices[1]; ask_quants[2] <= ask_quants[1];
                    end

                    // Level 3
                    if (ask_match[3] && !ask_match[2]) begin
                        ask_prices[3] <= price; ask_quants[3] <= quantity;
                    end else if (ask_match[2]) begin
                        ask_prices[3] <= ask_prices[2]; ask_quants[3] <= ask_quants[2];
                    end

                    // Level 4
                    if (ask_match[4] && !ask_match[3]) begin
                        ask_prices[4] <= price; ask_quants[4] <= quantity;
                    end else if (ask_match[3]) begin
                        ask_prices[4] <= ask_prices[3]; ask_quants[4] <= ask_quants[3];
                    end
                end
            end
        end
    end
endmodule