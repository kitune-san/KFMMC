//
// KFMMC_Controller
// Written by kitune-san
//
module KFMMC_Controller #(
    parameter init_spi_clock_cycle = 8'd010,
    parameter normal_spi_clock_cycle = 8'd002,
    parameter access_block_size = 16'd512
) (
    input   logic           clock,
    input   logic           reset,

    // Internal bus
    input   logic   [7:0]   internal_data_bus,
    input   logic           write_block_address_1,
    input   logic           write_block_address_2,
    input   logic           write_block_address_3,
    input   logic           write_block_address_4,
    input   logic           write_access_command,
    input   logic           write_data,

    output  logic   [7:0]   read_data,

    // Control MMC signals
    // Output (to Command I/O)
    output  logic           reset_command_state,
    output  logic           start_command,
    output  logic   [47:0]  command,
    output  logic           enable_command_crc,
    output  logic           enable_response_crc,
    output  logic   [4:0]   response_length,
    // Input (from Command I/O)
    input   logic           command_busy,
    input   logic   [135:0] response,
    input   logic           response_error,
    // Output (to Data I/O)
    output  logic           disable_data_io,
    output  logic           start_data_io,
    output  logic           check_data_start_bit,
    output  logic           clear_data_crc,
    output  logic           data_io,
    output  logic   [7:0]   transmit_data,
    // Input (from Data I/O)
    input   logic           data_io_busy,
    input   logic   [7:0]   received_data,
    // Output (to MMC interface)
    output  logic   [7:0]   mmc_clock_cycle,
    // Input (from MMC interface)
    input   logic   [15:0]  send_data_crc,
    input   logic   [15:0]  received_data_crc,
    input   logic           timeout_interrupt,

    // State
    output  logic           drive_busy,
    output  logic           drive_wait_next_data,

    // External input/output
    output  logic           interrupt,
    input   logic           terminal_count
);

    // State
    typedef enum {INIT, RESET_CLK_1, RESET_CLK_2, SEND_CMD0, WAIT_TO_SEND_CMD0, SEND_DUMMY, WAIT_TO_SEND_DUMMY, SEND_CMD8,
        RESP_CMD8, SEND_CMD1, RESP_CMD1, SEND_CMD55, RESP_CMD55, SEND_ACMD41, RESP_ACMD41, SEND_CMD58, SEND_INITIALIZE_DUMMY,
        WAIT_TO_SEND_INITIALIZE_DUMMY, SEND_CMD2, RESP_CMD2, SEND_CMD3, RESP_CMD3, SEND_CMD9, RESP_CMD9, SEND_CMD7, RESP_CMD7,
        BUSY_WAIT_CMD7_1, BUSY_WAIT_CMD7_2, READY} control_state_t;

    //
    // Internal signals
    //
    control_state_t control_state;
    control_state_t next_control_state;
    logic           busy;
    logic           error;
    logic   [3:0]   reset_pulse_count;
    logic           mmc_reset;
    logic           emmc_reset;
    logic   [16:0]  access_count;
    logic   [32:0]  ocr;
    logic   [127:0] cid;
    logic   [15:0]  rca;
    logic   [127:0] csd;
    logic   [31:0]  block_address;

    //
    // State machine
    //
    always_comb begin
        next_control_state = control_state;

        case (control_state)
            INIT: begin
                if (~busy)
                    next_control_state = RESET_CLK_1;
            end
            RESET_CLK_1: begin
                if (busy)
                    next_control_state = RESET_CLK_2;
            end
            RESET_CLK_2: begin
                if (~busy)
                    if (reset_pulse_count != 4'd00)
                        next_control_state = RESET_CLK_1;
                    else
                        next_control_state = SEND_CMD0;
            end
            SEND_CMD0: begin
                if (busy)
                    next_control_state = WAIT_TO_SEND_CMD0;
            end
            WAIT_TO_SEND_CMD0: begin
                if (~busy)
                    next_control_state = SEND_DUMMY;
            end
            SEND_DUMMY: begin
                if (busy)
                    next_control_state = WAIT_TO_SEND_DUMMY;
            end
            WAIT_TO_SEND_DUMMY: begin
                if (~busy)
                    if (emmc_reset)
                        next_control_state = SEND_CMD0;
                    else if (mmc_reset)
                        next_control_state = SEND_CMD1;
                    else
                        next_control_state = SEND_CMD8;
            end
            SEND_CMD8: begin
                if (busy)
                    next_control_state = RESP_CMD8;
            end
            RESP_CMD8: begin
                if (error)
                    next_control_state = INIT;
                else if (~busy)
                    if (response[19:8] != 12'h1_AA)
                        next_control_state = INIT;
                    else
                        next_control_state = SEND_CMD55;
            end
            SEND_CMD1: begin
                if (busy)
                    next_control_state = RESP_CMD1;
            end
            RESP_CMD1: begin
                if (error)
                    next_control_state = INIT;
                if (~busy)
                    if (response[39] == 1'b0)
                        next_control_state = SEND_INITIALIZE_DUMMY;
                    else
                        next_control_state = SEND_CMD2;
            end
            SEND_CMD55: begin
                if (busy)
                    next_control_state = RESP_CMD55;
            end
            RESP_CMD55: begin
                if (error)
                    next_control_state = INIT;
                if (~busy)
                    next_control_state = SEND_ACMD41;
            end
            SEND_ACMD41: begin
                if (busy)
                    next_control_state = RESP_ACMD41;
            end
            RESP_ACMD41: begin
                if (error)
                    next_control_state = INIT;
                if (~busy)
                    if (response[39] == 1'b0)
                        next_control_state = SEND_INITIALIZE_DUMMY;
                    else
                        next_control_state = SEND_CMD2;
            end
            SEND_INITIALIZE_DUMMY: begin
                if (busy)
                    next_control_state = WAIT_TO_SEND_INITIALIZE_DUMMY;
            end
            WAIT_TO_SEND_INITIALIZE_DUMMY: begin
                if (~busy)
                    if (mmc_reset)
                        next_control_state = SEND_CMD1;
                    else
                        next_control_state = SEND_CMD55;
            end
            SEND_CMD2: begin
                if (busy)
                    next_control_state = RESP_CMD2;
            end
            RESP_CMD2: begin
                if (error)
                    next_control_state = INIT;
                if (~busy)
                    next_control_state = SEND_CMD3;
            end
            SEND_CMD3: begin
                if (busy)
                    next_control_state = RESP_CMD3;
            end
            RESP_CMD3: begin
                if (error)
                    next_control_state = INIT;
                if (~busy)
                    if (response[21] == 1'b1)
                        next_control_state = INIT;
                    else
                        next_control_state = SEND_CMD9;
            end
            SEND_CMD9: begin
                if (busy)
                    next_control_state = RESP_CMD9;
            end
            RESP_CMD9: begin
                if (error)
                    next_control_state = INIT;
                if (~busy)
                    next_control_state = SEND_CMD7;
            end
            SEND_CMD7: begin
                if (busy)
                    next_control_state = RESP_CMD7;
            end
            RESP_CMD7: begin
                if (error)
                    next_control_state = INIT;
                if (~busy)
                    if (response[27] == 1'b1)
                        next_control_state = INIT;
                    else
                        next_control_state = BUSY_WAIT_CMD7_1;
            end
            BUSY_WAIT_CMD7_1: begin
                if (busy)
                    next_control_state = BUSY_WAIT_CMD7_2;
            end
            BUSY_WAIT_CMD7_2: begin
                if (timeout_interrupt)
                    next_control_state = READY;
                else if (~busy)
                    if (received_data[0] == 1'b1)
                        next_control_state = READY;
            end
            READY: begin
                if (write_data)
                    if (internal_data_bus == 8'b10000000)       // Read command
                        next_control_state = READY;     // TODO:
                    else if (internal_data_bus == 8'b10000001)  // Write command
                        next_control_state = READY;     // TODO:
            end
            default: begin
                //next_control_state = INIT;
            end
        endcase
    end

    always_ff @(negedge clock, posedge reset) begin
        if (reset)
            control_state <= INIT;
        else
            control_state <= next_control_state;
    end


    //
    // Control signals
    //
    always_comb begin
        reset_command_state     = 1'b0;
        start_command           = 1'b0;
        command                 = 48'hFF_FF_FF_FF_FF_FF;
        enable_command_crc      = 1'b0;
        enable_response_crc     = 1'b0;
        response_length         = 5'd0;

        disable_data_io         = 1'b1;
        start_data_io           = 1'b0;
        check_data_start_bit    = 1'b0;
        clear_data_crc          = 1'b0;
        data_io                 = 1'b1;
        transmit_data           = 8'hFF;

        case (control_state)
            INIT: begin
                reset_command_state     = 1'b1;
            end
            RESET_CLK_1: begin
                start_command           = 1'b1;
            end
            RESET_CLK_2: begin
            end
            SEND_CMD0: begin
                start_command           = 1'b1;
                if (emmc_reset)
                    command             = 48'h40_F0_F0_F0_F0_00;
                else
                    command             = 48'h40_00_00_00_00_00;
                enable_command_crc      = 1'b1;
            end
            WAIT_TO_SEND_CMD0: begin
            end
            SEND_DUMMY: begin
                start_command           = 1'b1;
            end
            WAIT_TO_SEND_DUMMY: begin
            end
            SEND_CMD8: begin
                start_command           = 1'b1;
                command                 = 48'h48_00_00_01_AA_00;
                enable_command_crc      = 1'b1;
                enable_response_crc     = 1'b1;
                response_length         = 5'd6;
            end
            RESP_CMD8: begin
            end
            SEND_CMD1: begin
                start_command           = 1'b1;
                command                 = 48'h69_40_FF_80_00_00;
                enable_command_crc      = 1'b1;
                enable_response_crc     = 1'b1;
                response_length         = 5'd6;
            end
            RESP_CMD1: begin
            end
            SEND_CMD55: begin
                start_command           = 1'b1;
                command                 = 48'h77_00_00_00_00_00;
                enable_command_crc      = 1'b1;
                enable_response_crc     = 1'b1;
                response_length         = 5'd6;
            end
            RESP_CMD55: begin
            end
            SEND_ACMD41: begin
                start_command           = 1'b1;
                command                 = 48'h69_40_FF_80_00_00;
                enable_command_crc      = 1'b1;
                enable_response_crc     = 1'b1;
                response_length         = 5'd6;
            end
            RESP_ACMD41: begin
            end
            SEND_INITIALIZE_DUMMY: begin
                start_command           = 1'b1;
            end
            WAIT_TO_SEND_INITIALIZE_DUMMY: begin
            end
            SEND_CMD2: begin
                start_command           = 1'b1;
                command                 = 48'h42_00_00_00_00_00;
                enable_command_crc      = 1'b1;
                enable_response_crc     = 1'b1;
                response_length         = 5'd17;
            end
            RESP_CMD2: begin
            end
            SEND_CMD3: begin
                start_command           = 1'b1;
                command[47:40]          = 8'h43;
                if (~mmc_reset)
                    command[39:24]      = 16'h00;
                else
                    command[39:24]      = 16'h01;
                command[23:0]           = 24'h00_00_00;
                enable_command_crc      = 1'b1;
                enable_response_crc     = 1'b1;
                response_length         = 5'd6;
            end
            RESP_CMD3: begin
            end
            SEND_CMD9: begin
                start_command           = 1'b1;
                command[47:40]          = 8'h49;
                command[39:24]          = rca;
                command[23:0]           = 24'h00_00_00;
                enable_command_crc      = 1'b1;
                enable_response_crc     = 1'b1;
                response_length         = 5'd17;
            end
            RESP_CMD9: begin
            end
            SEND_CMD7: begin
                start_command           = 1'b1;
                command[47:40]          = 8'h47;
                command[39:24]          = rca;
                command[23:0]           = 24'h00_00_00;
                enable_command_crc      = 1'b1;
                enable_response_crc     = 1'b1;
                response_length         = 5'd6;
            end
            RESP_CMD7: begin
            end
            BUSY_WAIT_CMD7_1: begin
                disable_data_io         = 1'b0;
                start_data_io           = 1'b1;
                check_data_start_bit    = 1'b1;
                data_io                 = 1'b1;
            end
            BUSY_WAIT_CMD7_2: begin
                disable_data_io         = 1'b0;
            end
            READY: begin
            end
            default: begin
            end
        endcase
    end

    // Busy flag
    assign  busy = command_busy | data_io_busy;

    // Error flag
    assign  error = response_error | timeout_interrupt;

    // Count of reset pulse
    always_ff @(negedge clock, posedge reset) begin
        if (reset)
            reset_pulse_count <= 4'd02;
        else if (control_state == INIT)
            reset_pulse_count <= 4'd02;
        else if ((control_state == RESET_CLK_1) && (next_control_state == RESET_CLK_2))
            reset_pulse_count <= reset_pulse_count - 4'd01;
        else
            reset_pulse_count <= reset_pulse_count;
    end

    // Reset mode
    always_ff @(negedge clock, posedge reset) begin
        if (reset) begin
            mmc_reset   <= 1'b0;
            emmc_reset  <= 1'b0;
        end
        else if (control_state == INIT) begin
            mmc_reset   <= 1'b0;
            emmc_reset  <= 1'b0;
        end
        else if ((control_state == RESP_CMD8) && (timeout_interrupt)) begin
            mmc_reset   <= 1'b1;
            emmc_reset  <= 1'b1;
        end
        else if ((control_state == SEND_DUMMY) && (emmc_reset)) begin
            mmc_reset   <= 1'b1;
            emmc_reset  <= 1'b0;
        end
        else if ((control_state == RESP_CMD1) && (timeout_interrupt)) begin
            mmc_reset   <= 1'b0;
            emmc_reset  <= 1'b0;
        end
        else begin
            mmc_reset   <= mmc_reset;
            emmc_reset  <= emmc_reset;
        end
    end

    // MMC clock cycle
    always_ff @(negedge clock, posedge reset) begin
        if (reset)
            mmc_clock_cycle <= init_spi_clock_cycle;
        else if (control_state == INIT)
            mmc_clock_cycle <= init_spi_clock_cycle;
        else if (control_state == READY)
            mmc_clock_cycle <= normal_spi_clock_cycle;
        else
            mmc_clock_cycle <= mmc_clock_cycle;
    end

    // access count
    always_ff @(negedge clock, posedge reset) begin
        if (reset)
            access_count <= 16'h0000;
        else if (control_state == READY)
            access_count <= access_block_size;
        else if (1'b0)  // TODO:
            access_count <= access_count - 16'h0001;
        else
            access_count <= access_count;
    end


    //
    // Registers
    //
    // OCR
    always_ff @(negedge clock, posedge reset) begin
        if (reset)
            ocr <= 32'h00000000;
        else if ((control_state == RESP_ACMD41) || (control_state == RESP_CMD1))
            ocr <= response[39:8];
        else
            ocr <= ocr;
    end

    // CID
    always_ff @(negedge clock, posedge reset) begin
        if (reset)
            cid <= 0;
        else if (control_state == RESP_CMD2)
            cid <= response[127:0];
        else
            cid <= cid;
    end

    // RCA
    always_ff @(negedge clock, posedge reset) begin
        if (reset)
            rca <= 16'h0001;
        else if ((~mmc_reset) && (control_state == RESP_CMD3))
            rca <= response[39:24];
        else
            rca <= rca;
    end

    // CSD
    always_ff @(negedge clock, posedge reset) begin
        if (reset)
            csd <= 0;
        else if (control_state == RESP_CMD9)
            csd <= response[127:0];
        else
            csd <= csd;
    end

    // Block Address
    always_ff @(negedge clock, posedge reset) begin
        if (reset)
            block_address <= 32'h00000000;
        else if (write_block_address_1)
            block_address <= {block_address[31:8],  internal_data_bus};
        else if (write_block_address_2)
            block_address <= {block_address[31:16], internal_data_bus, block_address[7:0]};
        else if (write_block_address_3)
            block_address <= {block_address[31:24], internal_data_bus, block_address[15:0]};
        else if (write_block_address_4)
            block_address <= {internal_data_bus, block_address[23:0]};
        else
            block_address <= block_address;
    end

    // Read data
    // TODO:

    //
    // Status
    //
    // Drive is busy
    assign  drive_busy = (control_state == READY);

endmodule

