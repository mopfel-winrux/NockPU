`ifndef memory_include
`define memory_include

`define memory_data_width 64
`define memory_addr_width 10
`define noun_width        28
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

//Memory constants
`define NIL          28'hFFFFFFF

`endif
