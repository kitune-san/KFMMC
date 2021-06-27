
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

    logic   clock;
    logic   reset;
    logic   drive_busy;

    logic   mmc_cmd_in;
    logic   mmc_cmd_out;
    logic   mmc_cmd_io;
    logic   mmc_dat_in;
    logic   mmc_dat_out;
    logic   mmc_dat_io;


    //
    // PLL
    //
    PLL PLL (
        .refclk     (CLK),
        .rst        (1'b0),
        .outclk_0   (clock)
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

    KFMMC_Drive #(
        .init_spi_clock_cycle   (8'd020),
        .normal_spi_clock_cycle (8'd002),
        .timeout                (32'h000FFFF0)
    ) u_KFMMC_Drive (
        .clock                  (clock),
        .reset                  (reset),

        .internal_data_bus      (8'b00000000),
        .write_data             (1'b0),
        .read_data              (1'b0),

        //.drive_selected         (),
        .drive_busy             (drive_busy),

        //.interrupt              (),
        .terminal_count         (1'b0),

        .mmc_clk                (MMC_CLK),
        .mmc_cmd_in             (mmc_cmd_in),
        .mmc_cmd_out            (mmc_cmd_out),
        .mmc_cmd_io             (mmc_cmd_io),
        .mmc_dat_in             (mmc_dat_in),
        .mmc_dat_out            (mmc_dat_out),
        .mmc_dat_io             (mmc_dat_io)
    );

    assign  MMC_CMD     = (~mmc_cmd_io & ~mmc_cmd_out) ? 1'b0 : 1'bz;
    assign  mmc_cmd_in  = MMC_CMD;

    assign  MMC_DATA[0] = (~mmc_dat_io & ~mmc_dat_out) ? 1'b0 : 1'bz;
    assign  mmc_dat_in  = MMC_DATA[0];
    assign  MMC_DATA[1] = 1'b1;
    assign  MMC_DATA[2] = 1'b1;
    assign  MMC_DATA[3] = 1'b1;

    assign  LED[0]  = MMC_CLK;
    assign  LED[1]  = mmc_cmd_in;
    assign  LED[2]  = mmc_dat_in;
    assign  LED[3]  = 1'b0;
    assign  LED[4]  = 1'b0;
    assign  LED[5]  = 1'b0;
    assign  LED[6]  = 1'b0;
    assign  LED[7]  = 1'b0;
    assign  LED[8]  = 1'b0;
    assign  LED[9]  = drive_busy;

endmodule

