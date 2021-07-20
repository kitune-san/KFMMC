create_clock -name CLK -period 20.000 [get_ports {CLK}]
create_clock -name CLK_5MHZ -period 200.000
create_clock -name CLK_25MHZ -period 40.000
derive_pll_clocks
derive_clock_uncertainty
set_input_delay -clock {CLK_5MHZ} -max 10 [get_ports {MMC_*}]
set_input_delay -clock {CLK_5MHZ} -min 5 [get_ports {MMC_*}]

set_output_delay -clock {CLK_5MHZ} -max 10 [get_ports {LED*}]
set_output_delay -clock {CLK_5MHZ} -min 5 [get_ports {LED*}]
set_output_delay -clock {CLK_5MHZ} -max 10 [get_ports {MMC_*}]
set_output_delay -clock {CLK_5MHZ} -min 5 [get_ports {MMC_*}]
set_output_delay -clock {CLK_25MHZ} -max 2 [get_ports {VGA_*}]
set_output_delay -clock {CLK_25MHZ} -min 1 [get_ports {VGA_*}]

