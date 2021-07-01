
`define TB_CYCLE        20
`define TB_FINISH_COUNT 20000

module KFMMC_Data_IO_tm();

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
    logic           disable_data_io;
    logic           start_data_io;
    logic           check_data_start_bit;
    logic           clear_data_crc;
    logic           data_io;
    logic   [7:0]   transmit_data;

    logic           data_io_busy;
    logic   [7:0]   received_data;

    logic           start_communication_to_mmc;
    logic           data_io_to_mmc;
    logic           check_data_start_bit_to_mmc;
    logic           read_continuous_data_to_mmc;
    logic           clear_data_crc_to_mmc;
    logic           clear_data_interrupt_to_mmc;
    logic           mask_data_interrupt_to_mmc;
    logic           set_send_data_to_mmc;
    logic   [7:0]   send_data_to_mmc;
    logic   [7:0]   received_data_from_mmc;

    logic           mmc_is_in_connecting;
    logic           sent_data_interrupt_from_mmc;
    logic           received_data_interrupt_from_mmc;

    KFMMC_Data_IO u_KFMMC_Data_IO(.*);

    //
    // Task : Initialization
    //
    task TASK_INIT();
    begin
        #(`TB_CYCLE * 0);
        disable_data_io         = 1'b1;
        start_data_io           = 1'b0;
        check_data_start_bit    = 1'b0;
        clear_data_crc          = 1'b0;
        data_io                 = 1'b1;
        transmit_data           = 8'h00;
        received_data_from_mmc  = 8'h00;
        mmc_is_in_connecting                = 1'b1;
        sent_data_interrupt_from_mmc        = 1'b0;
        received_data_interrupt_from_mmc    = 1'b0;
        #(`TB_CYCLE * 12);
    end
    endtask

    //
    // Test pattern
    //
    initial begin
        TASK_INIT();

        $display("***** SEND DATA ***** at %d", tb_cycle_counter);
        mmc_is_in_connecting                = 1'b1;
        sent_data_interrupt_from_mmc        = 1'b0;
        received_data_interrupt_from_mmc    = 1'b0;

        disable_data_io         = 1'b0;
        start_data_io           = 1'b1;
        data_io                 = 1'b0;
        transmit_data           = 8'hAB;
        #(`TB_CYCLE * 1);
        start_data_io           = 1'b0;
        transmit_data           = 8'h00;
        #(`TB_CYCLE * 2);
        mmc_is_in_connecting                = 1'b0;
        #(`TB_CYCLE * 2);
        mmc_is_in_connecting                = 1'b1;
        #(`TB_CYCLE * 4);
        mmc_is_in_connecting                = 1'b0;
        #(`TB_CYCLE * 1);
        mmc_is_in_connecting                = 1'b1;
        #(`TB_CYCLE * 4);
        mmc_is_in_connecting                = 1'b0;
        sent_data_interrupt_from_mmc        = 1'b1;
        received_data_interrupt_from_mmc    = 1'b0;
        #(`TB_CYCLE * 12);

        $display("***** RECV DATA ***** at %d", tb_cycle_counter);
        disable_data_io         = 1'b0;
        start_data_io           = 1'b1;
        data_io                 = 1'b1;
        #(`TB_CYCLE * 1);
        start_data_io           = 1'b0;
        #(`TB_CYCLE * 2);
        mmc_is_in_connecting                = 1'b0;
        #(`TB_CYCLE * 2);
        mmc_is_in_connecting                = 1'b1;
        sent_data_interrupt_from_mmc        = 1'b0;
        received_data_interrupt_from_mmc    = 1'b0;
        #(`TB_CYCLE * 4);
        mmc_is_in_connecting                = 1'b0;
        #(`TB_CYCLE * 1);
        mmc_is_in_connecting                = 1'b1;
        #(`TB_CYCLE * 4);
        received_data_from_mmc  = 8'hCD;
        mmc_is_in_connecting                = 1'b0;
        sent_data_interrupt_from_mmc        = 1'b0;
        received_data_interrupt_from_mmc    = 1'b1;
        #(`TB_CYCLE * 12);

        $display("***** CLEAR CRC (SEND DATA) ***** at %d", tb_cycle_counter);
        disable_data_io         = 1'b0;
        start_data_io           = 1'b1;
        clear_data_crc          = 1'b1;
        data_io                 = 1'b0;
        transmit_data           = 8'hEF;
        #(`TB_CYCLE * 1);
        start_data_io           = 1'b0;
        clear_data_crc          = 1'b0;
        transmit_data           = 8'h00;
        #(`TB_CYCLE * 1);
        mmc_is_in_connecting                = 1'b0;
        #(`TB_CYCLE * 1);
        mmc_is_in_connecting                = 1'b1;
        sent_data_interrupt_from_mmc        = 1'b0;
        received_data_interrupt_from_mmc    = 1'b0;
        #(`TB_CYCLE * 8);
        mmc_is_in_connecting                = 1'b0;
        sent_data_interrupt_from_mmc        = 1'b1;
        received_data_interrupt_from_mmc    = 1'b0;
        #(`TB_CYCLE * 12);

        $display("***** CLEAR CRC (RECV DATA) ***** at %d", tb_cycle_counter);
        disable_data_io         = 1'b0;
        start_data_io           = 1'b1;
        clear_data_crc          = 1'b1;
        data_io                 = 1'b1;
        #(`TB_CYCLE * 1);
        start_data_io           = 1'b0;
        clear_data_crc          = 1'b0;
        #(`TB_CYCLE * 1);
        mmc_is_in_connecting                = 1'b0;
        #(`TB_CYCLE * 1);
        mmc_is_in_connecting                = 1'b1;
        sent_data_interrupt_from_mmc        = 1'b0;
        received_data_interrupt_from_mmc    = 1'b0;
        #(`TB_CYCLE * 8);
        received_data_from_mmc  = 8'hBA;
        mmc_is_in_connecting                = 1'b0;
        sent_data_interrupt_from_mmc        = 1'b0;
        received_data_interrupt_from_mmc    = 1'b1;
        #(`TB_CYCLE * 12);

        $display("***** START BIT (RECV DATA) ***** at %d", tb_cycle_counter);
        disable_data_io         = 1'b0;
        start_data_io           = 1'b1;
        check_data_start_bit    = 1'b1;
        data_io                 = 1'b1;
        #(`TB_CYCLE * 1);
        start_data_io           = 1'b0;
        check_data_start_bit    = 1'b0;
        #(`TB_CYCLE * 1);
        mmc_is_in_connecting                = 1'b0;
        #(`TB_CYCLE * 1);
        mmc_is_in_connecting                = 1'b1;
        sent_data_interrupt_from_mmc        = 1'b0;
        received_data_interrupt_from_mmc    = 1'b0;
        #(`TB_CYCLE * 8);
        received_data_from_mmc  = 8'hDC;
        mmc_is_in_connecting                = 1'b0;
        sent_data_interrupt_from_mmc        = 1'b0;
        received_data_interrupt_from_mmc    = 1'b1;
        #(`TB_CYCLE * 12);

        $display("***** DISABLE TEST ***** at %d", tb_cycle_counter);
        disable_data_io         = 1'b1;
        #(`TB_CYCLE * 1);
        disable_data_io         = 1'b0;
        #(`TB_CYCLE * 12);


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

