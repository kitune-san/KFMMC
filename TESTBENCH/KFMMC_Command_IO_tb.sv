
`define TB_CYCLE        20
`define TB_FINISH_COUNT 20000

module KFMMC_Command_IO_tm();

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
    //
    logic           reset_command_state;

    logic           start_command;
    logic   [47:0]  command;
    logic           enable_command_crc;
    logic           enable_response_crc;
    logic   [4:0]   response_length;

    logic           command_busy;
    logic   [135:0] response;
    logic           response_error;

    logic           start_communication_to_mmc;
    logic           command_io_to_mmc;
    logic           check_command_start_bit_to_mmc;
    logic           clear_command_crc_to_mmc;
    logic           clear_command_interrupt_to_mmc;
    logic           mask_command_interrupt_to_mmc;
    logic           set_send_command_to_mmc;
    logic   [7:0]   send_command_to_mmc;

    logic   [7:0]   received_response_from_mmc;
    logic   [6:0]   send_command_crc_from_mmc;
    logic   [6:0]   received_response_crc_from_mmc;

    logic           mmc_is_in_connecting;
    logic           sent_command_interrupt_from_mmc;
    logic           received_response_interrupt_from_mmc;

    KFMMC_Command_IO u_KFMMC_Command_IO(.*);

    //
    // Calculate CRC
    //
    // CRC-7
    function logic [6:0] crc_7 (input data_in, input [6:0] prev_crc);
        crc_7[0] = prev_crc[6] ^ data_in;
        crc_7[1] = prev_crc[0];
        crc_7[2] = prev_crc[1];
        crc_7[3] = prev_crc[2] ^ (prev_crc[6] ^ data_in);
        crc_7[4] = prev_crc[3];
        crc_7[5] = prev_crc[4];
        crc_7[6] = prev_crc[5];
    endfunction

    //
    // Task : Initialization
    //
    task TASK_INIT();
    begin
        #(`TB_CYCLE * 0);
        reset_command_state                     = 1'b0;
        start_command                           = 1'b0;
        command                                 = 48'hFFFFFFFFFFFF;
        enable_command_crc                      = 1'b0;
        enable_response_crc                     = 1'b0;
        response_length                         = 5'b000;
        received_response_from_mmc              = 8'hFF;
        send_command_crc_from_mmc               = 7'h7F;
        received_response_crc_from_mmc          = 7'h7F;
        mmc_is_in_connecting                    = 1'b0;
        sent_command_interrupt_from_mmc         = 1'b0;
        received_response_interrupt_from_mmc    = 1'b0;
        #(`TB_CYCLE * 12);
    end
    endtask

    //
    // Task : SPI send-receive test
    //
    task TASK_SEND_RECEIVE_TEST(input [47:0] send_data, input [55:0] recv_data, input [3:0] recv_data_length, input send_crc_flag, input recv_crc_flag, input switch_recv_data_crc);
    begin
        #(`TB_CYCLE * 0);
        reset_command_state                     = 1'b0;
        start_command                           = 1'b1;
        command                                 = send_data;
        enable_command_crc                      = send_crc_flag;
        enable_response_crc                     = recv_crc_flag;
        response_length                         = recv_data_length;
        received_response_from_mmc              = 8'hFF;
        send_command_crc_from_mmc               = 7'h00;
        received_response_crc_from_mmc          = 7'h00;
        mmc_is_in_connecting                    = 1'b0;
        sent_command_interrupt_from_mmc         = 1'b0;
        received_response_interrupt_from_mmc    = 1'b0;
        #(`TB_CYCLE * 1);
        start_command                           = 1'b0;
        #(`TB_CYCLE * 1);
        mmc_is_in_connecting                    = 1'b1;
        #(`TB_CYCLE * 1);
        send_command_crc_from_mmc               = crc_7(send_data[47], send_command_crc_from_mmc);
        #(`TB_CYCLE * 1);
        send_command_crc_from_mmc               = crc_7(send_data[46], send_command_crc_from_mmc);
        #(`TB_CYCLE * 1);
        send_command_crc_from_mmc               = crc_7(send_data[45], send_command_crc_from_mmc);
        #(`TB_CYCLE * 1);
        send_command_crc_from_mmc               = crc_7(send_data[44], send_command_crc_from_mmc);
        #(`TB_CYCLE * 1);
        mmc_is_in_connecting                    = 1'b0;
        #(`TB_CYCLE * 2);
        mmc_is_in_connecting                    = 1'b1;
        #(`TB_CYCLE * 1);
        send_command_crc_from_mmc               = crc_7(send_data[43], send_command_crc_from_mmc);
        #(`TB_CYCLE * 1);
        send_command_crc_from_mmc               = crc_7(send_data[42], send_command_crc_from_mmc);
        #(`TB_CYCLE * 1);
        send_command_crc_from_mmc               = crc_7(send_data[41], send_command_crc_from_mmc);
        #(`TB_CYCLE * 1);
        send_command_crc_from_mmc               = crc_7(send_data[40], send_command_crc_from_mmc);
        #(`TB_CYCLE * 1);
        sent_command_interrupt_from_mmc         = 1'b1;
        mmc_is_in_connecting                    = 1'b0;
        #(`TB_CYCLE * 1);
        sent_command_interrupt_from_mmc         = 1'b0;
        mmc_is_in_connecting                    = 1'b1;
        #(`TB_CYCLE * 1);
        send_command_crc_from_mmc               = crc_7(send_data[39], send_command_crc_from_mmc);
        #(`TB_CYCLE * 1);
        send_command_crc_from_mmc               = crc_7(send_data[38], send_command_crc_from_mmc);
        #(`TB_CYCLE * 1);
        send_command_crc_from_mmc               = crc_7(send_data[37], send_command_crc_from_mmc);
        #(`TB_CYCLE * 1);
        send_command_crc_from_mmc               = crc_7(send_data[36], send_command_crc_from_mmc);
        #(`TB_CYCLE * 1);
        send_command_crc_from_mmc               = crc_7(send_data[35], send_command_crc_from_mmc);
        #(`TB_CYCLE * 1);
        send_command_crc_from_mmc               = crc_7(send_data[34], send_command_crc_from_mmc);
        #(`TB_CYCLE * 1);
        send_command_crc_from_mmc               = crc_7(send_data[33], send_command_crc_from_mmc);
        #(`TB_CYCLE * 1);
        send_command_crc_from_mmc               = crc_7(send_data[32], send_command_crc_from_mmc);
        #(`TB_CYCLE * 1);
        sent_command_interrupt_from_mmc         = 1'b1;
        mmc_is_in_connecting                    = 1'b0;
        #(`TB_CYCLE * 1);
        sent_command_interrupt_from_mmc         = 1'b0;
        mmc_is_in_connecting                    = 1'b1;
        #(`TB_CYCLE * 1);
        send_command_crc_from_mmc               = crc_7(send_data[31], send_command_crc_from_mmc);
        #(`TB_CYCLE * 1);
        send_command_crc_from_mmc               = crc_7(send_data[30], send_command_crc_from_mmc);
        #(`TB_CYCLE * 1);
        send_command_crc_from_mmc               = crc_7(send_data[29], send_command_crc_from_mmc);
        #(`TB_CYCLE * 1);
        send_command_crc_from_mmc               = crc_7(send_data[28], send_command_crc_from_mmc);
        #(`TB_CYCLE * 1);
        send_command_crc_from_mmc               = crc_7(send_data[27], send_command_crc_from_mmc);
        #(`TB_CYCLE * 1);
        send_command_crc_from_mmc               = crc_7(send_data[26], send_command_crc_from_mmc);
        #(`TB_CYCLE * 1);
        send_command_crc_from_mmc               = crc_7(send_data[25], send_command_crc_from_mmc);
        #(`TB_CYCLE * 1);
        send_command_crc_from_mmc               = crc_7(send_data[24], send_command_crc_from_mmc);
        sent_command_interrupt_from_mmc         = 1'b1;
        mmc_is_in_connecting                    = 1'b0;
        #(`TB_CYCLE * 1);
        sent_command_interrupt_from_mmc         = 1'b0;
        mmc_is_in_connecting                    = 1'b1;
        #(`TB_CYCLE * 1);
        send_command_crc_from_mmc               = crc_7(send_data[23], send_command_crc_from_mmc);
        #(`TB_CYCLE * 1);
        send_command_crc_from_mmc               = crc_7(send_data[22], send_command_crc_from_mmc);
        #(`TB_CYCLE * 1);
        send_command_crc_from_mmc               = crc_7(send_data[21], send_command_crc_from_mmc);
        #(`TB_CYCLE * 1);
        send_command_crc_from_mmc               = crc_7(send_data[20], send_command_crc_from_mmc);
        #(`TB_CYCLE * 1);
        send_command_crc_from_mmc               = crc_7(send_data[19], send_command_crc_from_mmc);
        #(`TB_CYCLE * 1);
        send_command_crc_from_mmc               = crc_7(send_data[18], send_command_crc_from_mmc);
        #(`TB_CYCLE * 1);
        send_command_crc_from_mmc               = crc_7(send_data[17], send_command_crc_from_mmc);
        #(`TB_CYCLE * 1);
        send_command_crc_from_mmc               = crc_7(send_data[16], send_command_crc_from_mmc);
        #(`TB_CYCLE * 1);
        sent_command_interrupt_from_mmc         = 1'b1;
        mmc_is_in_connecting                    = 1'b0;
        #(`TB_CYCLE * 1);
        sent_command_interrupt_from_mmc         = 1'b0;
        mmc_is_in_connecting                    = 1'b1;
        #(`TB_CYCLE * 1);
        send_command_crc_from_mmc               = crc_7(send_data[15], send_command_crc_from_mmc);
        #(`TB_CYCLE * 1);
        send_command_crc_from_mmc               = crc_7(send_data[14], send_command_crc_from_mmc);
        #(`TB_CYCLE * 1);
        send_command_crc_from_mmc               = crc_7(send_data[13], send_command_crc_from_mmc);
        #(`TB_CYCLE * 1);
        send_command_crc_from_mmc               = crc_7(send_data[12], send_command_crc_from_mmc);
        #(`TB_CYCLE * 1);
        send_command_crc_from_mmc               = crc_7(send_data[11], send_command_crc_from_mmc);
        #(`TB_CYCLE * 1);
        send_command_crc_from_mmc               = crc_7(send_data[10], send_command_crc_from_mmc);
        #(`TB_CYCLE * 1);
        send_command_crc_from_mmc               = crc_7(send_data[9], send_command_crc_from_mmc);
        #(`TB_CYCLE * 1);
        send_command_crc_from_mmc               = crc_7(send_data[8], send_command_crc_from_mmc);
        #(`TB_CYCLE * 1);
        sent_command_interrupt_from_mmc         = 1'b1;
        mmc_is_in_connecting                    = 1'b0;
        #(`TB_CYCLE * 1);
        sent_command_interrupt_from_mmc         = 1'b0;
        mmc_is_in_connecting                    = 1'b1;
        #(`TB_CYCLE * 1);
        send_command_crc_from_mmc               = crc_7(send_data[7], send_command_crc_from_mmc);
        #(`TB_CYCLE * 1);
        send_command_crc_from_mmc               = crc_7(send_data[6], send_command_crc_from_mmc);
        #(`TB_CYCLE * 1);
        send_command_crc_from_mmc               = crc_7(send_data[5], send_command_crc_from_mmc);
        #(`TB_CYCLE * 1);
        send_command_crc_from_mmc               = crc_7(send_data[4], send_command_crc_from_mmc);
        #(`TB_CYCLE * 1);
        send_command_crc_from_mmc               = crc_7(send_data[3], send_command_crc_from_mmc);
        #(`TB_CYCLE * 1);
        send_command_crc_from_mmc               = crc_7(send_data[2], send_command_crc_from_mmc);
        #(`TB_CYCLE * 1);
        send_command_crc_from_mmc               = crc_7(send_data[1], send_command_crc_from_mmc);
        #(`TB_CYCLE * 1);
        send_command_crc_from_mmc               = crc_7(send_data[0], send_command_crc_from_mmc);
        #(`TB_CYCLE * 1);
        sent_command_interrupt_from_mmc         = 1'b1;
        mmc_is_in_connecting                    = 1'b0;

        #(`TB_CYCLE * 12);

        if (recv_data_length > 4'd0) begin
            sent_command_interrupt_from_mmc         = 1'b0;
            mmc_is_in_connecting                    = 1'b1;
            #(`TB_CYCLE * 1);
            received_response_from_mmc              = {received_response_from_mmc[6:0], recv_data[55]};
            received_response_crc_from_mmc          = crc_7(recv_data[55], received_response_crc_from_mmc);
            #(`TB_CYCLE * 1);
            received_response_from_mmc              = {received_response_from_mmc[6:0], recv_data[54]};
            received_response_crc_from_mmc          = crc_7(recv_data[54], received_response_crc_from_mmc);
            #(`TB_CYCLE * 1);
            received_response_from_mmc              = {received_response_from_mmc[6:0], recv_data[53]};
            received_response_crc_from_mmc          = crc_7(recv_data[53], received_response_crc_from_mmc);
            #(`TB_CYCLE * 1);
            received_response_from_mmc              = {received_response_from_mmc[6:0], recv_data[52]};
            received_response_crc_from_mmc          = crc_7(recv_data[52], received_response_crc_from_mmc);
            #(`TB_CYCLE * 1);
            mmc_is_in_connecting                    = 1'b0;
            #(`TB_CYCLE * 2);
            mmc_is_in_connecting                    = 1'b1;
            #(`TB_CYCLE * 1);
            received_response_from_mmc              = {received_response_from_mmc[6:0], recv_data[51]};
            received_response_crc_from_mmc          = crc_7(recv_data[51], received_response_crc_from_mmc);
            #(`TB_CYCLE * 1);
            received_response_from_mmc              = {received_response_from_mmc[6:0], recv_data[50]};
            received_response_crc_from_mmc          = crc_7(recv_data[50], received_response_crc_from_mmc);
            #(`TB_CYCLE * 1);
            received_response_from_mmc              = {received_response_from_mmc[6:0], recv_data[49]};
            received_response_crc_from_mmc          = crc_7(recv_data[49], received_response_crc_from_mmc);
            #(`TB_CYCLE * 1);
            received_response_from_mmc              = {received_response_from_mmc[6:0], recv_data[48]};
            received_response_crc_from_mmc          = crc_7(recv_data[48], received_response_crc_from_mmc);
            #(`TB_CYCLE * 1);
            received_response_interrupt_from_mmc    = 1'b1;
            mmc_is_in_connecting                    = 1'b0;
            #(`TB_CYCLE * 1);
        end

        if (recv_data_length > 4'd1) begin
            received_response_interrupt_from_mmc    = 1'b0;
            mmc_is_in_connecting                    = 1'b1;
            #(`TB_CYCLE * 1);
            received_response_from_mmc              = {received_response_from_mmc[6:0], recv_data[47]};
            received_response_crc_from_mmc          = crc_7(recv_data[47], received_response_crc_from_mmc);
            #(`TB_CYCLE * 1);
            received_response_from_mmc              = {received_response_from_mmc[6:0], recv_data[46]};
            received_response_crc_from_mmc          = crc_7(recv_data[46], received_response_crc_from_mmc);
            #(`TB_CYCLE * 1);
            received_response_from_mmc              = {received_response_from_mmc[6:0], recv_data[45]};
            received_response_crc_from_mmc          = crc_7(recv_data[45], received_response_crc_from_mmc);
            #(`TB_CYCLE * 1);
            received_response_from_mmc              = {received_response_from_mmc[6:0], recv_data[44]};
            received_response_crc_from_mmc          = crc_7(recv_data[44], received_response_crc_from_mmc);
            #(`TB_CYCLE * 1);
            received_response_from_mmc              = {received_response_from_mmc[6:0], recv_data[43]};
            received_response_crc_from_mmc          = crc_7(recv_data[43], received_response_crc_from_mmc);
            #(`TB_CYCLE * 1);
            received_response_from_mmc              = {received_response_from_mmc[6:0], recv_data[42]};
            received_response_crc_from_mmc          = crc_7(recv_data[42], received_response_crc_from_mmc);
            #(`TB_CYCLE * 1);
            received_response_from_mmc              = {received_response_from_mmc[6:0], recv_data[41]};
            received_response_crc_from_mmc          = crc_7(recv_data[41], received_response_crc_from_mmc);
            #(`TB_CYCLE * 1);
            received_response_from_mmc              = {received_response_from_mmc[6:0], recv_data[40]};
            received_response_crc_from_mmc          = crc_7(recv_data[40], received_response_crc_from_mmc);
            #(`TB_CYCLE * 1);
            received_response_interrupt_from_mmc    = 1'b1;
            mmc_is_in_connecting                    = 1'b0;
            #(`TB_CYCLE * 1);
        end

        if (recv_data_length > 4'd2) begin
            received_response_interrupt_from_mmc    = 1'b0;
            mmc_is_in_connecting                    = 1'b1;
            #(`TB_CYCLE * 1);
            received_response_from_mmc              = {received_response_from_mmc[6:0], recv_data[39]};
            received_response_crc_from_mmc          = crc_7(recv_data[39], received_response_crc_from_mmc);
            #(`TB_CYCLE * 1);
            received_response_from_mmc              = {received_response_from_mmc[6:0], recv_data[38]};
            received_response_crc_from_mmc          = crc_7(recv_data[38], received_response_crc_from_mmc);
            #(`TB_CYCLE * 1);
            received_response_from_mmc              = {received_response_from_mmc[6:0], recv_data[37]};
            received_response_crc_from_mmc          = crc_7(recv_data[37], received_response_crc_from_mmc);
            #(`TB_CYCLE * 1);
            received_response_from_mmc              = {received_response_from_mmc[6:0], recv_data[36]};
            received_response_crc_from_mmc          = crc_7(recv_data[36], received_response_crc_from_mmc);
            #(`TB_CYCLE * 1);
            received_response_from_mmc              = {received_response_from_mmc[6:0], recv_data[35]};
            received_response_crc_from_mmc          = crc_7(recv_data[35], received_response_crc_from_mmc);
            #(`TB_CYCLE * 1);
            received_response_from_mmc              = {received_response_from_mmc[6:0], recv_data[34]};
            received_response_crc_from_mmc          = crc_7(recv_data[34], received_response_crc_from_mmc);
            #(`TB_CYCLE * 1);
            received_response_from_mmc              = {received_response_from_mmc[6:0], recv_data[33]};
            received_response_crc_from_mmc          = crc_7(recv_data[33], received_response_crc_from_mmc);
            #(`TB_CYCLE * 1);
            received_response_from_mmc              = {received_response_from_mmc[6:0], recv_data[32]};
            received_response_crc_from_mmc          = crc_7(recv_data[32], received_response_crc_from_mmc);
            #(`TB_CYCLE * 1);
            received_response_interrupt_from_mmc    = 1'b1;
            mmc_is_in_connecting                    = 1'b0;
            #(`TB_CYCLE * 1);
        end

        if (recv_data_length > 4'd3) begin
            received_response_interrupt_from_mmc    = 1'b0;
            mmc_is_in_connecting                    = 1'b1;
            #(`TB_CYCLE * 1);
            received_response_from_mmc              = {received_response_from_mmc[6:0], recv_data[31]};
            received_response_crc_from_mmc          = crc_7(recv_data[31], received_response_crc_from_mmc);
            #(`TB_CYCLE * 1);
            received_response_from_mmc              = {received_response_from_mmc[6:0], recv_data[30]};
            received_response_crc_from_mmc          = crc_7(recv_data[30], received_response_crc_from_mmc);
            #(`TB_CYCLE * 1);
            received_response_from_mmc              = {received_response_from_mmc[6:0], recv_data[29]};
            received_response_crc_from_mmc          = crc_7(recv_data[29], received_response_crc_from_mmc);
            #(`TB_CYCLE * 1);
            received_response_from_mmc              = {received_response_from_mmc[6:0], recv_data[28]};
            received_response_crc_from_mmc          = crc_7(recv_data[28], received_response_crc_from_mmc);
            #(`TB_CYCLE * 1);
            received_response_from_mmc              = {received_response_from_mmc[6:0], recv_data[27]};
            received_response_crc_from_mmc          = crc_7(recv_data[27], received_response_crc_from_mmc);
            #(`TB_CYCLE * 1);
            received_response_from_mmc              = {received_response_from_mmc[6:0], recv_data[26]};
            received_response_crc_from_mmc          = crc_7(recv_data[26], received_response_crc_from_mmc);
            #(`TB_CYCLE * 1);
            received_response_from_mmc              = {received_response_from_mmc[6:0], recv_data[25]};
            received_response_crc_from_mmc          = crc_7(recv_data[25], received_response_crc_from_mmc);
            #(`TB_CYCLE * 1);
            received_response_from_mmc              = {received_response_from_mmc[6:0], recv_data[24]};
            received_response_crc_from_mmc          = crc_7(recv_data[24], received_response_crc_from_mmc);
            #(`TB_CYCLE * 1);
            received_response_interrupt_from_mmc    = 1'b1;
            mmc_is_in_connecting                    = 1'b0;
            #(`TB_CYCLE * 1);
        end

        if (recv_data_length > 4'd4) begin
            received_response_interrupt_from_mmc    = 1'b0;
            mmc_is_in_connecting                    = 1'b1;
            #(`TB_CYCLE * 1);
            received_response_from_mmc              = {received_response_from_mmc[6:0], recv_data[23]};
            received_response_crc_from_mmc          = crc_7(recv_data[23], received_response_crc_from_mmc);
            #(`TB_CYCLE * 1);
            received_response_from_mmc              = {received_response_from_mmc[6:0], recv_data[22]};
            received_response_crc_from_mmc          = crc_7(recv_data[22], received_response_crc_from_mmc);
            #(`TB_CYCLE * 1);
            received_response_from_mmc              = {received_response_from_mmc[6:0], recv_data[21]};
            received_response_crc_from_mmc          = crc_7(recv_data[21], received_response_crc_from_mmc);
            #(`TB_CYCLE * 1);
            received_response_from_mmc              = {received_response_from_mmc[6:0], recv_data[20]};
            received_response_crc_from_mmc          = crc_7(recv_data[20], received_response_crc_from_mmc);
            #(`TB_CYCLE * 1);
            received_response_from_mmc              = {received_response_from_mmc[6:0], recv_data[19]};
            received_response_crc_from_mmc          = crc_7(recv_data[19], received_response_crc_from_mmc);
            #(`TB_CYCLE * 1);
            received_response_from_mmc              = {received_response_from_mmc[6:0], recv_data[18]};
            received_response_crc_from_mmc          = crc_7(recv_data[18], received_response_crc_from_mmc);
            #(`TB_CYCLE * 1);
            received_response_from_mmc              = {received_response_from_mmc[6:0], recv_data[17]};
            received_response_crc_from_mmc          = crc_7(recv_data[17], received_response_crc_from_mmc);
            #(`TB_CYCLE * 1);
            received_response_from_mmc              = {received_response_from_mmc[6:0], recv_data[16]};
            received_response_crc_from_mmc          = crc_7(recv_data[16], received_response_crc_from_mmc);
            #(`TB_CYCLE * 1);
            received_response_interrupt_from_mmc    = 1'b1;
            mmc_is_in_connecting                    = 1'b0;
            #(`TB_CYCLE * 1);
        end

        if (recv_data_length > 4'd5) begin
            received_response_interrupt_from_mmc    = 1'b0;
            mmc_is_in_connecting                    = 1'b1;
            #(`TB_CYCLE * 1);
            received_response_from_mmc              = {received_response_from_mmc[6:0], recv_data[15]};
            received_response_crc_from_mmc          = crc_7(recv_data[15], received_response_crc_from_mmc);
            #(`TB_CYCLE * 1);
            received_response_from_mmc              = {received_response_from_mmc[6:0], recv_data[14]};
            received_response_crc_from_mmc          = crc_7(recv_data[14], received_response_crc_from_mmc);
            #(`TB_CYCLE * 1);
            received_response_from_mmc              = {received_response_from_mmc[6:0], recv_data[13]};
            received_response_crc_from_mmc          = crc_7(recv_data[13], received_response_crc_from_mmc);
            #(`TB_CYCLE * 1);
            received_response_from_mmc              = {received_response_from_mmc[6:0], recv_data[12]};
            received_response_crc_from_mmc          = crc_7(recv_data[12], received_response_crc_from_mmc);
            #(`TB_CYCLE * 1);
            received_response_from_mmc              = {received_response_from_mmc[6:0], recv_data[11]};
            received_response_crc_from_mmc          = crc_7(recv_data[11], received_response_crc_from_mmc);
            #(`TB_CYCLE * 1);
            received_response_from_mmc              = {received_response_from_mmc[6:0], recv_data[10]};
            received_response_crc_from_mmc          = crc_7(recv_data[10], received_response_crc_from_mmc);
            #(`TB_CYCLE * 1);
            received_response_from_mmc              = {received_response_from_mmc[6:0], recv_data[9]};
            received_response_crc_from_mmc          = crc_7(recv_data[9], received_response_crc_from_mmc);
            #(`TB_CYCLE * 1);
            received_response_from_mmc              = {received_response_from_mmc[6:0], recv_data[8]};
            received_response_crc_from_mmc          = crc_7(recv_data[8], received_response_crc_from_mmc);
            #(`TB_CYCLE * 1);
            received_response_interrupt_from_mmc    = 1'b1;
            mmc_is_in_connecting                    = 1'b0;
            #(`TB_CYCLE * 1);
        end

        if (recv_data_length > 4'd6) begin
            received_response_interrupt_from_mmc    = 1'b0;
            mmc_is_in_connecting                    = 1'b1;
            #(`TB_CYCLE * 1);
            if (switch_recv_data_crc == 1'b0) begin
                received_response_from_mmc              = {received_response_from_mmc[6:0], recv_data[7]};
                #(`TB_CYCLE * 1);
                received_response_from_mmc              = {received_response_from_mmc[6:0], recv_data[6]};
                #(`TB_CYCLE * 1);
                received_response_from_mmc              = {received_response_from_mmc[6:0], recv_data[5]};
                #(`TB_CYCLE * 1);
                received_response_from_mmc              = {received_response_from_mmc[6:0], recv_data[4]};
                #(`TB_CYCLE * 1);
                received_response_from_mmc              = {received_response_from_mmc[6:0], recv_data[3]};
                #(`TB_CYCLE * 1);
                received_response_from_mmc              = {received_response_from_mmc[6:0], recv_data[2]};
                #(`TB_CYCLE * 1);
                received_response_from_mmc              = {received_response_from_mmc[6:0], recv_data[1]};
                #(`TB_CYCLE * 1);
                received_response_from_mmc              = {received_response_from_mmc[6:0], recv_data[0]};
                #(`TB_CYCLE * 1);
            end
            else begin
                received_response_from_mmc              = {received_response_from_mmc[6:0], received_response_crc_from_mmc[6]};
                #(`TB_CYCLE * 1);
                received_response_from_mmc              = {received_response_from_mmc[6:0], received_response_crc_from_mmc[5]};
                #(`TB_CYCLE * 1);
                received_response_from_mmc              = {received_response_from_mmc[6:0], received_response_crc_from_mmc[4]};
                #(`TB_CYCLE * 1);
                received_response_from_mmc              = {received_response_from_mmc[6:0], received_response_crc_from_mmc[3]};
                #(`TB_CYCLE * 1);
                received_response_from_mmc              = {received_response_from_mmc[6:0], received_response_crc_from_mmc[2]};
                #(`TB_CYCLE * 1);
                received_response_from_mmc              = {received_response_from_mmc[6:0], received_response_crc_from_mmc[1]};
                #(`TB_CYCLE * 1);
                received_response_from_mmc              = {received_response_from_mmc[6:0], received_response_crc_from_mmc[0]};
                #(`TB_CYCLE * 1);
                received_response_from_mmc              = {received_response_from_mmc[6:0], 1'b1};
                #(`TB_CYCLE * 1);
            end
            received_response_interrupt_from_mmc    = 1'b1;
            mmc_is_in_connecting                    = 1'b0;
            #(`TB_CYCLE * 1);
        end

        #(`TB_CYCLE * 12);
    end
    endtask

    //
    // Test patter;
    //
    initial begin
        TASK_INIT();
        TASK_SEND_RECEIVE_TEST(48'h0123456789AB, 56'h123456789ABCDE, 4'd0, 1'b0, 1'b0, 1'b0);
        TASK_SEND_RECEIVE_TEST(48'h0123456789AB, 56'h123456789ABCDE, 4'd7, 1'b0, 1'b0, 1'b0);
        TASK_SEND_RECEIVE_TEST(48'h400000000000, 56'h01000000000000, 4'd1, 1'b1, 1'b0, 1'b0);
        TASK_SEND_RECEIVE_TEST(48'h48000001AA00, 56'h01000001AA0000, 4'd5, 1'b1, 1'b0, 1'b0);
        TASK_SEND_RECEIVE_TEST(48'h0123456789AB, 56'h123456789ABCDE, 4'd7, 1'b0, 1'b1, 1'b0);
        TASK_SEND_RECEIVE_TEST(48'h0123456789AB, 56'h123456789ABCDE, 4'd7, 1'b0, 1'b1, 1'b1);

        TASK_SEND_RECEIVE_TEST(48'h0123456789AB, 56'h123456789ABCDE, 4'd7, 1'b0, 1'b1, 1'b0);
        reset_command_state = 1'b1;
        #(`TB_CYCLE * 1);
        reset_command_state = 1'b0;
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

