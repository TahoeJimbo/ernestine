## freeswitch-router
=================

While largely specific to my situation, this LUA code is "generic enough" to be helpful to
others attempting to integrate FreeSWITCH into their own integrated calling environments.

Two lua objects ("Dialstring" and "Destination") are worth mentioning here.

The "Dialstring" object implements a simplified freeswitch dialstring allowing
you to cram the basics of call flow into a short string describing
which extensions to ring, in what order, and what should happen if nobody answers.

For example:

    "wait=30|8000:8001:8002|4000:wait=60,4001|VM(8000)"
  
Translates to "ring 8001, 8001, 8002 at the same time.  If nobody answers after 30 seconds
then ring 4000 and 4001.  Give 4001 a fill minute to answer.  If nobody answers, send to
voicemail box 8000.

The "Destination" object can work from a "Dialstring" or a standard freeswitch or sofia (SIP) dialstring and
manages the process of ringing and connecting the calling party to the destination, or returning a simple
code and an error message explaining why it couldn't.

### Other Stuff

The diaplan processor `dialplan_*.lua` reads the `diaplan_config.txt` file, containing easily 
configurable extensions and routing patterns.  For example

```
Example to come
```
