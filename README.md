# NockPU

This repository contains Verilog code used to produce hardware that can execute Nock code directly. 

Design and Reference documentation along with a general chat can be found by joining the urbit group:

`~mopfel-winrux/NockPU`

## How to run

This project can be simulated with `iverilog` and the waveform can be viewed with `gtkwave`. Please make sure those are installed on your system.

To compile the project run

`iverilog -o npu.vvp -c command_file`

This will create a file called `npu.vvp`. This can be simulated with `vvp` using the following command

`vvp npu.vvp`

When the simulation stops you can type `finish` to stop the simulation. This will create a file called `waveform.vcd` which will contain the waveform of the model.

This can be viewed using `gtkwave`:

`gtkwave waveform.vcd`




# Project Layout

In the `verilog` folder there is the verilog code that can be synthesized into hardware. 

The `simulation` folder contains the ModelSim project files that are used to run simulations of the hardware.

The `synthesis` folder contains the Quartus project file that is used to synthesize the verilog code into hardware.

The `memory` folder contains memory files that can be loaded onto the synthesized SRAM.

The `testbenches` folder contains wrapper classes for different verilog modules to perform unit tests. 

It contains Quartus and ModelSim project files . The synthesis and simulation folders respectively
