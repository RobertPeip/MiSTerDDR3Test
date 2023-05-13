derive_pll_clocks
derive_clock_uncertainty

set_false_path -from [get_clocks {emu|pll|pll_inst|altera_pll_i|cyclonev_pll|counter[0].output_counter|divclk}] -to [get_clocks {emu|pll2|pll2_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}]
set_false_path -from [get_clocks {emu|pll2|pll2_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -to [get_clocks {emu|pll|pll_inst|altera_pll_i|cyclonev_pll|counter[0].output_counter|divclk}]