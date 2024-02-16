
This document shows how the nockpu should handle the following nock code:

`*[[50 51] [[1 2] 1 3]]` -> `[*[[50 51] [1 2]] *[[50 51] [1 3]]]` -> `[2 3]`

```
Addr | Data (hex)           | New Data (hex)     | Notes
0x00 | 00 0000000 0000006   | 00 0000000 0000006 | Total Bytes only matters for the memory unit
0x01 | 80 0000002 0000003   | 00 0000003 0000006 | Subject is save and two cells are pointed to.
0x02 | 03 0000032 0000033   | 03 0000032 0000033 | Not changing the subject
0x03 | 00 0000004 0000005   | 80 0000002 0000004 | Becomes the [subject tel->hed]
0x04 | 03 0000001 0000002   | 03 0000001 0000002 | Not changing just executing
0x05 | 03 0000001 0000003   | 03 0000001 0000003 | Not changing just executing 
0x06 | X                    | 80 0000002 0000005 | New cell is created [subject tel->tel]
0x07 | X                    | X
```

Start with
[subject tel]

Step 1: save subject, ask for 1 new memory slot
Step 2: Write execute_start as `[tel new_mem]`
Step 3: Read tel
Step 4: Write tel as `*[subject tel->hed]`
Step 5: Write new_mem as `*[subject tel->tel]`


0000000000000006
8000000020000003
0300000320000033
0000000040000005
0300000010000002
0300000010000003
