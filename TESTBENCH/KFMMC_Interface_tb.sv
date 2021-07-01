
`define TB_CYCLE        20
`define TB_FINISH_COUNT 20000

module KFMMC_Interface_tm();

    timeunit        1ns;
    timeprecision   10ps;

    //
    // Generate wave file to check
    //
`ifdef IVERILOG
    initial begin
        $dumpfile("tb.vcd");
        $dumpvars(0, tb);
    end
`endif

    //
    // Generate clock
    //
    logic   clock;
    initial clock = 1'b1;
    always #(`TB_CYCLE / 2) clock = ~clock;

    //
    // Generate reset
    //
    logic reset;
    initial begin
        reset = 1'b1;
            # (`TB_CYCLE * 10)
        reset = 1'b0;
    end

    //
    // Cycle counter
    //
    logic   [31:0]  tb_cycle_counter;
    always_ff @(negedge clock, posedge reset) begin
        if (reset)
            tb_cycle_counter <= 32'h0;
        else
            tb_cycle_counter <= tb_cycle_counter + 32'h1;
    end

    always_comb begin
        if (tb_cycle_counter == `TB_FINISH_COUNT) begin
            $display("***** SIMULATION TIMEOUT ***** at %d", tb_cycle_counter);
`ifdef IVERILOG
            $finish;
`elsif  MODELSIM
            $stop;
`else
            $finish;
`endif
        end
    end

    //
    // Module under test
    //
    logic           start_communication;
    logic           command_io;
    logic           data_io;
    logic           check_command_start_bit;
    logic           check_data_start_bit;
    logic           read_continuous_data;
    logic           clear_command_crc;
    logic           clear_data_crc;
    logic           clear_command_interrupt;
    logic           clear_data_interrupt;
    logic           mask_command_interrupt;
    logic           mask_data_interrupt;
    logic           set_send_command;
    logic   [7:0]   send_command;
    logic           set_send_data;
    logic   [7:0]   send_data;

    logic   [7:0]   received_response;
    logic   [6:0]   send_command_crc;
    logic   [6:0]   received_response_crc;
    logic   [7:0]   received_data;
    logic   [15:0]  send_data_crc;
    logic   [15:0]  received_data_crc;

    logic           in_connecting;
    logic           sent_command_interrupt;
    logic           received_response_interrupt;
    logic           sent_data_interrupt;
    logic           received_data_interrupt;
    logic           timeout_interrupt;

    logic   [7:0]   mmc_clock_cycle;
    logic           mmc_clk;
    logic           mmc_cmd_in;
    logic           mmc_cmd_out;
    logic           mmc_cmd_io;
    logic           mmc_dat_in;
    logic           mmc_dat_out;
    logic           mmc_dat_io;

    KFMMC_Interface u_KFMMC_Interface(.*);

    //
    // Task : Initialization
    //
    task TASK_INIT();
    begin
        #(`TB_CYCLE * 0);
        start_communication     = 1'b0;
        command_io              = 1'b0;
        data_io                 = 1'b0;
        check_command_start_bit = 1'b0;
        check_data_start_bit    = 1'b0;
        read_continuous_data    = 1'b0;
        clear_command_crc       = 1'b0;
        clear_data_crc          = 1'b0;
        clear_command_interrupt = 1'b0;
        clear_data_interrupt    = 1'b0;
        mask_command_interrupt  = 1'b0;
        mask_data_interrupt     = 1'b0;
        set_send_command        = 1'b0;
        send_command            = 8'b00000000;
        set_send_data           = 1'b0;
        send_data               = 8'b00000000;
        mmc_clock_cycle         = 8'b00000010;
        mmc_cmd_in              = 1'b1;
        mmc_dat_in              = 1'b1;
        #(`TB_CYCLE * 12);
    end
    endtask

    //
    // Task : Send command test
    //
    task SEND_COMMAND_TEST();
    begin
        #(`TB_CYCLE * 0);
        start_communication     = 1'b1;
        command_io              = 1'b0;
        data_io                 = 1'b1;
        check_command_start_bit = 1'b1;
        check_data_start_bit    = 1'b1;
        clear_command_crc       = 1'b1;
        clear_data_crc          = 1'b0;
        clear_command_interrupt = 1'b1;
        clear_data_interrupt    = 1'b0;
        mask_command_interrupt  = 1'b0;
        mask_data_interrupt     = 1'b1;
        set_send_command        = 1'b1;
        send_command            = 8'h40;
        set_send_data           = 1'b0;
        send_data               = 8'h00;
        #(`TB_CYCLE * 1);
        start_communication     = 1'b0;
        clear_command_crc       = 1'b0;
        clear_command_interrupt = 1'b0;
        set_send_command        = 1'b0;
        #(`TB_CYCLE * 24);
        start_communication     = 1'b1;
        clear_command_interrupt = 1'b1;
        set_send_command        = 1'b1;
        send_command            = 8'h00;
        #(`TB_CYCLE * 1);
        start_communication     = 1'b0;
        clear_command_interrupt = 1'b0;
        set_send_command        = 1'b0;
        #(`TB_CYCLE * 24);
        start_communication     = 1'b1;
        clear_command_interrupt = 1'b1;
        set_send_command        = 1'b1;
        send_command            = 8'h00;
        #(`TB_CYCLE * 1);
        start_communication     = 1'b0;
        clear_command_interrupt = 1'b0;
        set_send_command        = 1'b0;
        #(`TB_CYCLE * 24);
        start_communication     = 1'b1;
        clear_command_interrupt = 1'b1;
        set_send_command        = 1'b1;
        send_command            = 8'h00;
        #(`TB_CYCLE * 1);
        start_communication     = 1'b0;
        clear_command_interrupt = 1'b0;
        set_send_command        = 1'b0;
        #(`TB_CYCLE * 24);
        start_communication     = 1'b1;
        clear_command_interrupt = 1'b1;
        set_send_command        = 1'b1;
        send_command            = 8'h00;
        #(`TB_CYCLE * 1);
        start_communication     = 1'b0;
        clear_command_interrupt = 1'b0;
        set_send_command        = 1'b0;
        #(`TB_CYCLE * 24);
        start_communication     = 1'b1;
        clear_command_interrupt = 1'b1;
        set_send_command        = 1'b1;
        send_command            = {send_command_crc, 1'b1};
        #(`TB_CYCLE * 1);
        start_communication     = 1'b0;
        clear_command_interrupt = 1'b0;
        clear_command_interrupt = 1'b0;
        set_send_command        = 1'b0;
        #(`TB_CYCLE * 24);
    end
    endtask

    //
    // Task : Response command test
    //
    task RESPONSE_COMMAND_TEST();
    begin
        #(`TB_CYCLE * 0);
        start_communication     = 1'b1;
        command_io              = 1'b1;
        data_io                 = 1'b1;
        check_command_start_bit = 1'b1;
        check_data_start_bit    = 1'b1;
        clear_command_crc       = 1'b1;
        clear_data_crc          = 1'b0;
        clear_command_interrupt = 1'b1;
        clear_data_interrupt    = 1'b0;
        mask_command_interrupt  = 1'b0;
        mask_data_interrupt     = 1'b1;
        set_send_command        = 1'b0;
        send_command            = 8'h00;
        set_send_data           = 1'b0;
        send_data               = 8'h00;
        mmc_cmd_in              = 1'b1;
        #(`TB_CYCLE * 1);
        start_communication     = 1'b0;
        command_io              = 1'b0;
        check_command_start_bit = 1'b0;
        clear_command_crc       = 1'b0;
        clear_command_interrupt = 1'b0;
        #(`TB_CYCLE * 12);

        // 0x01
        mmc_cmd_in              = 1'b0; // start bit
        #(`TB_CYCLE * 2);
        mmc_cmd_in              = 1'b0;
        #(`TB_CYCLE * 2);
        mmc_cmd_in              = 1'b0;
        #(`TB_CYCLE * 2);
        mmc_cmd_in              = 1'b0;
        #(`TB_CYCLE * 2);
        mmc_cmd_in              = 1'b0;
        #(`TB_CYCLE * 2);
        mmc_cmd_in              = 1'b0;
        #(`TB_CYCLE * 2);
        mmc_cmd_in              = 1'b0;
        #(`TB_CYCLE * 2);
        mmc_cmd_in              = 1'b1;
        #(`TB_CYCLE * 2);

        start_communication     = 1'b1;
        command_io              = 1'b1;
        clear_command_interrupt = 1'b1;
        #(`TB_CYCLE * 1);
        start_communication     = 1'b0;
        command_io              = 1'b0;
        clear_command_interrupt = 1'b0;

        // 0x00
        mmc_cmd_in              = 1'b0;
        #(`TB_CYCLE * 2);
        mmc_cmd_in              = 1'b0;
        #(`TB_CYCLE * 2);
        mmc_cmd_in              = 1'b0;
        #(`TB_CYCLE * 2);
        mmc_cmd_in              = 1'b0;
        #(`TB_CYCLE * 2);
        mmc_cmd_in              = 1'b0;
        #(`TB_CYCLE * 2);
        mmc_cmd_in              = 1'b0;
        #(`TB_CYCLE * 2);
        mmc_cmd_in              = 1'b0;
        #(`TB_CYCLE * 2);
        mmc_cmd_in              = 1'b0;
        #(`TB_CYCLE * 2);

        start_communication     = 1'b1;
        command_io              = 1'b1;
        clear_command_interrupt = 1'b1;
        #(`TB_CYCLE * 1);
        start_communication     = 1'b0;
        command_io              = 1'b0;
        clear_command_interrupt = 1'b0;

        // 0xFF
        mmc_cmd_in              = 1'b1;
        #(`TB_CYCLE * 2);
        mmc_cmd_in              = 1'b1;
        #(`TB_CYCLE * 2);
        mmc_cmd_in              = 1'b1;
        #(`TB_CYCLE * 2);
        mmc_cmd_in              = 1'b1;
        #(`TB_CYCLE * 2);
        mmc_cmd_in              = 1'b1;
        #(`TB_CYCLE * 2);
        mmc_cmd_in              = 1'b1;
        #(`TB_CYCLE * 2);
        mmc_cmd_in              = 1'b1;
        #(`TB_CYCLE * 2);
        mmc_cmd_in              = 1'b1;
        #(`TB_CYCLE * 2);

        start_communication     = 1'b1;
        command_io              = 1'b1;
        clear_command_interrupt = 1'b1;
        #(`TB_CYCLE * 1);
        start_communication     = 1'b0;
        command_io              = 1'b0;
        clear_command_interrupt = 1'b0;

        // 0x80
        mmc_cmd_in              = 1'b1;
        #(`TB_CYCLE * 2);
        mmc_cmd_in              = 1'b0;
        #(`TB_CYCLE * 2);
        mmc_cmd_in              = 1'b0;
        #(`TB_CYCLE * 2);
        mmc_cmd_in              = 1'b0;
        #(`TB_CYCLE * 2);
        mmc_cmd_in              = 1'b0;
        #(`TB_CYCLE * 2);
        mmc_cmd_in              = 1'b0;
        #(`TB_CYCLE * 2);
        mmc_cmd_in              = 1'b0;
        #(`TB_CYCLE * 2);
        mmc_cmd_in              = 1'b0;
        #(`TB_CYCLE * 2);

        start_communication     = 1'b1;
        command_io              = 1'b1;
        clear_command_interrupt = 1'b1;
        #(`TB_CYCLE * 1);
        start_communication     = 1'b0;
        command_io              = 1'b0;
        clear_command_interrupt = 1'b0;

        // 0x00
        mmc_cmd_in              = 1'b0;
        #(`TB_CYCLE * 2);
        mmc_cmd_in              = 1'b0;
        #(`TB_CYCLE * 2);
        mmc_cmd_in              = 1'b0;
        #(`TB_CYCLE * 2);
        mmc_cmd_in              = 1'b0;
        #(`TB_CYCLE * 2);
        mmc_cmd_in              = 1'b0;
        #(`TB_CYCLE * 2);
        mmc_cmd_in              = 1'b0;
        #(`TB_CYCLE * 2);
        mmc_cmd_in              = 1'b0;
        #(`TB_CYCLE * 2);
        mmc_cmd_in              = 1'b0;
        #(`TB_CYCLE * 2);
        mmc_cmd_in              = 1'b1;

        #(`TB_CYCLE * 12);
    end
    endtask

    logic   [15:0]  crc;
    //
    // Task : Send data test
    //
    task SEND_DATA_TEST();
    begin
        #(`TB_CYCLE * 0);
        start_communication     = 1'b1;
        command_io              = 1'b1;
        data_io                 = 1'b0;
        check_command_start_bit = 1'b1;
        check_data_start_bit    = 1'b1;
        clear_command_crc       = 1'b0;
        clear_data_crc          = 1'b1;
        clear_command_interrupt = 1'b0;
        clear_data_interrupt    = 1'b1;
        mask_command_interrupt  = 1'b1;
        mask_data_interrupt     = 1'b0;
        set_send_command        = 1'b0;
        send_command            = 8'h00;
        set_send_data           = 1'b1;
        send_data               = 8'hFE;    // send_data[0] = start bit(0)
        #(`TB_CYCLE * 1);
        start_communication     = 1'b0;
        clear_data_crc          = 1'b0;
        clear_data_interrupt    = 1'b0;
        set_send_data           = 1'b0;
        #(`TB_CYCLE * 24);
        start_communication     = 1'b1;
        clear_data_crc          = 1'b1;
        clear_data_interrupt    = 1'b1;
        set_send_data           = 1'b1;
        send_data               = 8'h40;
        #(`TB_CYCLE * 1);
        start_communication     = 1'b0;
        clear_data_crc          = 1'b0;
        clear_data_interrupt    = 1'b0;
        set_send_data           = 1'b0;
        #(`TB_CYCLE * 24);
        start_communication     = 1'b1;
        clear_data_interrupt    = 1'b1;
        set_send_data           = 1'b1;
        send_data               = 8'h12;
        #(`TB_CYCLE * 1);
        start_communication     = 1'b0;
        clear_data_interrupt    = 1'b0;
        set_send_data           = 1'b0;
        #(`TB_CYCLE * 24);
        start_communication     = 1'b1;
        clear_data_interrupt    = 1'b1;
        set_send_data           = 1'b1;
        send_data               = 8'h34;
        #(`TB_CYCLE * 1);
        start_communication     = 1'b0;
        clear_data_interrupt    = 1'b0;
        set_send_data           = 1'b0;
        #(`TB_CYCLE * 24);
        start_communication     = 1'b1;
        clear_data_interrupt    = 1'b1;
        set_send_data           = 1'b1;
        send_data               = 8'h56;
        #(`TB_CYCLE * 1);
        start_communication     = 1'b0;
        clear_data_interrupt    = 1'b0;
        set_send_data           = 1'b0;
        #(`TB_CYCLE * 24);
        start_communication     = 1'b1;
        clear_data_interrupt    = 1'b1;
        set_send_data           = 1'b1;
        send_data               = 8'h78;
        #(`TB_CYCLE * 1);
        start_communication     = 1'b0;
        clear_data_interrupt    = 1'b0;
        set_send_data           = 1'b0;
        #(`TB_CYCLE * 24);
        start_communication     = 1'b1;
        clear_data_interrupt    = 1'b1;
        set_send_data           = 1'b1;
        send_data               = 8'h9A;
        #(`TB_CYCLE * 1);
        start_communication     = 1'b0;
        clear_data_interrupt    = 1'b0;
        set_send_data           = 1'b0;
        #(`TB_CYCLE * 24);
        crc                     = send_data_crc;
        start_communication     = 1'b1;
        clear_data_interrupt    = 1'b1;
        set_send_data           = 1'b1;
        send_data               = crc[15:8];
        #(`TB_CYCLE * 1);
        start_communication     = 1'b0;
        clear_data_interrupt    = 1'b0;
        set_send_data           = 1'b0;
        #(`TB_CYCLE * 24);
        start_communication     = 1'b1;
        clear_data_interrupt    = 1'b1;
        set_send_data           = 1'b1;
        send_data               = crc[7:0];
        #(`TB_CYCLE * 1);
        start_communication     = 1'b0;
        clear_data_interrupt    = 1'b0;
        set_send_data           = 1'b0;
        #(`TB_CYCLE * 24);
    end
    endtask

    //
    // Task : Receive data test
    //
    task RECV_DATA_TEST();
    begin
        #(`TB_CYCLE * 0);
        start_communication     = 1'b1;
        command_io              = 1'b1;
        data_io                 = 1'b1;
        check_command_start_bit = 1'b1;
        check_data_start_bit    = 1'b1;
        clear_command_crc       = 1'b0;
        clear_data_crc          = 1'b1;
        clear_command_interrupt = 1'b0;
        clear_data_interrupt    = 1'b1;
        mask_command_interrupt  = 1'b1;
        mask_data_interrupt     = 1'b0;
        set_send_command        = 1'b0;
        send_command            = 8'h00;
        set_send_data           = 1'b0;
        send_data               = 8'h00;
        mmc_dat_in              = 1'b1;
        #(`TB_CYCLE * 1);
        start_communication     = 1'b0;
        data_io                 = 1'b0;
        check_data_start_bit    = 1'b0;
        clear_data_crc          = 1'b0;
        clear_data_interrupt    = 1'b0;
        #(`TB_CYCLE * 12);
        mmc_dat_in              = 1'b0; // start bit
        #(`TB_CYCLE * 2);

        // 0xFF
        mmc_dat_in              = 1'b1;
        #(`TB_CYCLE * 2);
        mmc_dat_in              = 1'b1;
        #(`TB_CYCLE * 2);
        mmc_dat_in              = 1'b1;
        #(`TB_CYCLE * 2);
        mmc_dat_in              = 1'b1;
        #(`TB_CYCLE * 2);
        mmc_dat_in              = 1'b1;
        #(`TB_CYCLE * 2);
        mmc_dat_in              = 1'b1;
        #(`TB_CYCLE * 2);
        mmc_dat_in              = 1'b1;
        #(`TB_CYCLE * 2);
        mmc_dat_in              = 1'b1;
        #(`TB_CYCLE * 2);

        start_communication     = 1'b1;
        data_io                 = 1'b1;
        clear_data_interrupt    = 1'b1;
        #(`TB_CYCLE * 1);
        start_communication     = 1'b0;
        data_io                 = 1'b0;
        clear_data_interrupt    = 1'b0;

        // 0x12
        mmc_dat_in              = 1'b0;
        #(`TB_CYCLE * 2);
        mmc_dat_in              = 1'b0;
        #(`TB_CYCLE * 2);
        mmc_dat_in              = 1'b0;
        #(`TB_CYCLE * 2);
        mmc_dat_in              = 1'b1;
        #(`TB_CYCLE * 2);
        mmc_dat_in              = 1'b0;
        #(`TB_CYCLE * 2);
        mmc_dat_in              = 1'b0;
        #(`TB_CYCLE * 2);
        mmc_dat_in              = 1'b1;
        #(`TB_CYCLE * 2);
        mmc_dat_in              = 1'b0;
        #(`TB_CYCLE * 2);

        mmc_dat_in              = 1'b1;
        #(`TB_CYCLE * 12);
    end
    endtask

    //
    // Task : Receive response and data test
    //
    task RECV_RESPONSE_AND_DATA_TEST();
    begin
        #(`TB_CYCLE * 0);
        start_communication     = 1'b1;
        command_io              = 1'b1;
        data_io                 = 1'b1;
        check_command_start_bit = 1'b1;
        check_data_start_bit    = 1'b1;
        clear_command_crc       = 1'b1;
        clear_data_crc          = 1'b1;
        clear_command_interrupt = 1'b1;
        clear_data_interrupt    = 1'b1;
        mask_command_interrupt  = 1'b0;
        mask_data_interrupt     = 1'b0;
        set_send_command        = 1'b0;
        send_command            = 8'h00;
        set_send_data           = 1'b0;
        send_data               = 8'h00;
        mmc_cmd_in              = 1'b1;
        mmc_dat_in              = 1'b1;
        #(`TB_CYCLE * 1);
        start_communication     = 1'b0;
        check_command_start_bit = 1'b0;
        check_data_start_bit    = 1'b0;
        clear_command_crc       = 1'b0;
        clear_data_crc          = 1'b0;
        clear_command_interrupt = 1'b0;
        clear_data_interrupt    = 1'b0;
        #(`TB_CYCLE * 12);
        mmc_cmd_in              = 1'b0;
        #(`TB_CYCLE * 12);
        mmc_dat_in              = 1'b0;
        #(`TB_CYCLE * 12);
        start_communication     = 1'b1;
        clear_command_interrupt = 1'b1;
        #(`TB_CYCLE * 1);
        start_communication     = 1'b0;
        clear_command_interrupt = 1'b0;
        #(`TB_CYCLE * 24);
    end
    endtask

    //
    // Test pattern
    //
    initial begin
        TASK_INIT();

        SEND_COMMAND_TEST();
        SEND_DATA_TEST();
        RESPONSE_COMMAND_TEST();
        RECV_DATA_TEST();
        RECV_RESPONSE_AND_DATA_TEST();

        // End of simulation
`ifdef IVERILOG
        $finish;
`elsif  MODELSIM
        $stop;
`else
        $finish;
`endif
    end
endmodule

