onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /mem_traversal_tb/traversal/clk
add wave -noupdate /mem_traversal_tb/traversal/sys_func
add wave -noupdate /mem_traversal_tb/traversal/state
add wave -noupdate /mem_traversal_tb/traversal/mem_addr
add wave -noupdate /mem_traversal_tb/traversal/write_return_sys_func
add wave -noupdate /mem_traversal_tb/traversal/write_return_state
add wave -noupdate /mem_traversal_tb/traversal/mem_ready
add wave -noupdate /mem_traversal_tb/traversal/read_addr
add wave -noupdate /mem_traversal_tb/traversal/read_data
add wave -noupdate -expand /mem_traversal_tb/traversal/mem_tag
add wave -noupdate /mem_traversal_tb/traversal/hed
add wave -noupdate /mem_traversal_tb/traversal/tel
add wave -noupdate /mem_traversal_tb/traversal/trav_P
add wave -noupdate /mem_traversal_tb/traversal/trav_B
add wave -noupdate -divider {Can ignore}
add wave -noupdate {/mem_traversal_tb/mem/ram/ram[0]}
add wave -noupdate {/mem_traversal_tb/mem/ram/ram[1]}
add wave -noupdate {/mem_traversal_tb/mem/ram/ram[2]}
add wave -noupdate {/mem_traversal_tb/mem/ram/ram[3]}
add wave -noupdate {/mem_traversal_tb/mem/ram/ram[4]}
add wave -noupdate {/mem_traversal_tb/mem/ram/ram[5]}
add wave -noupdate /mem_traversal_tb/mem/ram/ram
add wave -noupdate /mem_traversal_tb/traversal/mem_func
add wave -noupdate /mem_traversal_tb/traversal/write_addr
add wave -noupdate /mem_traversal_tb/traversal/mem_execute
add wave -noupdate /mem_traversal_tb/traversal/write_data
add wave -noupdate /mem_traversal_tb/traversal/mem_data
add wave -noupdate /mem_traversal_tb/traversal/debug_sig
add wave -noupdate /mem_traversal_tb/traversal/start_addr
add wave -noupdate /mem_traversal_tb/traversal/execute
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {427 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 283
configure wave -valuecolwidth 221
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {416 ns} {820 ns}
