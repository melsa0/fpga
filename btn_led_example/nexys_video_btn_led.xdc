## Clock
set_property -dict { PACKAGE_PIN R4 IOSTANDARD LVCMOS33 } [get_ports clk]
create_clock -period 10.000 -name sys_clk [get_ports clk]

## Buttons (LVCMOS12)
set_property -dict { PACKAGE_PIN B22 IOSTANDARD LVCMOS12 } [get_ports btnc]
set_property -dict { PACKAGE_PIN D22 IOSTANDARD LVCMOS12 } [get_ports btnd]
set_property -dict { PACKAGE_PIN C22 IOSTANDARD LVCMOS12 } [get_ports btnl]
set_property -dict { PACKAGE_PIN D14 IOSTANDARD LVCMOS12 } [get_ports btnr]
set_property -dict { PACKAGE_PIN F15 IOSTANDARD LVCMOS12 } [get_ports btnu]

## LEDs (LVCMOS25)
set_property -dict { PACKAGE_PIN T14 IOSTANDARD LVCMOS25 } [get_ports {LED[0]}]
set_property -dict { PACKAGE_PIN T15 IOSTANDARD LVCMOS25 } [get_ports {LED[1]}]
set_property -dict { PACKAGE_PIN T16 IOSTANDARD LVCMOS25 } [get_ports {LED[2]}]
set_property -dict { PACKAGE_PIN U16 IOSTANDARD LVCMOS25 } [get_ports {LED[3]}]
set_property -dict { PACKAGE_PIN V15 IOSTANDARD LVCMOS25 } [get_ports {LED[4]}]
set_property -dict { PACKAGE_PIN W16 IOSTANDARD LVCMOS25 } [get_ports {LED[5]}]
set_property -dict { PACKAGE_PIN W15 IOSTANDARD LVCMOS25 } [get_ports {LED[6]}]
set_property -dict { PACKAGE_PIN Y13 IOSTANDARD LVCMOS25 } [get_ports {LED[7]}]
