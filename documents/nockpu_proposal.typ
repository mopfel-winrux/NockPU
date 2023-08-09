#set text(
  font: "New Computer Modern",
  size: 8pt
)
#set page(
  paper: "a6",
  margin: (x: 1.8cm, y: 1.5cm),
)
#set par(
  justify: true,
  leading: 0.52em,
)

= Proposal for the Development and Testing of a Hardware-Based Nock Processing Unit (NockPU)

#par(justify: true)[
	=== Executive Summary
	Native Planet, a Urbit-centered hardware and software enterprise, seeks to undertake a novel and ambitious project aimed at instantiating the Nock Instruction Set Architecture (ISA) in hardware. We propose the development of a specialized Nock Processing Unit (NockPU), marking a significant shift from the current software-based Nock interpreters. This research project is driven by a strong theoretical framework coupled with practical industry experience and is anticipated to yield transformative results in computational performance and efficiency.
]

== Project Objectives and Description

The primary goal is to engineer a Verilog-based NockPU capable of performing complex tasks such as traversing and manipulating a binary tree represented in memory using specific Nock commands. By achieving this, we aim to demonstrate the unit's capability to efficiently carry out all Nock operations. This will contribute to the advancement of zero-knowledge proofs and difficult-to-jet Nock code.

=== Methodology and Timelines

The project will be completed over twelve months and can be divided into five main milestones:
- **Completion of All Nock Opcodes (Month 1-6):** 

-- This is the first significant milestone. We'll design and test all nock opcodes, focusing on ensuring their flawless functionality when instantiated in hardware.

- **Implementation of Garbage Collection (Month 7-8):** 

-- Post opcode completion, the focus will shift to designing and implementing an efficient garbage collection system. This will help in maintaining optimum memory utilization, essential for the hardware's high-performance functioning.

- **Memory Optimization (Month 9-10):** 

-- We will work on algorithms to ensure optimal memory usage and fast access times. A variety of techniques will be employed and tested for effectiveness, with the best one(s) chosen for the final design.

- **Support for Arbitrarily Large Atoms (Month 10-11):** 

-- At this stage, we will integrate the support for arbitrarily large atoms into the NockPU, enhancing the unit's flexibility and broadening its scope of application.

- **Synthesizing the Design onto an FPGA (Month 12):** 

-- The final stage will involve synthesizing the whole design onto an FPGA. This will be a crucial stage, marking the transition from design to physical hardware, and will include rigorous testing and fine-tuning.

Throughout the project, we will use 'iverilog' and 'gtkwave' for simulation, and the choice of chip for synthesis will be decided based on the design requirements and performance in the preliminary stages.

=== Budget and Resource Allocation
We are seeking `$`100,000 in funding to cover the project's expenses. The budget distribution is as follows:
- Project lead salary (Research & Development): `$`85,000
- Software and Hardware (iverilog, gtkwave, FPGA): `$`5,000
- Administrative and overhead costs: `$`0
- Contingency (for unexpected costs): `$`10,000

=== Anticipated Outcomes and Measures of Success

The project is anticipated to yield groundbreaking outcomes in hardware-based processing, including the execution of Nock Formulas of varying complexity. 

Our specific measures of success are as follows:

- **Addition Operations (By End of Month 6):** 

-- As a core arithmetic operation, the execution of addition operations will be a significant achievement, illustrating the NockPU's ability to handle essential mathematical functions.

- **Decrement Operations (By End of Month 6):** 

-- An early indicator of success will be the NockPU's ability to execute decrement operations efficiently. This milestone will demonstrate the unit's initial operational capabilities.

- **Subtraction Operations (By End of Month 6):** 

-- The successful execution of subtraction operations will further showcase the NockPU's computational prowess and its progress in implementing more complex functions.

- **Complex Nock Formulas (By End of Month 10):** 

-- The NockPU should be capable of executing complex Nock formulas, demonstrating the versatility and power of the hardware-based approach.

- **Synthesis into a Chip (By End of Month 12):** 

-- The NockPU should be synthesized on an FPGA where it can be sent some Nock and a start command and return the computed Nock.

The speed of these executions is another key performance indicator. The aim is to make these operations as efficient as possible, to bring about significant improvements in performance over software-based interpreters.

An additional measure of success will be the production of detailed design documentation, outlining the methodologies employed, challenges encountered, solutions devised, and key learning outcomes. Finally, the project will be deemed successful upon the presentation of a working prototype that effectively demonstrates the capabilities of the NockPU.

=== Unique Value Proposition

The project stands out due to its hardware instantiation approach, providing enhanced control over interpreter operations and facilitating unique design decisions, like a stackless tree traversal. This approach is a departure from traditional software-based Nock interpreters (vere and ares), making the NockPU a trailblazing venture in the field.

=== Strategic Partnerships

We maintain strong relationships with entities such as the Urbit Foundation, Zorp, and other Urbit companies, which will prove advantageous for knowledge exchange, collaboration, and potential applications of the NockPU technology.

=== Open-Source Commitment

In the spirit of fostering innovation and community collaboration, Native Planet is committed to making the outcomes of this project openly accessible. All the work related to the NockPU, including design documentation, code, and testing results, will be released under an open-source license.

This approach will not only promote transparency but also enable other researchers and developers to build upon our work, fostering further innovation. By contributing to the open-source community, we aim to catalyze broader developments in hardware-based processing units and their applications.

=== Deliverables

There are two deliverables associated with this product:
- The open source design, including the verilog and design documentation. 
- A demo unit (at the end of this work) be delivered to Tacen.

=== Conclusion

Native Planet presents this proposal for your consideration, underlining our commitment to fostering technological innovation and progress. We believe the NockPU project will significantly advance our understanding of the Nock ISA's hardware capabilities. Your support will be pivotal in realizing this groundbreaking initiative, which holds potential to unlock exciting new capabilities for efficient Nock computation.
