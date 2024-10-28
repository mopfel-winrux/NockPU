/*
 Will have 3 main functions used by external modules.
  - Given an address of a cell, return its value
  - Given an address of a cell, the cell's value, and a type tag, write to memory
  - Request the a batch of emprt cells that have a length of write_data.
    These are garrenteed to be open and this will cause a GC to run if not.
 Memory is word addressable. When all the correct values are set,
 pull execute to high and wait for is_ready to go high. This will mark that your command is finished
*/

`include "memory_unit.vh"

module memory_unit(
  input power,
  input clk,
  input rst,
  input [1:0] func, 
  input execute,
  input [`memory_addr_width - 1:0] address1,
  input [`memory_addr_width - 1:0] address2,
  input [`memory_data_width - 1:0] write_data,
  input gc_ready,
  output reg [`memory_addr_width - 1:0] free_addr,
  output reg [`memory_data_width - 1:0] read_data1,
  output reg [`memory_data_width - 1:0] read_data2,
  output reg gc,
  output wire is_ready,
  output wire [`memory_data_width - 1:0] mem_data_out1,
  output wire [`memory_data_width - 1:0] mem_data_out2
);
  reg [7:0] debug_sig;
  // Signal wires for this module
  reg is_ready_reg;
  assign is_ready = !execute && is_ready_reg;

  // Interface with the ram module
  reg [`memory_addr_width - 1:0] mem_addr1;
  reg [`memory_addr_width - 1:0] mem_addr2;
  reg mem_write;
  reg [`memory_data_width - 1:0] mem_data_in;

  //Garbage Collection Registers
  reg [`memory_addr_width - 1:0] old_root;
  reg [`memory_addr_width - 1:0] new_root;
  reg [`memory_addr_width - 1:0] gc_x;
  reg [`memory_addr_width - 1:0] gc_h;
  reg [`memory_addr_width - 1:0] gc_k;
  reg [`memory_addr_width - 1:0] gc_t;
  reg [`memory_addr_width - 1:0] gc_n;
  reg [`memory_data_width - 1:0] gc_a;
  reg [`memory_data_width - 1:0] gc_d;
  reg [`memory_data_width - 1:0] gc_tmp;
  
  localparam [`memory_addr_width:0] memory_mask = (1<<`memory_addr_width-1)+1; 

  reg [`memory_addr_width - 1:0] max_memory;
  reg [`memory_addr_width - 1:0] need_mem;


  // Internal regs and wires
  reg [`memory_addr_width - 1:0] free_mem;

  reg [3:0] state;
  reg [3:0] next_state;
  reg [3:0] gc_state;
  reg [3:0] gc_next_state;
  // States
  parameter STATE_INIT_SETUP          = 4'h0,
            STATE_INIT_WAIT_0         = 4'h1,
            STATE_INIT_STORE_FREE_MEM = 4'h2,
            STATE_INIT_CLEAR_NIL      = 4'h3,
            STATE_INIT_WAIT_1         = 4'h4,
            STATE_WAIT                = 4'h5,
            STATE_READ_WAIT_0         = 4'h6,
            STATE_READ_FINISH         = 4'h7,
            STATE_WRITE_WAIT_0        = 4'h8,
            STATE_WRITE_FINISH        = 4'h9,
            STATE_FREE_WAIT           = 4'hA,
            STATE_GC                  = 4'hB,
            STATE_DUMP                = 4'hC,
            STATE_DUMP2               = 4'hD;

  parameter GC_INIT                   = 4'h0,
            GC_START                  = 4'h1,
            GC_A1                     = 4'h2,
            GC_A2                     = 4'h3,
            GC_A3                     = 4'h4,
            GC_A4                     = 4'h5,
            GC_A5                     = 4'h6,
            GC_A6                     = 4'h7,
            GC_B0                     = 4'h8,
            GC_B1                     = 4'h9,
            GC_B2                     = 4'hA,
            GC_B3_READ                = 4'hB,
            GC_B3                     = 4'hC,
            GC_WTF                    = 4'hD,
            GC_DONE                   = 4'hE,
            GC_WAIT                   = 4'hF;

  ram ram(.address1 (mem_addr1),
          .address2 (mem_addr2),
          .clock (clk),
          .data (mem_data_in),
          .wren (mem_write),
          .q1 (mem_data_out1),
          .q2 (mem_data_out2));

  always@(posedge clk or negedge rst) begin
  if(!rst) begin
    state <= STATE_INIT_SETUP;
    free_mem <= 0;
    gc <= 0;

    mem_addr1 <= 0;
    mem_addr2 <= 0;
    mem_data_in <= 0;

    is_ready_reg <= 0;
    max_memory <= 1022;//1020;
    old_root <= 1;
    new_root <= memory_mask;
    need_mem <= (free_addr - old_root);
  end
  else if (gc_ready && gc && (state != STATE_DUMP2 && state != STATE_DUMP && state != STATE_GC) ) begin
    state <= STATE_GC;
    next_state <= STATE_GC;
    gc_state <= GC_START;
    gc_n <= free_mem;
    gc_k <= old_root;
    mem_addr1 <= old_root;
  end
  else if (power) begin
    case (state)
    // Initialize the free memory register
    STATE_INIT_SETUP: begin
      state <= STATE_INIT_WAIT_0;
      mem_addr1 <= 0;
      mem_addr2 <= 0;
    end
    STATE_INIT_WAIT_0: begin
      state <= STATE_INIT_STORE_FREE_MEM;
    end
    // Record the start of the free memory store
    STATE_INIT_STORE_FREE_MEM: begin
      state <= STATE_INIT_CLEAR_NIL;
      free_mem <= mem_data_out1[9:0];
    end
    // Clear the nil pointer
    STATE_INIT_CLEAR_NIL: begin
      state <= STATE_INIT_WAIT_1;
      mem_addr1 <= 0;
      mem_addr2 <= 0;
      mem_data_in <= 0;
    end
    STATE_INIT_WAIT_1: begin
      state <= STATE_WAIT;
      free_addr <= free_mem;

      mem_write <= 0;
    end

    // Wait for a command dispatch
    STATE_WAIT: begin
      if(execute) begin
        is_ready_reg <= 0;
        // Dispatch according to the function
        case (func)
        `GET_CONTENTS: begin
          mem_addr1 <= address1;
          mem_addr2 <= address2;
          state <= STATE_READ_WAIT_0;
        end

        `SET_CONTENTS: begin
          mem_addr1 <= address1;
          mem_data_in <= write_data;
          mem_write<=1;
          state <= STATE_WRITE_WAIT_0;
        end

        `GET_FREE: begin
          need_mem <= (free_mem - old_root) + write_data;
          if((free_mem-old_root) + write_data <= max_memory) begin // if you have enough free memory
            free_addr <= free_mem;
            free_mem <= free_mem + write_data;
            state <= STATE_FREE_WAIT;
          end
          else begin
            state <= STATE_GC;
            gc_state <= GC_INIT;
          end
        end
        endcase
      end else begin
        state <= STATE_WAIT;
        is_ready_reg <= 1;
      end
    end

    // Various wait states used when reading from memory
    STATE_READ_WAIT_0: begin
      state <= STATE_READ_FINISH;
    end

    STATE_READ_FINISH: begin
      state <= STATE_WAIT;
      is_ready_reg <= 1;
      read_data1 <= mem_data_out1;
      read_data2 <= mem_data_out2;
    end
    
    // Various wait states used when writing to memory
    STATE_WRITE_WAIT_0: begin
      state <= STATE_WRITE_FINISH;
      mem_write<=0;
    end

    STATE_WRITE_FINISH: begin
      state <= STATE_WAIT;
      is_ready_reg <= 1;
    end

    // Return a new cell
    STATE_FREE_WAIT: begin
      is_ready_reg <= 1;
      state <= STATE_WAIT;
    end

    STATE_DUMP: begin
      if (gc_k < gc_n) begin
        mem_addr1 <= gc_k;
        gc_k <= gc_k +1;
        $display("0x%0h 0x%8h", gc_k-1, mem_data_out1);
        state <= STATE_DUMP2;
      end else begin 
        read_data1 <= gc_h; // replace with new root
        state <= next_state;
        $display("0x%0h 0x%8h", gc_k-1, mem_data_out1);
        $display("fin");
        $stop;
      end
    end
    
    STATE_DUMP2: begin
      state <= STATE_DUMP;
    end

    STATE_GC: begin
      case (gc_state)
        GC_INIT: begin
          gc <= 1;
          state <= STATE_WAIT;
        end

        GC_START: begin
          gc_x <= old_root;
          gc_h <= new_root;
          gc_n <= new_root;
          gc_k <= `NIL_ADDR;
          gc_state <= GC_A1;
        end
        // Garbage Collect
        GC_A1: begin
          //  [Initialize.] x+--h, h*-n, and k*--NIL.
          mem_addr1 <= gc_x;
          gc_state <= GC_WAIT;
          gc_next_state <= GC_A2;
        end

        GC_A2: begin
          gc_a <= mem_data_out1;
          gc_d <= mem_data_out1;
          gc_state <= GC_A3;
        end

        GC_A3: begin
          mem_addr1 <= gc_x;
          mem_data_in <= {
                  gc_a[`tag_start:`tel_trav],
                  `CELL,
                  gc_a[`tel_tag],
                  `ADDR_PAD,
                  gc_n,
                  gc_a[`tel_start:`tel_end]};
          mem_write<=1;
          gc_next_state <= GC_A4;
          gc_state <= GC_WAIT;
        end

        GC_A4: begin
          if(gc_a[`hed_tag] == `CELL) begin
            mem_addr1 <= gc_x;
            mem_data_in <= {
              mem_data_in[`tag_start:`tag_end],
              mem_data_in[`hed_start:`hed_end],
              `ADDR_PAD,
              gc_k};
            mem_write<=1;
            gc_k <= gc_x;
            gc_state <= GC_WAIT;
            gc_next_state <= GC_A5;
          end 
          else begin
            gc_state <= GC_A5;
          end
        end
        
        GC_A5: begin
          mem_addr1 <= gc_n;
          mem_data_in <= {
            gc_a[`tag_start:`hed_tag],
            `ATOM,
            gc_a[`hed_start:`hed_end],
            `NIL};
          mem_write<=1;
          gc_state <= GC_WAIT;
          gc_next_state <= GC_A6;
          // prepare for A6
          //if(gc_d[`tel_tag] == `CELL)
            mem_addr2 <= gc_d[`tel_start:`tel_end];
        end
        
        GC_A6: begin
          if(gc_d[`tel_tag]==`ATOM) begin
            debug_sig <= 3;
            mem_addr1 <= gc_n;
            mem_data_in <= {
              mem_data_in[`tag_start:`hed_tag],
              gc_d[`tel_tag],
              mem_data_in[`hed_start:`hed_end],
              gc_d[`tel_start:`tel_end]};
            mem_write<=1;
            gc_state <= GC_WAIT;
            gc_next_state <= GC_B0;
            gc_n <= gc_n + 1;
          end 
          else if (mem_data_out2[`hed_tag] ==`CELL &&
                  (((new_root == memory_mask) && 
                   (mem_data_out2[`hed_start:`hed_end] >= memory_mask)) ||
                   (old_root == memory_mask) &&
                   (mem_data_out2[`hed_start:`hed_end] < memory_mask)))
          begin
            debug_sig <= 4;
            mem_addr1 <= gc_n;
            mem_data_in <= {
              mem_data_in[`tag_start:`hed_tag],
              mem_data_out2[`hed_tag],
              mem_data_in[`hed_start:`hed_end],
              mem_data_out2[`hed_start:`hed_end]};
            mem_write <= 1;
            gc_state <= GC_WAIT;
            gc_next_state <= GC_B0;
            gc_n <= gc_n + 1;
          end else begin
            debug_sig <= 5;
            mem_addr1 <= gc_n;
            mem_data_in <= {
              mem_data_in[`tag_start:`hed_tag],
              `CELL,
              mem_data_in[`hed_start:`hed_end],
              `ADDR_PAD,
              gc_n+2'h1};
            mem_write<=1;
            gc_n <= gc_n + 1;
            gc_x <= gc_d[`tel_start:`tel_end];
            
            gc_state <= GC_WAIT;
            gc_next_state <= GC_A1;
          end
        end
            
        GC_B0: begin
          if (gc_k == `NIL_ADDR) begin
            gc_state <= GC_DONE;
          end
          else begin
            mem_addr1 <= gc_k;
            gc_state <= GC_B1;
          end
        end
        
        GC_B1: begin
          mem_addr2 <= mem_data_out1[`hed_start:`hed_end];
          gc_state <= GC_WAIT;
          gc_next_state <= GC_B2;
        end
        
        GC_B2: begin
          mem_addr1 <= mem_data_out1[`hed_start:`hed_end];
          gc_t <= gc_k;
          gc_k <= mem_data_out1[`tel_start:`tel_end];
          gc_state <= GC_WAIT;
          gc_next_state <= GC_B3_READ;
        end
        
        GC_B3_READ: begin
          gc_tmp <= mem_data_out1;
          gc_x <= mem_data_out1[`hed_start:`hed_end];
          mem_addr1 <= mem_data_out1[`hed_start:`hed_end];
          mem_addr2 <= gc_t;//mem_data_out2[`hed_start:`hed_end];
          gc_state <= GC_WAIT;
          gc_next_state <= GC_B3;
        end

        GC_B3: begin
          if ((gc_tmp[`hed_tag] ==`CELL) &&
              ((new_root == memory_mask) && 
              (gc_tmp[`hed_start:`hed_end] >= memory_mask)) ||
             ((old_root == memory_mask) &&
              (gc_tmp[`hed_start:`hed_end] < memory_mask)))
          begin
            debug_sig <= 64;
            mem_addr1 <= mem_data_out2[`hed_start:`hed_end];
            mem_data_in <= mem_data_out1;

            mem_write<=1;
            gc_state <= GC_WAIT;
            gc_next_state <= GC_B0;
          end 
          else begin
            debug_sig <= 128;
            mem_addr1 <= mem_data_out2[`hed_start:`hed_end];
            mem_data_in <= {
              gc_tmp[`tag_start:`tel_trav],
              `CELL,
              gc_tmp[`tel_tag],
              `ADDR_PAD,
              gc_n,
              gc_tmp[`tel_start:`tel_end]};
            mem_write<=1;
            gc_state <= GC_WAIT;
            gc_next_state <= GC_A1;
          end
        end
        
        GC_DONE: begin
          debug_sig <= 1;
          read_data1 <= gc_h; // replace with new root
          free_mem <= gc_n;
          old_root <= new_root;
          new_root <= old_root;
          //gc_state <= GC_WTF;
          //gc_n <= free_mem;
          gc_k <= new_root;
          gc <= 0;
          gc_state <= GC_INIT;
          state <= STATE_WAIT;
        end

        GC_WTF: begin
          if (gc_k < gc_n) begin
            //mem_data_in <= 'x;
            mem_addr1 <= gc_k;
            gc_k <= gc_k +1;
            //mem_write <= 1;
            gc_state <= GC_WAIT;
            gc_next_state <= GC_WTF;
            $display("0x%0h 0x%8h", gc_k-1, mem_data_out1);
          end else begin 
            read_data1 <= gc_h; // replace with new root
            gc <= 0;
            //gc_state <= GC_INIT;
            state <= STATE_WAIT;
            $display("0x%0h 0x%8h", gc_k-1, mem_data_out1);
          end
        end
        
        GC_WAIT: begin
          mem_write<=0;
          gc_state <= gc_next_state;
            //debug_sig <= 0;
        end

        endcase
     end
    
    default:;

    endcase
  end
end

endmodule
