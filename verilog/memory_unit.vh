`ifndef memory_include
`define memory_include

`define memory_data_width 69
`define memory_addr_width 10
`define tag_start         68
`define tag_end           64
`define hed_start         63
`define hed_end           32
`define tel_start         31
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
`define NIL          32'hFFFFFFFF

`endif