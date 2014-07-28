
-----OS UTILS-------------------------------------------------------------


debug_execute = true;

function log_osex(result, command)

    if (debug_os == true) and (result == 0) then
       logInfo("Executed <"..command..">")
    end

    if (result ~= 0) then
        logError("Error "..result.." executing <"..command..">")
    end
end

function execute_and_capture(cmd, raw)
   local f = assert(io.popen(cmd, 'r'))
   local s = assert(f:read('*a'))
   f:close()
   if (raw == true) then return s end

  -- Process the string and return a table of strings.

  s = string.gsub(s, '^%s+', '')
  s = string.gsub(s, '%s+$', '')

  local results = {}
  
  results = string_split(s, "\n")

  return results
end
