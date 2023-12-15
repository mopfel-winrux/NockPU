
This document shows how the nockpu should handle the following nock code:

`*[[50 51] [2 [0 3] [1 [4 0 1]]]]` -> `*[*[[50 51] [0 3]] *[[50 51] [1 [4 0 1]]]]`

```
Addr | Data (hex)           | New Data (hex)     | Notes
0x00 | 00 0000000 0000009   | 00 0000000 000000A | Total Bytes only matters for compiler not for NPU
0x01 | 80 0000002 0000003   | 80 0000009 0000003 | Step 1: Get N free cells ned to rewrite main
0x02 | 03 0000032 0000033   | 03 0000032 0000033 | Not chaning subject, Save this address in register
0x03 | 02 0000002 0000004   | 80 0000002 0000006 | Step 3: second execute is [subject tel->tel->tel]
0x04 | 00 0000005 0000006   | X                  | Don't care GC will take care of this
0x05 | 03 0000000 0000003   | X                  | Don't care GC will take care of this
0x06 | 02 0000001 0000007   | 02 0000001 0000007 | Not changing just executing 
0x07 | 02 0000004 0000007   | 02 0000004 0000007 | Not changing just executing
0x08 | 03 0000000 0000001   | 03 0000000 0000001 | Not changing just executing
0x09 | X                    | 80 0000002 0000005 | Step 2: first execute is [subject tel->tel->hed]
0x0A | X                    | X
```

Possible optimizations:

I can save the tel->tel in a register and use its address to place the first execute. This brings the total number of wasted memory allocations down from 3 to 1. I should probbaly do this. 

That would look like this:

```
Addr | Data (hex)           | New Data (hex)     | Notes
0x00 | 00 0000000 0000009   | 00 0000000 000000A | Total Bytes only matters for compiler not for NPU
0x01 | 80 0000002 0000003   | 80 0000004 0000003 | Step 1: save tel->tel values. write addr to hed
0x02 | 03 0000032 0000033   | 03 0000032 0000033 | Not chaning subject, Save this address in register
0x03 | 02 0000002 0000004   | 80 0000002 0000006 | Step 3: second execute is [subject tel->tel->tel]
0x04 | 00 0000005 0000006   | 80 0000002 0000005 | Step 2: first execute is [subject tel->tel->hed]
0x05 | 03 0000000 0000003   | X                  | Don't care GC will take care of this
0x06 | 02 0000001 0000007   | 02 0000001 0000007 | Not changing just executing 
0x07 | 02 0000004 0000007   | 02 0000004 0000007 | Not changing just executing
0x08 | 03 0000000 0000001   | 03 0000000 0000001 | Not changing just executing
0x09 | X                    | X
0x0A | X                    | X
```

