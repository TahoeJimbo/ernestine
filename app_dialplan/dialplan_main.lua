
--[[

   The dialplan application routes calls from private (internal)
   and public (external) sources.

-- APPLICATION ARGUMENTS

   "dialplan" is called from the XML dialplan with the following arguments:

   dialplan {inbound|outbound} {destination_digits} {public|private}

   "inbound" is used when a call arrives at FreeSWITCH for an internal
   extension.  This call can be from an private (internal) extension
   or a public (external) PSTN number.

   "outbound" is used when a call is placed from a private (internal)
   extension to a public PSTN number.  (Outbound can also be used
   by applications, like an IVR to transfer a call off-switch)

   {destination_digits} are the digits dialed by the caller.  From
   private extensions, it's the extension number.  From public PSTN
   calls, it's the 11 digit (NANPA) number.

   "public" marks the source of the call as the PSTN.
   "private" marks the source of the call as an internal extension.

-- FLOW

 -- INBOUND from PUBLIC

    Inbound PSTN calls: (e.g.: "dialplan inbound 15305239155 public")
   
    Inbound calls from the PSTN are compared against a table of 
    possible destinations in dispatch_external() and are routed
    to the dispatch_internal() function for disposition.

 -- INBOUND from PRIVATE

    Inbound local extensions: (e.g.: dialplan inbound 8001 private")
   
    Inbound calls from local extensions are routed directly through
    the dispatch_internal() function as they're less prone to
    security concerns. :-)  
   
    The dispatch_internal() function uses a table of extension
    names/numbers mapping the requested extension to a list of
    destination extensions. ---> SEE dialplan_config.txt for the table.

    The call is handled based on the instructions in the
    destination extension's dialstring.  (e.g.: "ring 8001 for 30
    seconds, then transfer to voicemail box 546)

 -- OUTBOUND from PUBLIC
    
    Typically this is not allowed for security reasons, unless
    it is mediated from an IVR application that knows what it is
    doing.

 -- OUTBOUND from PRIVATE

    Outbound calls: (e.g.: "dialplan outbound 18314650752 private"

    Are parsed to determine the "kind" (international, domestic, local or
    "SSN" (special services 311,411,911, etc.)) and are sent to
    route_to_carrier().  Route to carrier uses whatever logic it needs
    to route a call to the appropriate carrier.
 
]]--


local dialplan_parser_config = {
   { group_name = "Location",           keywords = g_location_parser_keywords  },
   { group_name = "Gateway",            keywords = g_gateway_parser_keywords   },
   { group_name = "Gateway_Defaults",   keywords = g_gateway_defaults_keywords },
   { group_name = "Route",              keywords = g_route_parser_keywords     },
   { group_name = "Route_Defaults",     keywords = g_route_defaults_keywords   },
}

function process_dialplan_inbound(extension, context)

   logError("Starting dialplan: Extension "..extension
	    ..", Context: "..context);
   dialplan_entrypoint_inbound(session, context, extension);
   logError("Finishing dialplan: Extension "..extension
	    ..", Context: "..context);
end

function process_dialplan_outbound()
   if (#arg ~= 3) then
      logError("Wrong number of arguments.");
      return;
   end

   local extension = arg[2];
   local context = arg[3];

   logError("Starting dialplan: Extension "..extension
	    ..", Context: "..context);
   dialplan_entrypoint_outbound(session, context, extension);
   logError("Finishing dialplan: Extension "..extension
	    ..", Context: "..context);
end

----------------------------------------------------------------
-- MAIN
----------------------------------------------------------------

-- GATHER SOME INITIAL DATA
-- and turn them into global variables.

-- PROCESS ARGUMENTS

if (argv) then
   arg = argv
end

for key, value in ipairs(arg) do
   if DEBUG then logInfo("Arg: "..key.." = "..value); end
end

if (#arg ~= 3) then
   logError("Expecting three arguments.")
   return
end

local config_parser, error_message = Parser:new(SCRIPTS.."dialplan_config.txt",
						dialplan_parser_config)

if not config_parser then
   logError("Cannot parse configuration file.")
   return
end

--table_dump("Config array", config_parser.config_array)

gLocations  = Location_ctrl:new(config_parser.config_array)
gGateways   =  Gateway_ctrl:new(config_parser.config_array)
gRoutes     =    Route_ctrl:new(config_parser.config_array)

if gLocations == nil or gGateways == nil or gRoutes == nil then
   logError("Error parsing configuration file.")
   return
end

if (session) then
   source_obj = Source:new(session)
end


--location.load()


local destination_digits = arg[2]
local context = arg[3]

if (arg[1] == "inbound") then
   logError("STARTING INBOUND DIALPLAN: dest=<"..destination_digits..">, "
	       .."context=<"..context..">");

   dispatch_inbound(source_obj, context, destination_digits, nil)

   logError("ENDING INBOUND DIALPLAN: dest=<"..destination_digits..">, "
	       .."context=<"..context..">");
   return
end

if (arg[1] == "outbound") then
   logError("STARTING OUTBOUND DIALPLAN: dest=<"..destination_digits..">, "
	       .."context=<"..context..">");

   dispatch_outbound(source_obj, context, destination_digits, nil)

   logError("ENDING OUTBOUND DIALPLAN: dest=<"..destination_digits..">, "
	       .."context=<"..context..">");
   return
end

--
-- Ack. Extreme brokenness here. :-)
--

sounds.sit(aLeg, "vacant")


