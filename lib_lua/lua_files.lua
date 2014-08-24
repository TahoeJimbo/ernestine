

-----FILE UTILS----------------------------------------------------------------

function PRIV_execute(command)

   if DEBUG_FILE then
      logInfo("exec: <"..command..">")
   end

   local ok, term_method, status_code = os.execute(command)

   if ok then
      return true
   end

   logError("exec failed: <"..command..">: "..term_method.." "..status_code)

   return false
end

--[[ RENAME --]]

function file_rename(source_file, dest_file)

   if source_file == dest_file then
      logError("rename failed: files have same name: "..source_file)
      return false
   end

   local command = "mv "..source_file.." "..dest_file

   local result = PRIV_execute(command)
   return result;
end

--[[ DELETE --]]

function file_delete(path)
   local command = "rm "..path

   local result = PRIV_execute(command)
   return result;
end

--[[ RECURSIVE_DELETE --]]

function file_recursive_delete(path)
   local command = "rm -rf "..path

   local result = PRIV_execute(command)
   return result;
end

--[[ MKDIR --]]

function file_mkdir(path)
   local command = "mkdir "..path

   local result = PRIV_execute(command)
   return result
end

--[[ EXISTS --]]

function file_exists(name)
   local test_file = io.open(name, "rb")

   if (test_file == nil) then
      return false
   end

   test_file:close()
   return true
end
