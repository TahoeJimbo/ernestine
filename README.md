## freeswitch-router

While largely specific to my situation, this LUA code is "generic enough" to be helpful to
others attempting to integrate FreeSWITCH™ into their own integrated calling environments.

Two lua objects ("Dialstring" and "Destination") are worth mentioning here.

The "Dialstring" object implements a simplified FreeSWITCH™ dialstring allowing
you to cram the basics of call flow into a short string describing
which extensions to ring, in what order, and what should happen if nobody answers.

For example:

    "wait=30|8000:8001:8002|4000:wait=60,4001|VM(8000)"
  
Translates to "ring 8001, 8001, 8002 at the same time.  If nobody answers after 30 seconds
then ring 4000 and 4001.  Give 4001 a fill minute to answer.  If nobody answers, send to
voicemail box 8000.

The "Destination" object can work from a "Dialstring" or a standard FreeSWITCH™ or sofia (SIP) dialstring and
manages the process of ringing and connecting the calling party to the destination, or returning a simple
code and an error message explaining why it couldn't.

### Dialplan Processor

The diaplan processor `dialplan_*.lua` reads the `diaplan_config.txt` file, containing easily 
configurable gateways and routing patterns.

It can route calls based on time-of-day, user location, incoming DID, etc.  Again, this stuff is largely specific to my needs, but is "generic enough" to be helpful to others.

####Dialplan Configuration Examples

_User Location Management/E-911_

```
Location {
           id = "tahoe"
           description = "Lake Tahoe, CA"

           numbering_plan = "NANPA"
           local_code = "530"

           default_caller_id_name = "Jim Hayes (TAHOE)"
           default_caller_id_number = "530523xxxx"

           activation_code = "*8"    # "*T"
           confirmation_msg = "Home_Auto/location-set-to-lake-tahoe.wav"

           e911_id = "530523xxxx"
}
```

_Inbound/Outbound Gateway_

```
Gateway {
        name = "grandstream-tahoe"
        freeswitch_profile = "public::grandstream-tahoe"
        allowed_call_kinds = "service, emergency"

        trunk_access_code = "*9"    #-- This allows direct access to the PSTN dialtone
                                    #-- from internal callers.
        location = "tahoe"

        outbound_local_format = "%l"
        outbound_intl_format = "011%c"
}
```
_Inbound Routing based on DID_

```
Route {
        id = "1530523xxxx"
        description = "Tahoe Main Number, inbound from FlowRoute"
        route = "GOTO(Jim)"
}

Route {
        id = "1530523xxxx"
        description = "Direct to Voicemail, inbound from FlowRoute"
        route =   "GOTO(Jim_DirectVM)"
}

```
_Call Treatments_

```
Route { id = "Jim"
        route = "IF_TIME(2100,0200,Jim_GoneToSleep)"     # 9 pm to 2 am
               +"|IF_TIME(0200,0800,Jim_NotAwakeYet)"    # 2 am to 8 am
               +"|IF_LOC(546,tahoe,Jim_Tahoe)"           # in tahoe
               +"|IF_LOC(546,scruz,Jim_Scruz)"           # in santa cruz
               +"|IF_LOC(546,away,Jim_Outside)"          # or outside
               +"|GOTO(Jim_Tahoe)"                       # catch-all
}

Route { id = "Jim_GoneToSleep" route = "VM(546,2)" }     # BOX 546, greeting 2
Route { id = "Jim_NotAwakeYet" route = "VM(546,3)" }     # BOX 546, greeting 3

Route { id = "Jim_Tahoe" route = "wait=30|8001:8002:8003|VM(546)" }
Route { id = "Jim_Scruz" route = "wait=30|4001|VM(546)" }
Route { id = "Jim_Outside" route = "wait=30|7001|4001|VM(546)" }

Route { id = "*3246"   route = "APP(echo_test)" }          #   *ECHO

```

You get the idea...

Calling the dial plan from FreeSWITCH's XML diaplan is as simple as setting up rules like this
to match your configuration.  These are just a few examples. 

```
  <extension name="generic-internal">
    <condition field="destination_number" expression="^(\d{4,5})$">
      <action application="set" data="sip_to_user=$1" />
      <action application="lua" data="dialplan inbound ${sip_to_user} private"/>
    </condition>
  </extension>

  <extension name="star-codes">
    <condition field="destination_number" expression="^(\*\d+)$">
      <action application="set" data="sip_to_user=$1" />
      <action application="lua" data="dialplan inbound ${sip_to_user} private"/>
    </condition>
  </extension>
  
  
```

### Simple Voicemail
A brutally simple voicemail client is included, and again, it's probably good for showing how to do FreeSWITCH™ stuff in Lua.  (Or as a starting point for your own system.)  It has a long way to go before being antyhing more than useful to me. :-)
