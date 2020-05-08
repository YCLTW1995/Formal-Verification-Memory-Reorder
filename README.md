
# Formal verification of memory model.
verify the correctness of a out of order lock-free ringbuffer
## Project Overview  
For this project, we are going to verify the correctness of a lock-free ringbuffer. There are two key goals for our verification model. First, with the caveat that the writer will not pause for a slow reader and instead will overwrite the reader. The reader then has to properly detect that it may have invalid state without relying on the message contents. Second, due to the compiler optimization, there might exist different order in different threads for stores and loads operation. Our model must able to detect every stores and loads are in correct order in multiple thread system.  We will carry out these verification by verifying a TLA+/Pluscal model of the ringbuffer. 
## Background 
Lock-Free RingBuffers Lock-free ringbuffers are ideal tools for high performance communication between cpu cores, such as for high-throughput/low latency message passing or for DMA communication with hardware. In some situations, it can be advantageous to augment the performance properties further by having the writer ignore the position of readers, and force readers to detect when their state has been invalidated. For example, this can be useful to prevent one slow reader from blocking others. However, writing correct lock-free code is extremely difficult due to complex concurrency management and hardware/compiler memory models. The fact that the writer is expected to write over memory in use by the reader adds another layer of complexity in that the reader must be able to detect overwrites in addition to understanding when it can read at all. 
## Memory Model  
One of the trickiest parts of lock-free code is dealing with memory reordering. Due to both compiler and hardware optimizations, loads and stores may be be visible to other threads in a different order than on the writing thread. As an example, 
 
 (x=y=0) Thread 1    Thread 2    
           x=1         a=y 
           y=2         b=x   
           z=3         c=z 
 Thread 2 is allowed to end with a=2 and b=0 because the load of b was ordered before the load of a. It can also exit with c=3 and a=b=0 because the store to z is ordered before the stores to x and y. As a result, memory fences exist to instruct the compiler and CPU that they cannot reorder memory. These are essential for properly writing lock-free code and one of the hardest parts to reason about, so it would be silly to work on formally verifying lock-free code without verifying orderings. 
