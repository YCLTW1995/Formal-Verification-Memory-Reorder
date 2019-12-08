
# Formal verification of memory model.

## Memory Model :
Lock-free code is dealing with memory reordering. 
Due to both compiler and hardware optimizations, loads and stores maybe be visible to other threads in a different order than on the writing thread. 
As an example,  
Initially :(x=y=0) <br/>
Thread1 | Thread2     
 x=1    |  a=y     
 y=2    |  b=x<br/>
 z=3    |  c=z <br/>
 Thread 2 is allowed to end with a=2 and b=0 because the load of b was ordered before the load of a. 
It can also exit with c=3 and a=b=0 because the store to z is ordered before the stores to x and y. 
As a result, memory fences exist to instruct the compiler and CPU that they cannot reorder memory. 
These are essential for properly writing lock-free code and one of the hardest parts to reason about, 
so it would be silly to work on formally verifying lock-free code without verifying orderings. 
 
