

-----STRING UTILS--------------------------------------------------------------

-- Splits a string containing delimiter into an array of strings.
-- splitStr("2133;4211;1234;121", ";") ---> { "2133", "4211", "1234", "121" }

function string_split(str, delimiter)

   local index = 0;
   local results = {};
   local untrimmed;
   local final;

   local delimStart, delimEnd

   repeat
      delimStart, delimEnd = string.find(str, delimiter);

      index = index + 1;

      if (delimStart) then
	 untrimmed = string.sub(str, 1, delimStart - 1);
	 results[index] = string.match(untrimmed, "^%s*(.*)%s*$");

	 str = string.sub(str, delimEnd + 1);
	 --print("<"..results[index]..">  Remain: <"..str..">");
      else
	 final = string.match(str, "^%s*(.*)%s*$");
	 if (final == "") then
	    return results;
	 end

	 results[index] = final;
	 --print("<"..results[index]..">");
	 return results;
      end
   until (#str == 0);

   return results;
end


function string_parse_true_false(token)

   if token == nil then return nil; end

   if type(token) == "boolean" then return token; end

   local token = token:upper()

   if token == "YES" or token == "TRUE" or token == "ON" or token == "1" then
      return true
   end

   if token == "NO" or token == "FALSE" or token == "OFF" or token == "0" then
      return false
   end

   return nil
end
