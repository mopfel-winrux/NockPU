`*[a 5 b c]` ->`=[*[a b] *[a c]]`

```
Addr | Data (hex)           | New Data (hex)     | Notes
0x00 | 00 0000000 0000007   | 00 0000000 0000007 | 
0x01 | 80 0000002 0000003   | C2 0000005 0000007 | Should change to *#[opcode new_cell] 
0x02 | 03 0000032 0000033   | 03 0000032 0000033 | Subject doesnt change
0x03 | 02 0000005 0000004   | 80 0000002 0000005 | this becomes *[subject hed]
0x04 | 00 0000005 0000006   | 80 0000002 0000006 | This becomes *[subject tel]
0x05 | 03 0000000 0000002   | 03 0000000 0000002 | Don't Change keep just going to execute
0x06 | 03 0000000 0000003   | 03 0000000 0000002 | Don't Change keep just going to execute
0x07 | X                    | 00 0000003 0000004 | New Cell becomes [execute->tel execute->tel->tel]
0x08 | X                    | X
```
Step 1: save subject, ask for 1 new memory slot
Step 2: Write execute_start as `*#[opcode new_mem]`
Step 3: Read tel
Step 4: Read tel->tel
Step 5: Write tel as `*[subject tel->hed]`
Step 6: Write new_mem as `*[subject tel->tel]`



