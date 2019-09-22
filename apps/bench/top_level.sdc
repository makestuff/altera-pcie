create_clock -period "100 MHz" [get_ports pcieRefClk_in]
derive_pll_clocks
