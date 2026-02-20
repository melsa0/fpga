set project_name "btn_led"
set project_dir "C:/btn_led_build"
set script_dir [file dirname [file normalize [info script]]]

if {[file exists $project_dir]} { file delete -force $project_dir }
create_project $project_name $project_dir -part xc7a200tsbg484-1 -force

add_files -norecurse [glob $script_dir/*.v]
add_files -fileset constrs_1 -norecurse "$script_dir/nexys_video_btn_led.xdc"
set_property top btn_led_top [current_fileset]
update_compile_order -fileset sources_1

puts "========== SYNTHESIS =========="
launch_runs synth_1 -jobs 4
wait_on_run synth_1
if {[get_property STATUS [get_runs synth_1]] != "synth_design Complete!"} { puts "ERROR: Synthesis failed!"; exit 1 }
puts "SYNTHESIS COMPLETE!"

puts "========== IMPLEMENTATION =========="
launch_runs impl_1 -jobs 4
wait_on_run impl_1
if {[get_property STATUS [get_runs impl_1]] != "route_design Complete!"} { puts "ERROR: Implementation failed!"; exit 1 }
puts "IMPLEMENTATION COMPLETE!"

puts "========== BITSTREAM =========="
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
puts "BITSTREAM COMPLETE!"

puts "========== PROGRAMMING =========="
set bitstream_file "$project_dir/$project_name.runs/impl_1/btn_led_top.bit"
if {![file exists $bitstream_file]} { puts "ERROR: Bitstream not found!"; exit 1 }
open_hw_manager
connect_hw_server
open_hw_target
set hw_device [lindex [get_hw_devices] 0]
set_property PROGRAM.FILE $bitstream_file $hw_device
program_hw_devices $hw_device
puts "DEVICE PROGRAMMED SUCCESSFULLY!"
close_hw_target
disconnect_hw_server
close_hw_manager
close_project
puts "ALL DONE!"
