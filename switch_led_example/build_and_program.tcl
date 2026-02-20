# ==============================================================================
# Switch-to-LED Build & Program Script - Nexys Video
# ==============================================================================

set project_name "switch_led"
set project_dir "C:/switch_led_build"
set script_dir [file dirname [file normalize [info script]]]

# Clean previous build
if {[file exists $project_dir]} {
    file delete -force $project_dir
}

# Create project
create_project $project_name $project_dir -part xc7a200tsbg484-1 -force
# Board part not installed - using part number only (xc7a200tsbg484-1) which is sufficient

# Add sources
add_files -norecurse "$script_dir/switch_to_led.v"
add_files -fileset constrs_1 -norecurse "$script_dir/nexys_video_switch_led.xdc"

# Set top module
set_property top switch_to_led [current_fileset]
update_compile_order -fileset sources_1

# ==============================================================================
# Synthesis
# ==============================================================================
puts "============================================"
puts "  SYNTHESIS STARTING..."
puts "============================================"

launch_runs synth_1 -jobs 4
wait_on_run synth_1

if {[get_property STATUS [get_runs synth_1]] != "synth_design Complete!"} {
    puts "ERROR: Synthesis failed!"
    exit 1
}
puts "SYNTHESIS COMPLETE!"

# ==============================================================================
# Implementation
# ==============================================================================
puts "============================================"
puts "  IMPLEMENTATION STARTING..."
puts "============================================"

launch_runs impl_1 -jobs 4
wait_on_run impl_1

if {[get_property STATUS [get_runs impl_1]] != "route_design Complete!"} {
    puts "ERROR: Implementation failed!"
    exit 1
}
puts "IMPLEMENTATION COMPLETE!"

# ==============================================================================
# Bitstream Generation
# ==============================================================================
puts "============================================"
puts "  BITSTREAM GENERATION STARTING..."
puts "============================================"

launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

puts "BITSTREAM GENERATION COMPLETE!"

# ==============================================================================
# Program Device
# ==============================================================================
puts "============================================"
puts "  PROGRAMMING DEVICE..."
puts "============================================"

set bitstream_file "$project_dir/$project_name.runs/impl_1/switch_to_led.bit"

if {![file exists $bitstream_file]} {
    puts "ERROR: Bitstream file not found at $bitstream_file"
    exit 1
}

open_hw_manager
connect_hw_server
open_hw_target

set hw_device [lindex [get_hw_devices] 0]
set_property PROGRAM.FILE $bitstream_file $hw_device
program_hw_devices $hw_device

puts "============================================"
puts "  DEVICE PROGRAMMED SUCCESSFULLY!"
puts "  Switch'leri acip LED'leri kontrol edin."
puts "============================================"

close_hw_target
disconnect_hw_server
close_hw_manager

close_project
puts "BUILD & PROGRAM COMPLETE!"
