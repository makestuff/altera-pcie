create_clock -period "40.000 ns" -name {altera_reserved_tck} {altera_reserved_tck}
set_input_delay -clock altera_reserved_tck 5 [get_ports altera_reserved_tdi]
set_input_delay -clock altera_reserved_tck 5 [get_ports altera_reserved_tms]
set_output_delay -clock altera_reserved_tck -clock_fall -max 5 [get_ports altera_reserved_tdo]

create_clock -period "100 MHz" [get_ports pcieRefClk_in]
derive_pll_clocks
