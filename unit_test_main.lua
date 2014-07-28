
-- PROCESS ARGUMENTS

if (argv) then
   args = argv
end

--
-- Dialplan args
--

if (#arg == 0) then
   logError("No arguments.");
   return;
end

if     arg[1] == "DIALPLAN" then dialplan_unittest();
elseif arg[1] == "RECITE"   then recite_unittest();
end


