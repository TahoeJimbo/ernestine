

private_log = {}

function private_log.getHeader()
   --
   -- get the function that called us
   --

   local info
   local function_name

   if (COMPATIBILITY_MODE == true) then 
      info = debug.getinfo(3, "nSl")
   else
      info = debug.getinfo(2, "nSl")
   end

   if info.name == nil then
      function_name = "main-chunk"
   else
      function_name = info.name
   end

   if DEBUG == true then
      return info.short_src..":"..info.currentline..": "..function_name.."(): "
   else
      return info.short_src..": "..function_name.."(): "      
   end
   
end

function logInfo(message)
   freeswitch.consoleLog("notice", private_log.getHeader()..message.."\n");
end

function logError(message)
   freeswitch.consoleLog("crit", private_log.getHeader()..message.."\n");
end


