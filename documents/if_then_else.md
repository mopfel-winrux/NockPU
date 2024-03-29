`*[a 6 b c d]` -> `*[a *[[c d] 0 *[[2 3] 0 *[a 4 4 b]]]]`

`.*(1 [6 [0 1] [0 1] [4 0 1]])`

```
a = 1       = addr 0x01 = execute_data[hed]
b = [0 1]   = addr 0x04 = execute_data[tel]->tel[hed]
c = [0 1]   = addr 0x06 = execute_data[tel]->tel->tel[hed]
d = [4 0 1] = addr 0x07 = execute_data[tel]->tel->tel[tel]
```

```
Addr | Data (hex)           | New Data (hex)     | Notes
0x00 | 00 0000000 0000009   | 00 0000000 0000007 |
0x01 | 82 0000001 0000002   | 82 0000001 0000009 | *[a                                        ]
0x02 | 02 0000006 0000003   | 03 0000006 0000003 | 
0x03 | 00 0000004 0000005   | 80 0000004 0000005 | 
0x04 | 03 0000000 0000001   | 80 0000000 0000001 | Don't change
0x05 | 00 0000006 0000007   | 80 0000006 0000007 | 
0x06 | 03 0000000 0000001   | 03 0000000 0000001 | Don't change
0x07 | 02 0000004 0000008   | 03 0000004 0000008 | Don't change 
0x08 | 03 0000000 0000001   | 03 0000000 0000001 | Don't change
0x09 | X                    | 83 000000A 000000B |      *[[    ] [                          ]]
0x0A | X                    | 03 0000006 0000007 |         c  d    
0x0B | X                    | 02 0000000 000000C |                0  
0x0C | X                    | 82 000000D 000000E |                  *[[   ] [
0x0D | X                    | 03 0000002 0000003 |                     2 3   
0x0E | X                    | 02 0000000 000000F |                           0 [  
0x0F | X                    | 82 0000001 0000010 |                              *[a
0x10 | X                    | 02 0000004 0000011 |                                  [4 
0x11 | X                    | 02 0000004 0000004 |                                     4 b]
```
Without intelligently reusing memory space we will require 9 new memory spots we can do better


```
Addr | Data (hex)           | New Data (hex)     | Notes
0x00 | 00 0000000 0000009   | 00 0000000 0000007 |
0x01 | 82 0000001 0000002   | 82 0000001 0000002 | *[a                                        ]
0x02 | 02 0000006 0000003   | 80 0000003 0000005 |     *[[    ] [                          ]] 
0x03 | 00 0000004 0000005   | 00 0000006 0000007 |        c d
0x04 | 03 0000000 0000001   | 80 0000000 0000001 | Don't change
0x05 | 00 0000006 0000007   | 80 0000000 0000009 |                0 
0x06 | 03 0000000 0000001   | 03 0000000 0000001 | Don't change
0x07 | 02 0000004 0000008   | 03 0000004 0000008 | Don't change
0x08 | 03 0000000 0000001   | 03 0000000 0000001 | Don't change
0x09 | X                    | 80 000000A 000000B |                  *[[   ] [
0x0A | X                    | 03 0000002 0000003 |                     2 3    
0x0B | X                    | 02 0000000 000000C |                           0 [  
0x0C | X                    | 82 0000001 000000D |                              *[a
0x0D | X                    | 02 0000004 000000E |                                  [4 
0x0E | X                    | 02 0000004 0000004 |                                     4 b]
```

We can use the bottom version to only require 6 new memory spots to run `if then else`

Steps

1. Get 6 free memory addresses
2. populate the following registers, multiple state machines
```
a = 1       = addr 0x01 = execute_data[hed]
b = [0 1]   = addr 0x04 = execute_data[tel]->tel[hed]
c = [0 1]   = addr 0x06 = execute_data[tel]->tel->tel[hed]
d = [4 0 1] = addr 0x07 = execute_data[tel]->tel->tel[tel]
```
3. Save the following addresses
```
execute_data[tel]             = 2
execute_data[tel][tel]        = 3
execute_data[tel][tel][tel]   = 5
```



