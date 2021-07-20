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
    inout   logic   [3:0]   MMC_DATA
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
    logic           write_interface_error;

    logic           block_read_interrupt;
    logic           read_completion_interrupt;
    logic           request_write_data_interrupt;
    logic           write_completion_interrupt;

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
    // TEST
    //
    typedef enum {INITIAL, SEND_ADDRESS_1,  SEND_ADDRESS_2, SEND_ADDRESS_3, SEND_ADDRESS_4, START_WRITE,
        WAIT_INTERRUPT, SEND_DATA, READ_RESULT, WAIT_BUSY,
        COMPLETE} test_state_t;
    test_state_t    test_state;
    test_state_t    next_test_state;
    logic   [7:0]   block;
    logic   [7:0]   data;

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
                next_test_state = START_WRITE;
            START_WRITE:
                next_test_state = WAIT_INTERRUPT;
            WAIT_INTERRUPT:
                if (write_completion_interrupt)
                    next_test_state = READ_RESULT;
                else if (request_write_data_interrupt)
                    next_test_state = SEND_DATA;
            SEND_DATA:
                if (~request_write_data_interrupt)
                    next_test_state = WAIT_INTERRUPT;
            READ_RESULT:
                next_test_state = WAIT_BUSY;
            WAIT_BUSY:
                if (~drive_busy)
                    if (block != 8'h02)
                        next_test_state = SEND_ADDRESS_1;
                    else
                        next_test_state = COMPLETE;
        endcase
    end

    always_ff @(negedge clock, posedge reset) begin
        if (reset)
            test_state = INITIAL;
        else
            test_state = next_test_state;
    end

    // Controll MMC signals
    always_comb begin
        internal_data_bus       = 8'h00;
        write_block_address_1   = 1'b0;
        write_block_address_2   = 1'b0;
        write_block_address_3   = 1'b0;
        write_block_address_4   = 1'b0;
        write_access_command    = 1'b0;
        read_data               = 1'b0;
        write_data              = 1'b0;

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
            START_WRITE: begin
                internal_data_bus       = 8'h81;
                write_access_command    = 1'b1;
            end
            WAIT_INTERRUPT: begin
            end
            SEND_DATA: begin
                internal_data_bus       = data;
                write_data              = 1'b1;
            end
            READ_RESULT: begin
                read_data               = 1'b1;
            end
            WAIT_BUSY: begin
            end
            COMPLETE: begin
            end
        endcase
    end

    always_ff @(negedge clock, posedge reset) begin
        if (reset)
            block <= 8'h00;
        else if (test_state == READ_RESULT)
            block <= block + 8'h01;
        else
            block <= block;
    end

    always_ff @(negedge clock, posedge reset) begin
        if (reset)
            data <= 8'h00;
        else if ((test_state == WAIT_INTERRUPT) && (request_write_data_interrupt))
            data <= data + 8'h01;
        else
            data <= data;
    end

    assign  LED[0]  = MMC_CLK;
    assign  LED[1]  = mmc_cmd_in;
    assign  LED[2]  = mmc_dat_in;
    assign  LED[3]  = 1'b0;
    assign  LED[4]  = 1'b0;
    assign  LED[5]  = request_write_data_interrupt;
    assign  LED[6]  = write_completion_interrupt;
    assign  LED[7]  = write_interface_error;
    assign  LED[8]  = drive_busy;
    assign  LED[9]  = (test_state == COMPLETE);
endmodule

