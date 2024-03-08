To get the nock for the addition gate I had to compile both the dec and the add function

in dojo this looks like
```
=addr =>  [a=@ b=@]
 !=
 |-
 ?:  =(0 a)  b
 $(a .*(a !=(=>(c=. =+(d=0 |-(?:(=(c +(d)) d $(d +(d)))))))), b +(b))
```

Followed by running

`.*([2 2] addr)`
