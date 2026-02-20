## Clock
set_property -dict { PACKAGE_PIN R4 IOSTANDARD LVCMOS33 } [get_ports clk]
create_clock -period 10.000 -name sys_clk [get_ports clk]

## Switches (LVCMOS12)
set_property -dict { PACKAGE_PIN E22 IOSTANDARD LVCMOS12 } [get_ports {SW[0]}]
set_property -dict { PACKAGE_PIN F21 IOSTANDARD LVCMOS12 } [get_ports {SW[1]}]
set_property -dict { PACKAGE_PIN G21 IOSTANDARD LVCMOS12 } [get_ports {SW[2]}]
set_property -dict { PACKAGE_PIN G22 IOSTANDARD LVCMOS12 } [get_ports {SW[3]}]
set_property -dict { PACKAGE_PIN H17 IOSTANDARD LVCMOS12 } [get_ports {SW[4]}]
set_property -dict { PACKAGE_PIN J16 IOSTANDARD LVCMOS12 } [get_ports {SW[5]}]
set_property -dict { PACKAGE_PIN K13 IOSTANDARD LVCMOS12 } [get_ports {SW[6]}]
set_property -dict { PACKAGE_PIN M17 IOSTANDARD LVCMOS12 } [get_ports {SW[7]}]

## LEDs (LVCMOS25)
set_property -dict { PACKAGE_PIN T14 IOSTANDARD LVCMOS25 } [get_ports {LED[0]}]
set_property -dict { PACKAGE_PIN T15 IOSTANDARD LVCMOS25 } [get_ports {LED[1]}]
set_property -dict { PACKAGE_PIN T16 IOSTANDARD LVCMOS25 } [get_ports {LED[2]}]
set_property -dict { PACKAGE_PIN U16 IOSTANDARD LVCMOS25 } [get_ports {LED[3]}]
set_property -dict { PACKAGE_PIN V15 IOSTANDARD LVCMOS25 } [get_ports {LED[4]}]
set_property -dict { PACKAGE_PIN W16 IOSTANDARD LVCMOS25 } [get_ports {LED[5]}]
set_property -dict { PACKAGE_PIN W15 IOSTANDARD LVCMOS25 } [get_ports {LED[6]}]
set_property -dict { PACKAGE_PIN Y13 IOSTANDARD LVCMOS25 } [get_ports {LED[7]}]

## OLED (LVCMOS33)
set_property -dict { PACKAGE_PIN W22 IOSTANDARD LVCMOS33 } [get_ports oled_dc]
set_property -dict { PACKAGE_PIN U21 IOSTANDARD LVCMOS33 } [get_ports oled_res]
set_property -dict { PACKAGE_PIN W21 IOSTANDARD LVCMOS33 } [get_ports oled_sclk]
set_property -dict { PACKAGE_PIN Y22 IOSTANDARD LVCMOS33 } [get_ports oled_sdin]
set_property -dict { PACKAGE_PIN P20 IOSTANDARD LVCMOS33 } [get_ports oled_vbat]
set_property -dict { PACKAGE_PIN V22 IOSTANDARD LVCMOS33 } [get_ports oled_vdd]
