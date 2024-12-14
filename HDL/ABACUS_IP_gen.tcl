# Set the reference directory for source file relative paths (by default the value is script directory path)
#set origin_dir [ file dirname [ file normalize [ info script ] ] ]
set origin_dir [file dirname [info script]]
puts $origin_dir

# Use origin directory path location variable, if specified in the tcl shell
if { [info exists ::origin_dir_loc] } {
  set origin_dir $::origin_dir_loc
}

# Set the project name
set _xil_proj_name_ "ABACUS_IP"

# Use project name variable, if specified in the tcl shell
if { [info exists ::user_project_name] } {
  set _xil_proj_name_ $::user_project_name
}

variable script_file
set script_file "ABACUS_IP_gen.tcl"

# Help information for this script
proc print_help {} {
  variable script_file
  puts "\nDescription:"
  puts "Recreate a Vivado project from this script. The created project will be"
  puts "functionally equivalent to the original project for which this script was"
  puts "generated. The script contains commands for creating a project, filesets,"
  puts "runs, adding/importing sources and setting properties on various objects.\n"
  puts "Syntax:"
  puts "$script_file"
  puts "$script_file -tclargs \[--origin_dir <path>\]"
  puts "$script_file -tclargs \[--project_name <name>\]"
  puts "$script_file -tclargs \[--help\]\n"
  puts "Usage:"
  puts "Name                   Description"
  puts "-------------------------------------------------------------------------"
  puts "\[--origin_dir <path>\]  Determine source file paths wrt this path. Default"
  puts "                       origin_dir path value is \".\", otherwise, the value"
  puts "                       that was set with the \"-paths_relative_to\" switch"
  puts "                       when this script was generated.\n"
  puts "\[--project_name <name>\] Create project with the specified name. Default"
  puts "                       name is the name of the project from where this"
  puts "                       script was generated.\n"
  puts "\[--help\]               Print help information for this script"
  puts "-------------------------------------------------------------------------\n"
  exit 0
}

if { $::argc > 0 } {
  for {set i 0} {$i < $::argc} {incr i} {
    set option [string trim [lindex $::argv $i]]
    switch -regexp -- $option {
      "--origin_dir"   { incr i; set origin_dir [lindex $::argv $i] }
      "--project_name" { incr i; set _xil_proj_name_ [lindex $::argv $i] }
      "--help"         { print_help }
      default {
        if { [regexp {^-} $option] } {
          puts "ERROR: Unknown option '$option' specified, please type '$script_file -tclargs --help' for usage info.\n"
          return 1
        }
      }
    }
  }
}

# Set the directory path for the original project from where this script was exported
#This is where the IP project gets stored ?
set orig_proj_dir "[file normalize "$origin_dir/"]"

# Create project
create_project ${_xil_proj_name_} $origin_dir/${_xil_proj_name_} -part xcvu9p-flga2104-2L-e -force

# Set the directory path for the new project
set proj_dir [get_property directory [current_project]]

# Reconstruct message rules
# None
# Set project properties
set obj [current_project]
set_property -name "board_part" -value "xilinx.com:vcu118:part0:2.3" -objects $obj
set_property -name "default_lib" -value "xil_defaultlib" -objects $obj
set_property -name "ip_cache_permissions" -value "read write" -objects $obj
set_property -name "ip_output_repo" -value "$proj_dir/${_xil_proj_name_}.cache/ip" -objects $obj
set_property -name "sim.ip.auto_export_scripts" -value "1" -objects $obj
set_property -name "simulator_language" -value "Mixed" -objects $obj
set_property -name "target_language" -value "Verilog" -objects $obj

# Create 'sources_1' fileset (if not found)
if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}

#import all sources from abacus repo directory

import_files -norecurse $origin_dir/abacus_top.sv -force
import_files -norecurse $origin_dir/profiling_units/instruction_profiler.sv -force
import_files -norecurse $origin_dir/profiling_units/cache_profiler.sv -force

# Set IP repository paths
set obj [get_filesets sources_1]
set_property "ip_repo_paths" "[file normalize "$origin_dir/ABACUS_IP"]" $obj

# Rebuild user ip_repo's index before adding any source files
update_ip_catalog -rebuild

# Set 'sources_1' fileset properties
set obj [get_filesets sources_1]
set_property -name "top" -value "abacus_top" -objects $obj
set_property -name "top_auto_set" -value "0" -objects $obj
set_property -name "top_file" -value " ${origin_dir}/abacus_top.sv" -objects $obj


puts "INFO: Project created:${_xil_proj_name_}"

############## Initial IP Packaging########################################
ipx::package_project -import_files -force -root_dir $proj_dir
update_compile_order -fileset sources_1
set_property core_revision 2 [ipx::current_core]
ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::save_core [ipx::current_core]


#####Re-Adding of project files
set_property  ip_repo_paths  $origin_dir/${_xil_proj_name_} [current_project]
current_project $_xil_proj_name_
update_ip_catalog
import_files -fileset [get_filesets sources_1] $origin_dir/abacus_top.sv
import_files -fileset [get_filesets sources_1] $origin_dir/profiling_units/cache_profiler.sv
import_files -fileset [get_filesets sources_1] $origin_dir/profiling_units/instruction_profiler.sv

ipx::add_subcore xilinx.com:ip:ila:6.2 [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]


############## Re-packaging of core
update_compile_order -fileset sources_1
ipx::merge_project_changes files [ipx::current_core]
set_property core_revision 3 [ipx::current_core]
ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::save_core [ipx::current_core]
current_project ABACUS_IP
set_property "ip_repo_paths" "[file normalize "$origin_dir/ABACUS_IP"]" $obj
update_ip_catalog -rebuild

exit
