------------------------------- MODULE memory -------------------------------

EXTENDS Integers, TLC

BufSize == 4
Writes == BufSize*3

(* --algorithm queue
variables buffer = [i \in 1..BufSize |-> -1], write_ind = BufSize, read_ind = BufSize, last_read = 0, did_proper_read = 1, 
target = [ a|-> FALSE, b |->-1 ],
write_buffer = [a |-> FALSE, b |-> 1],   \* struct, gives the values and enum them
write_index = [a |-> FALSE, b |-> 2],
read_buffer = [a |-> FALSE, b |-> 3],
read_index = [a |-> FALSE, b |-> 4],
W_Change = FALSE,
R_Change = FALSE, 
nothing = -1 

define
    Choose_Set(S) == CHOOSE x \in S : x.a=TRUE 
end define;

macro do_action(target) begin  \* Do every write and read action 
  if target.b = 1 then
    if read_ind + BufSize > write_ind then  \* Writer buffer action 
      buffer[1 + (write_ind % BufSize)] := write_ind;
      write_buffer.a := FALSE;
      W_Change := FALSE;
    end if ;
  elsif target.b = 2 then \* Writer index action
    if read_ind + BufSize > write_ind then 
      write_ind := write_ind + 1;
      write_index.a := FALSE ;
      W_Change := FALSE;
    end if ;

  elsif target.b = 3 then \* Reader buffer
    if read_ind < write_ind then
      last_read := buffer[1 + (read_ind % BufSize)];
      if last_read /= read_ind then
          did_proper_read := 0   \* If this read data is valid,
      end if;
      read_buffer.a := FALSE ;
      R_Change := FALSE ;
    end if ;
  elsif target.b = 4 then  \* read index
    if read_ind < write_ind then
      read_ind := read_ind + 1 ;
      read_index.a := FALSE ;
      R_Change := FALSE; 
     end if;
  else
    skip;
  end if ;
end macro;


fair process writer = 0
begin
 Write:
  while write_ind <= Writes do
   skip;
  W_op1:    \* Writer operation 1 : set write_buffer to true
   write_buffer.a := TRUE;
   W_Change := TRUE; \* set TRUE when there is operation on writer
  W_op2:    \* Writer operation 2 : fence for write_buffer and set write_index to true
   await write_buffer.a = FALSE ;
   write_index.a := TRUE ;
   W_Change := TRUE;
  W_Foo:
   skip;
  end while;
end process;

fair process reader = 1
begin
 Read:
  while read_ind <= Writes do
   skip;
   R_op1:   \* Reader operation 1 : set read_buffer to true
    read_buffer.a := TRUE;
    R_Change := TRUE;    \* set True when there is operation on reader
   R_op2:   \* Reader operation 2 : fence for read_buffer and set read_index to true
    await read_buffer.a = FALSE ;
    read_index.a := TRUE ;
    R_Change := TRUE;
   R_Foo:
    skip;
  end while;
end process;


fair process memory = 2
begin
 Memory:
  while write_ind <= Writes do
     skip;
     M_op1: \* memory operation 1 , wait until there is action for reader or writer, 
      await target.a = FALSE; \* wait until last memory operation is done 
      await R_Change = TRUE \/ W_Change = TRUE;
      target := CHOOSE x \in {write_buffer,write_index,read_buffer,read_index } : x.a=TRUE; \* choose the random value in the set
      if target.a = FALSE then \* make sure target get the value
       goto M_op1;
      else 
       goto M_op2;
      end if;
     M_op2:  \* do the action 
      do_action(target);
     M_op3:  \* done action 
      target.a := FALSE;
     M_Foo:
      skip;
  end while ;

end process;

end algorithm; *)
\* BEGIN TRANSLATION
VARIABLES buffer, write_ind, read_ind, last_read, did_proper_read, target, 
          write_buffer, write_index, read_buffer, read_index, W_Change, 
          R_Change, nothing, pc

(* define statement *)
Choose_Set(S) == CHOOSE x \in S : x.a=TRUE


vars == << buffer, write_ind, read_ind, last_read, did_proper_read, target, 
           write_buffer, write_index, read_buffer, read_index, W_Change, 
           R_Change, nothing, pc >>

ProcSet == {0} \cup {1} \cup {2}

Init == (* Global variables *)
        /\ buffer = [i \in 1..BufSize |-> -1]
        /\ write_ind = BufSize
        /\ read_ind = BufSize
        /\ last_read = 0
        /\ did_proper_read = 1
        /\ target = [ a|-> FALSE, b |->-1 ]
        /\ write_buffer = [a |-> FALSE, b |-> 1]
        /\ write_index = [a |-> FALSE, b |-> 2]
        /\ read_buffer = [a |-> FALSE, b |-> 3]
        /\ read_index = [a |-> FALSE, b |-> 4]
        /\ W_Change = FALSE
        /\ R_Change = FALSE
        /\ nothing = -1
        /\ pc = [self \in ProcSet |-> CASE self = 0 -> "Write"
                                        [] self = 1 -> "Read"
                                        [] self = 2 -> "Memory"]

Write == /\ pc[0] = "Write"
         /\ IF write_ind <= Writes
               THEN /\ TRUE
                    /\ pc' = [pc EXCEPT ![0] = "W_op1"]
               ELSE /\ pc' = [pc EXCEPT ![0] = "Done"]
         /\ UNCHANGED << buffer, write_ind, read_ind, last_read, 
                         did_proper_read, target, write_buffer, write_index, 
                         read_buffer, read_index, W_Change, R_Change, nothing >>

W_op1 == /\ pc[0] = "W_op1"
         /\ write_buffer' = [write_buffer EXCEPT !.a = TRUE]
         /\ W_Change' = TRUE
         /\ pc' = [pc EXCEPT ![0] = "W_op2"]
         /\ UNCHANGED << buffer, write_ind, read_ind, last_read, 
                         did_proper_read, target, write_index, read_buffer, 
                         read_index, R_Change, nothing >>

W_op2 == /\ pc[0] = "W_op2"
         /\ write_buffer.a = FALSE
         /\ write_index' = [write_index EXCEPT !.a = TRUE]
         /\ W_Change' = TRUE
         /\ pc' = [pc EXCEPT ![0] = "W_Foo"]
         /\ UNCHANGED << buffer, write_ind, read_ind, last_read, 
                         did_proper_read, target, write_buffer, read_buffer, 
                         read_index, R_Change, nothing >>

W_Foo == /\ pc[0] = "W_Foo"
         /\ TRUE
         /\ pc' = [pc EXCEPT ![0] = "Write"]
         /\ UNCHANGED << buffer, write_ind, read_ind, last_read, 
                         did_proper_read, target, write_buffer, write_index, 
                         read_buffer, read_index, W_Change, R_Change, nothing >>

writer == Write \/ W_op1 \/ W_op2 \/ W_Foo

Read == /\ pc[1] = "Read"
        /\ IF read_ind <= Writes
              THEN /\ TRUE
                   /\ pc' = [pc EXCEPT ![1] = "R_op1"]
              ELSE /\ pc' = [pc EXCEPT ![1] = "Done"]
        /\ UNCHANGED << buffer, write_ind, read_ind, last_read, 
                        did_proper_read, target, write_buffer, write_index, 
                        read_buffer, read_index, W_Change, R_Change, nothing >>

R_op1 == /\ pc[1] = "R_op1"
         /\ read_buffer' = [read_buffer EXCEPT !.a = TRUE]
         /\ R_Change' = TRUE
         /\ pc' = [pc EXCEPT ![1] = "R_op2"]
         /\ UNCHANGED << buffer, write_ind, read_ind, last_read, 
                         did_proper_read, target, write_buffer, write_index, 
                         read_index, W_Change, nothing >>

R_op2 == /\ pc[1] = "R_op2"
         /\ read_buffer.a = FALSE
         /\ read_index' = [read_index EXCEPT !.a = TRUE]
         /\ R_Change' = TRUE
         /\ pc' = [pc EXCEPT ![1] = "R_Foo"]
         /\ UNCHANGED << buffer, write_ind, read_ind, last_read, 
                         did_proper_read, target, write_buffer, write_index, 
                         read_buffer, W_Change, nothing >>

R_Foo == /\ pc[1] = "R_Foo"
         /\ TRUE
         /\ pc' = [pc EXCEPT ![1] = "Read"]
         /\ UNCHANGED << buffer, write_ind, read_ind, last_read, 
                         did_proper_read, target, write_buffer, write_index, 
                         read_buffer, read_index, W_Change, R_Change, nothing >>

reader == Read \/ R_op1 \/ R_op2 \/ R_Foo

Memory == /\ pc[2] = "Memory"
          /\ IF write_ind <= Writes
                THEN /\ TRUE
                     /\ pc' = [pc EXCEPT ![2] = "M_op1"]
                ELSE /\ pc' = [pc EXCEPT ![2] = "Done"]
          /\ UNCHANGED << buffer, write_ind, read_ind, last_read, 
                          did_proper_read, target, write_buffer, write_index, 
                          read_buffer, read_index, W_Change, R_Change, nothing >>

M_op1 == /\ pc[2] = "M_op1"
         /\ target.a = FALSE
         /\ R_Change = TRUE \/ W_Change = TRUE
         /\ target' = (CHOOSE x \in {write_buffer,write_index,read_buffer,read_index } : x.a=TRUE)
         /\ IF target'.a = FALSE
               THEN /\ pc' = [pc EXCEPT ![2] = "M_op1"]
               ELSE /\ pc' = [pc EXCEPT ![2] = "M_op2"]
         /\ UNCHANGED << buffer, write_ind, read_ind, last_read, 
                         did_proper_read, write_buffer, write_index, 
                         read_buffer, read_index, W_Change, R_Change, nothing >>

M_op2 == /\ pc[2] = "M_op2"
         /\ IF target.b = 1
               THEN /\ IF read_ind + BufSize > write_ind
                          THEN /\ buffer' = [buffer EXCEPT ![1 + (write_ind % BufSize)] = write_ind]
                               /\ write_buffer' = [write_buffer EXCEPT !.a = FALSE]
                               /\ W_Change' = FALSE
                          ELSE /\ TRUE
                               /\ UNCHANGED << buffer, write_buffer, W_Change >>
                    /\ UNCHANGED << write_ind, read_ind, last_read, 
                                    did_proper_read, write_index, read_buffer, 
                                    read_index, R_Change >>
               ELSE /\ IF target.b = 2
                          THEN /\ IF read_ind + BufSize > write_ind
                                     THEN /\ write_ind' = write_ind + 1
                                          /\ write_index' = [write_index EXCEPT !.a = FALSE]
                                          /\ W_Change' = FALSE
                                     ELSE /\ TRUE
                                          /\ UNCHANGED << write_ind, 
                                                          write_index, 
                                                          W_Change >>
                               /\ UNCHANGED << read_ind, last_read, 
                                               did_proper_read, read_buffer, 
                                               read_index, R_Change >>
                          ELSE /\ IF target.b = 3
                                     THEN /\ IF read_ind < write_ind
                                                THEN /\ last_read' = buffer[1 + (read_ind % BufSize)]
                                                     /\ IF last_read' /= read_ind
                                                           THEN /\ did_proper_read' = 0
                                                           ELSE /\ TRUE
                                                                /\ UNCHANGED did_proper_read
                                                     /\ read_buffer' = [read_buffer EXCEPT !.a = FALSE]
                                                     /\ R_Change' = FALSE
                                                ELSE /\ TRUE
                                                     /\ UNCHANGED << last_read, 
                                                                     did_proper_read, 
                                                                     read_buffer, 
                                                                     R_Change >>
                                          /\ UNCHANGED << read_ind, read_index >>
                                     ELSE /\ IF target.b = 4
                                                THEN /\ IF read_ind < write_ind
                                                           THEN /\ read_ind' = read_ind + 1
                                                                /\ read_index' = [read_index EXCEPT !.a = FALSE]
                                                                /\ R_Change' = FALSE
                                                           ELSE /\ TRUE
                                                                /\ UNCHANGED << read_ind, 
                                                                                read_index, 
                                                                                R_Change >>
                                                ELSE /\ TRUE
                                                     /\ UNCHANGED << read_ind, 
                                                                     read_index, 
                                                                     R_Change >>
                                          /\ UNCHANGED << last_read, 
                                                          did_proper_read, 
                                                          read_buffer >>
                               /\ UNCHANGED << write_ind, write_index, 
                                               W_Change >>
                    /\ UNCHANGED << buffer, write_buffer >>
         /\ pc' = [pc EXCEPT ![2] = "M_op3"]
         /\ UNCHANGED << target, nothing >>

M_op3 == /\ pc[2] = "M_op3"
         /\ target' = [target EXCEPT !.a = FALSE]
         /\ pc' = [pc EXCEPT ![2] = "M_Foo"]
         /\ UNCHANGED << buffer, write_ind, read_ind, last_read, 
                         did_proper_read, write_buffer, write_index, 
                         read_buffer, read_index, W_Change, R_Change, nothing >>

M_Foo == /\ pc[2] = "M_Foo"
         /\ TRUE
         /\ pc' = [pc EXCEPT ![2] = "Memory"]
         /\ UNCHANGED << buffer, write_ind, read_ind, last_read, 
                         did_proper_read, target, write_buffer, write_index, 
                         read_buffer, read_index, W_Change, R_Change, nothing >>

memory == Memory \/ M_op1 \/ M_op2 \/ M_op3 \/ M_Foo

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == writer \/ reader \/ memory
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(writer)
        /\ WF_vars(reader)
        /\ WF_vars(memory)

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION




=============================================================================
\* Modification History
\* Last modified Sun Dec 08 18:44:25 EST 2019 by linyungching
\* Created Sun Dec 08 17:28:36 EST 2019 by linyungching
