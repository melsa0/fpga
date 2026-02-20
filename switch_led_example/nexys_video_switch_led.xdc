## Nexys Video - Switch to LED Constraints

## Switches (LVCMOS12)
set_property PACKAGE_PIN E22 [get_ports {SW[0]}]
set_property PACKAGE_PIN F21 [get_ports {SW[1]}]
set_property PACKAGE_PIN G21 [get_ports {SW[2]}]
set_property PACKAGE_PIN G22 [get_ports {SW[3]}]
set_property PACKAGE_PIN H17 [get_ports {SW[4]}]
set_property PACKAGE_PIN J16 [get_ports {SW[5]}]
set_property PACKAGE_PIN K13 [get_ports {SW[6]}]
set_property PACKAGE_PIN M17 [get_ports {SW[7]}]

set_property IOSTANDARD LVCMOS12 [get_ports {SW[*]}]

## LEDs (LVCMOS25)
set_property PACKAGE_PIN T14 [get_ports {LED[0]}]
set_property PACKAGE_PIN T15 [get_ports {LED[1]}]
set_property PACKAGE_PIN T16 [get_ports {LED[2]}]
set_property PACKAGE_PIN U16 [get_ports {LED[3]}]
set_property PACKAGE_PIN V15 [get_ports {LED[4]}]
set_property PACKAGE_PIN W16 [get_ports {LED[5]}]
set_property PACKAGE_PIN W15 [get_ports {LED[6]}]
set_property PACKAGE_PIN Y13 [get_ports {LED[7]}]

set_property IOSTANDARD LVCMOS25 [get_ports {LED[*]}]
