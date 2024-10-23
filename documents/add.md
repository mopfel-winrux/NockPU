To get the nock for the addition gate I had to compile both the dec and the add function

in dojo this looks like
```
=addr =>  [a=@ b=@]
 !=
 |-
 ?:  =(0 a)  b
 $(a .*(a !=(=>(c=. =+(d=0 |-(?:(=(c +(d)) d $(d +(d)))))))), b +(b))
```
NOTE: "you don't actually want to compile the =>, you just want it there to set the subject expectations for the hoon compiler" - ~master-morzod


Followed by running

`.*([2 2] addr)`
