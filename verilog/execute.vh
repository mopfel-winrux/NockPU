`ifndef execute_include
`define execute_include

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

// MTU Return Functions
`define SYS_FUNC_EXECUTE    4'h3
`define SYS_EXECUTE_ERROR   4'hF

`define SYS_FUNC_READ       4'h0
`define SYS_READ_INIT       4'h0

// Error Definitions
`define ERROR_TEL_NOT_CELL            8'h01
`define ERROR_INVALID_OPCODE          8'h02


`endif