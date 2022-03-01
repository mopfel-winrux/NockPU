`ifndef traversal_include
`define traversal_include

// Opcode Definitions
`define slot                0
`define constant            1
`define evaluate            2
`define cell                3
`define increment           4
`define equality            5
`define if_then_else        6
`define compose             7
`define extend              8
`define invoke              9
`define replace             10
`define hint                11

// Error Definitions
`define ERROR_TEL_NOT_CELL            8'h01
`define ERROR_INVALID_OPCODE          8'h02

`endif
