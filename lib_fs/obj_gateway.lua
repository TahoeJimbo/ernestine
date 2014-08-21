
--[[

   A gateway encapsulates information about off-switch services that can process
   a call. Most often, this is a provider connected to the PSTN, but it can
   be another switch as well.

]]--

Gateway = {}

-- PARSER KEYWORD DEFINITIONS

g_gateway_defaults_keywords = {
         "domestic_numbering_plan",
         "local_code",
         "outbound_emergency_format",
         "outbound_service_format",
         "outbound_local_format",
         "outbound_domestic_format",
         "outbound_intl_format",
         "allowed_call_kinds",
}

g_gateway_parser_keywords = {
         "domestic_numbering_plan",
         "local_code",
         "outbound_emergency_format",
         "outbound_service_format",
         "outbound_local_format",
         "outbound_domestic_format",
         "outbound_intl_format",
         "outbound_prefix",
         "allowed_call_kinds",
         "name", "freeswitch_profile", "trunk_access_code",
         "location"
}

--
-- Configure a gateway as described in the parser-generated
-- configuration_table.
--
-- We use the parent controller's notion of the current defaults, and use them
-- when keywords are missing in the configuration file.
--
                                                                    --[[ GATEWAY:NEW ]]--
function Gateway:new(config_pairs, controller)

   if config_pairs == nil then
      logError("Invalid argument")
      return nil
   end

   local object = {}

   setmetatable(object, self)
   self.__index = self

   -- Copy the pairs in...

   for _, kw in ipairs(g_gateway_parser_keywords) do
      if config_pairs[kw] == nil then
	 config_pairs[kw] = controller["def_"..kw]
      end

      object[kw] = config_pairs[kw]
   end

   -- Sanity check

   -- FIXME: CHECK THAT LOCATION IS DEFINED

   return object
end

--
-- Give a number object and location, create an outbound dialstring that
-- FreeSWITCH should use to complete the call.  The source_location_obj
-- determines which caller ID values to send to the gateway.
--
                                           -- [[ GATEWAY:MAKE_DESTINATION_FOR_NUMBER ]]--

function Gateway:make_destination_for_number(destination_number_obj, source_location_obj)

   if DEBUG_GATEWAY then
      logInfo("Making destination string from "..destination_number_obj:description()..
		 " in "..source_location_obj.id)
   end

   local dialstring

   local cid_name, cid_number = source_location_obj:get_caller_id_info()

   if destination_number_obj.kind == "emergency" then
      --
      -- Yowza.  Most important code I think I've written 
      -- follows...
      --
      if self.e911_id then
	 cid_number = self.e911_id
      end
   end

   -- Create the base destination dialstring...

   local base_ds = "sofia/gateway/"..self.freeswitch_profile.."/"

   local kind = destination_number_obj.kind
   local output_format = self["outbound_"..kind.."_format"]

   if not output_format then
      logError("Gateway <"..self.name.."> has no dial string for "..kind
		  .." type calls.")
      return nil
   end

   -- And add the formatted number to it, including any prefix 
   -- required by the provider.

   local formatted_number = destination_number_obj:format(output_format)

   if not formatted_number then
      logError("Gateway <"..self.name.."> could not format number for "
		  ..kind.." type call.")
      return nil
   end

   if self.outbound_prefix then
      base_ds = base_ds..self.outbound_prefix
   end

   base_ds = base_ds..formatted_number

   local destination = Destination:new()

   destination:set_sofia_dialstring(base_ds)
   destination:set_source_caller_id(cid_name, cid_number)

   if DEBUG_GATEWAY then
      logInfo("Returning destination "..destination:description())
   end

   return destination
end
