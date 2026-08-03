// tb_lob.v
`timescale 1ns / 1ps

module tb_lob();
    reg clk;
    reg reset;
    reg order_action;
    reg [31:0] price;
    reg [31:0] quantity;
    reg order_valid;

    wire [31:0] best_bid_price;
    wire [31:0] best_ask_price;
    wire book_updated;

    limit_order_book uut (
        .clk(clk),
        .reset(reset),
        .order_action(order_action),
        .price(price),
        .quantity(quantity),
        .order_valid(order_valid),
        .best_bid_price(best_bid_price),
        .best_ask_price(best_ask_price),
        .book_updated(book_updated)
    );

    // 300MHz Clock Generation
    always #1.66 clk = ~clk;

    initial begin
        // Initialize Inputs
        clk = 0;
        reset = 1;
        order_action = 0;
        price = 0;
        quantity = 0;
        order_valid = 0;

        // Reset system
        #10;
        reset = 0;

        // Insert Bid 1: Price 100
        @(posedge clk);
        order_valid = 1; order_action = 0; price = 100; quantity = 50;
        
        // Insert Bid 2: Price 105 (Should shift 100 down)
        @(posedge clk);
        order_valid = 1; order_action = 0; price = 105; quantity = 25;
        
        // Insert Ask 1: Price 110
        @(posedge clk);
        order_valid = 1; order_action = 1; price = 110; quantity = 100;
        
        // Stop inserting
        @(posedge clk);
        order_valid = 0;

        #20 $finish;
    end
endmodule
