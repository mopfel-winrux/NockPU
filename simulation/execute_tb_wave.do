onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /execute_tb/execute/clk
add wave -noupdate /execute_tb/execute/rst
add wave -noupdate -divider MTU
add wave -noupdate /execute_tb/traversal/sys_func
add wave -noupdate /execute_tb/traversal/state
add wave -noupdate /execute_tb/traversal/is_finished_reg
add wave -noupdate -divider NEM
add wave -noupdate /execute_tb/execute/exec_func
add wave -noupdate /execute_tb/execute/state
add wave -noupdate /execute_tb/execute/execute_start
add wave -noupdate /execute_tb/execute/finished
add wave -noupdate /execute_tb/execute/error
add wave -noupdate /execute_tb/execute/execute_address
add wave -noupdate /execute_tb/execute/execute_tag
add wave -noupdate /execute_tb/execute/execute_data
add wave -noupdate /execute_tb/execute/a
add wave -noupdate /execute_tb/execute/opcode
add wave -noupdate /execute_tb/execute/b
add wave -noupdate /execute_tb/execute/c
add wave -noupdate /execute_tb/execute/d
add wave -noupdate /execute_tb/execute/execute_return_sys_func
add wave -noupdate /execute_tb/execute/execute_return_state
add wave -noupdate /execute_tb/execute/read_data_reg
add wave -noupdate -divider Memory
add wave -noupdate {/execute_tb/mem/ram/ram[3]}
add wave -noupdate {/execute_tb/mem/ram/ram[2]}
add wave -noupdate {/execute_tb/mem/ram/ram[1]}
add wave -noupdate {/execute_tb/mem/ram/ram[0]}
add wave -noupdate -divider Misc
add wave -noupdate /execute_tb/execute/mem_ready
add wave -noupdate /execute_tb/execute/read_data
add wave -noupdate /execute_tb/execute/free_addr
add wave -noupdate /execute_tb/execute/mem_execute
add wave -noupdate /execute_tb/execute/address
add wave -noupdate /execute_tb/execute/mem_func
add wave -noupdate /execute_tb/execute/write_data
add wave -noupdate /execute_tb/execute/mem_tag
add wave -noupdate /execute_tb/execute/hed
add wave -noupdate /execute_tb/execute/tel
add wave -noupdate /execute_tb/execute/mem_addr
add wave -noupdate /execute_tb/execute/mem_data
add wave -noupdate /execute_tb/mem/ram/ram
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {210 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 329
configure wave -valuecolwidth 100
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
WaveRestoreZoom {145 ns} {1035 ns}
