import os
from ecflow import Defs,Suite,Task,Edit
    
print("Creating suite definition")
home = os.path.join(os.getenv("HOME"),"course")
defs = Defs(
        Suite('test',
            Edit(ECF_HOME=home),
            Task('t1')))
print(defs)
