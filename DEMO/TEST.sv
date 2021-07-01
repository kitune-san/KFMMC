//
// MMC Block Read Test
// Written by kitune-san
//
`define POR_MAX 16'hffff

module TOP (
    input   logic           CLK,

    // Output
    output  logic   [9:0]   LED,

    // MMC
    output  logic           MMC_CLK,
    inout   logic           MMC_CMD,
    inout   logic   [3:0]   MMC_DATA,

    // VGA
    output  logic           VGA_VS,
    output  logic           VGA_HS,
    output  logic   [3:0]   VGA_R,
    output  logic   [3:0]   VGA_G,
    output  logic   [3:0]   VGA_B
);

    logic           clock;
    logic           reset;
    logic           video_clock;
    logic           video_reset;

    //
    // PLL
    //
    PLL PLL (
        .refclk     (CLK),
        .rst        (1'b0),
        .outclk_0   (clock),
        .outclk_1   (video_clock)
    );

    //
    // Power On Reset
    //
    logic   [15:0]  por_count;

    always_ff @(negedge CLK)
    begin
        if (por_count != `POR_MAX) begin
            reset <= 1'b1;
            por_count <= por_count + 16'h0001;
        end
        else begin
            reset <= 1'b0;
            por_count <= por_count;
        end
    end

    assign  video_reset = reset;

    //
    // Install KFMMC_Drive
    //
    logic   [7:0]   internal_data_bus;
    logic           write_block_address_1;
    logic           write_block_address_2;
    logic           write_block_address_3;
    logic           write_block_address_4;
    logic           write_access_command;
    logic           write_data;

    logic   [7:0]   read_data_byte;
    logic           read_data;

    logic           drive_busy;

    logic           read_interface_error;
    logic           read_crc_error;

    logic           block_read_interrupt;
    logic           read_completion_interrupt;

    logic           mmc_clk;
    logic           mmc_cmd_in;
    logic           mmc_cmd_out;
    logic           mmc_cmd_io;
    logic           mmc_dat_in;
    logic           mmc_dat_out;
    logic           mmc_dat_io;

    KFMMC_Drive #(
        .init_spi_clock_cycle       (8'd020),
        .normal_spi_clock_cycle     (8'd002),
        .timeout                    (32'h000FFFF0)
    ) u_KFMMC_Drive (.*);

    assign  MMC_CLK     = mmc_clk;

    assign  MMC_CMD     = (~mmc_cmd_io & ~mmc_cmd_out) ? 1'b0 : 1'bz;
    assign  mmc_cmd_in  = MMC_CMD;

    assign  MMC_DATA[0] = (~mmc_dat_io & ~mmc_dat_out) ? 1'b0 : 1'bz;
    assign  mmc_dat_in  = MMC_DATA[0];
    assign  MMC_DATA[1] = 1'b1;
    assign  MMC_DATA[2] = 1'b1;
    assign  MMC_DATA[3] = 1'b1;


    //
    // Install KFTVGA
    //
    logic           chip_select_n;
    logic           read_enable_n;
    logic           write_enable_n;
    logic   [13:0]  address;
    logic   [7:0]   data_bus_in;

    logic   [7:0]   data_bus_out;

    logic           video_h_sync;
    logic           video_v_sync;
    logic   [3:0]   video_r;
    logic   [3:0]   video_g;
    logic   [3:0]   video_b;

    KFTVGA u_KFTVGA (.*);

    assign VGA_HS = video_h_sync;
    assign VGA_VS = video_v_sync;
    assign VGA_R  = video_r;
    assign VGA_G  = video_g;
    assign VGA_B  = video_b;


    //
    // TEST
    //
    typedef enum {INITIAL, SEND_ADDRESS_1,  SEND_ADDRESS_2, SEND_ADDRESS_3, SEND_ADDRESS_4, START_READ, READ_WAIT,
        DISPLAY_READ_DATA_1, DISPLAY_READ_DATA_2, DISPLAY_READ_DATA_3, DISPLAY_READ_DATA_4, 
        DISPLAY_READ_DATA_5, DISPLAY_READ_DATA_6, DISPLAY_READ_DATA_7, DISPLAY_READ_DATA_8, 
        READ_NEXT_DATA, COMPLETE} test_state_t;
    test_state_t    test_state;
    test_state_t    next_test_state;
    logic   [7:0]   block;
    logic   [13:0]  disp_count;

    // state machine
    always_comb begin
        next_test_state = test_state;

        case (test_state)
            INITIAL:
                if (~drive_busy)
                    next_test_state = SEND_ADDRESS_1;
            SEND_ADDRESS_1:
                next_test_state = SEND_ADDRESS_2;
            SEND_ADDRESS_2:
                next_test_state = SEND_ADDRESS_3;
            SEND_ADDRESS_3:
                next_test_state = SEND_ADDRESS_4;
            SEND_ADDRESS_4:
                next_test_state = START_READ;
            START_READ:
                next_test_state = READ_WAIT;
            READ_WAIT:
                if (read_completion_interrupt)
                    if (block != 8'h01)
                        next_test_state = INITIAL;
                    else
                        next_test_state = COMPLETE;
                else if (block_read_interrupt)
                    next_test_state = DISPLAY_READ_DATA_1;
            DISPLAY_READ_DATA_1:
                next_test_state = DISPLAY_READ_DATA_2;
            DISPLAY_READ_DATA_2:
                next_test_state = DISPLAY_READ_DATA_3;
            DISPLAY_READ_DATA_3:
                next_test_state = DISPLAY_READ_DATA_4;
            DISPLAY_READ_DATA_4:
                next_test_state = DISPLAY_READ_DATA_5;
            DISPLAY_READ_DATA_5:
                next_test_state = DISPLAY_READ_DATA_6;
            DISPLAY_READ_DATA_6:
                next_test_state = DISPLAY_READ_DATA_7;
            DISPLAY_READ_DATA_7:
                next_test_state = DISPLAY_READ_DATA_8;
            DISPLAY_READ_DATA_8:
                next_test_state = READ_NEXT_DATA;
            READ_NEXT_DATA:
                next_test_state = READ_WAIT;
        endcase
    end

    always_ff @(negedge clock, posedge reset) begin
        if (reset)
            test_state = INITIAL;
        else
            test_state = next_test_state;
    end

    function logic [7:0] num2ascii (input [3:0] number);
        if (number <= 4'd9)
            num2ascii = {4'h3, number};
        else
            num2ascii = {4'h4, number - 4'd9};
    endfunction


    // Controll MMC signals
    always_comb begin
        internal_data_bus       = 8'h00;
        write_block_address_1   = 1'b0;
        write_block_address_2   = 1'b0;
        write_block_address_3   = 1'b0;
        write_block_address_4   = 1'b0;
        write_access_command    = 1'b0;
        read_data               = 1'b0;

        chip_select_n           = 1'b1;
        read_enable_n           = 1'b1;
        write_enable_n          = 1'b1;
        address                 = 14'h0000;
        data_bus_in             = 8'h00;

        case (test_state)
            INITIAL: begin
                read_data               = 1'b1;
            end
            SEND_ADDRESS_1: begin
                internal_data_bus       = block;
                write_block_address_1   = 1'b1;
            end
            SEND_ADDRESS_2: begin
                internal_data_bus       = 8'h00;
                write_block_address_2   = 1'b1;
            end
            SEND_ADDRESS_3: begin
                internal_data_bus       = 8'h00;
                write_block_address_3   = 1'b1;
            end
            SEND_ADDRESS_4: begin
                internal_data_bus       = 8'h00;
                write_block_address_4   = 1'b1;
            end
            START_READ: begin
                internal_data_bus       = 8'h80;
                write_access_command    = 1'b1;
            end
            READ_WAIT: begin
            end
            DISPLAY_READ_DATA_1: begin
                chip_select_n           = 1'b0;
                write_enable_n          = 1'b0;
                data_bus_in             = num2ascii(read_data_byte[7:4]);
                address                 = disp_count + 14'h0000;
            end
            DISPLAY_READ_DATA_2: begin
                chip_select_n           = 1'b0;
                write_enable_n          = 1'b1;
                data_bus_in             = num2ascii(read_data_byte[7:4]);
                address                 = disp_count + 14'h0000;
            end
            DISPLAY_READ_DATA_3: begin
                chip_select_n           = 1'b0;
                write_enable_n          = 1'b0;
                data_bus_in             = 8'h0A;
                address                 = disp_count + 14'h0001;
            end
            DISPLAY_READ_DATA_4: begin
                chip_select_n           = 1'b0;
                write_enable_n          = 1'b1;
                data_bus_in             = 8'h0A;
                address                 = disp_count + 14'h0001;
            end
            DISPLAY_READ_DATA_5: begin
                chip_select_n           = 1'b0;
                write_enable_n          = 1'b0;
                data_bus_in             = num2ascii(read_data_byte[3:0]);
                address                 = disp_count + 14'h0002;
            end
            DISPLAY_READ_DATA_6: begin
                chip_select_n           = 1'b0;
                write_enable_n          = 1'b1;
                data_bus_in             = num2ascii(read_data_byte[3:0]);
                address                 = disp_count + 14'h0002;
            end
            DISPLAY_READ_DATA_7: begin
                chip_select_n           = 1'b0;
                write_enable_n          = 1'b0;
                data_bus_in             = 8'h0A;
                address                 = disp_count + 14'h0003;
            end
            DISPLAY_READ_DATA_8: begin
                chip_select_n           = 1'b0;
                write_enable_n          = 1'b1;
                data_bus_in             = 8'h0A;
                address                 = disp_count + 14'h0003;
            end
            READ_NEXT_DATA: begin
                read_data               = 1'b1;
            end
            COMPLETE: begin
            end
        endcase
    end

    always_ff @(negedge clock, posedge reset) begin
        if (reset)
            block <= 8'h00;
        else if ((test_state == READ_WAIT) && (read_completion_interrupt))
            block <= block + 8'h01;
        else
            block <= block;
    end

    always_ff @(negedge clock, posedge reset) begin
        if (reset)
            disp_count = 14'd320;
        else if (test_state == READ_NEXT_DATA)
            disp_count = disp_count + 14'd8;
        else
            disp_count = disp_count;
    end

    assign  LED[0]  = MMC_CLK;
    assign  LED[1]  = mmc_cmd_in;
    assign  LED[2]  = mmc_dat_in;
    assign  LED[3]  = 1'b0;
    assign  LED[4]  = 1'b0;
    assign  LED[5]  = block_read_interrupt;
    assign  LED[6]  = read_completion_interrupt;
    assign  LED[7]  = read_interface_error;
    assign  LED[8]  = read_crc_error;
    assign  LED[9]  = drive_busy;

endmodule

