`ifndef memory_include
`define memory_include

`define memory_data_width 64
`define memory_addr_width 11
`define noun_width        28
`define noun_tag_width    1
`define execute_bit       63
`define stack_bit         62
`define large_atom_bit    60
`define hed_trav          59
`define tel_trav          58
`define hed_tag           57
`define tel_tag           56
`define tag_width         8
`define tag_start         63
`define tag_end           56
`define hed_start         55
`define hed_end           28
`define tel_start         27
`define tel_end           0


// Memory unit functions
`define  GET_CONTENTS    2'b00
`define  SET_CONTENTS    2'b01
`define  GET_FREE        2'b10

// Memory tag defines
`define  ATOM_ATOM       2'b11
`define  ATOM_CELL       2'b10
`define  CELL_ATOM       2'b01
`define  CELL_CELL       2'b00
`define  CELL            1'b0
`define  ATOM            1'b1
`define  YES             1'b0
`define  NO              1'b1

//Memory constants
`define NIL          28'hFFFFFFF
`define ADDR_PAD     17'h0

`endif
