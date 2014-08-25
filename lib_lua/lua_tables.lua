
function table_append(table, item)
   local index = #table;

   index = index + 1;
   table[index] = item;
end

table_private = {}
table_private.spaces="                                "


function table_dump(header, theTable, output_func)

   output_func = output_func or print

   output_func(header);
   table_private.dump_recursive(theTable, 0, output_func)
end

---------- PRIVATE ----------------------------------------------------------------------

function table_private.dump_recursive(theTable, indent, output_func)
   
   -- sort the keys to lend a deterministic flair to things.
   -- (And to not confuse the unit-test output comparator.)

   local sorted_keys = {}

   for key in pairs(theTable) do sorted_keys[#sorted_keys + 1] = key; end

   table.sort(sorted_keys)
   
   for _, key in ipairs(sorted_keys) do
      local value = theTable[key]
      local indentString = table_private.spaces:sub(1, indent * 3)

      if (value == nil) then value = "(nil)"; end

      if type(value) == "table" then

	 if (key ~= "__index") then 
	    output_func(indentString..key.." is a table:")
	    table_private.dump_recursive(value, indent + 1, output_func)
	 else
	    output_func(indentString..key.." is an __index table. Skipping.")
	 end
      elseif type(value) == "function" then
	 output_func(indentString..key.." is a function.")
      elseif type(value) == "boolean" then
	 local boolString
	 if value == true then boolString = "true"; else boolString = "false"; end
	 output_func(indentString..key.."\t"..boolString)
      else
	 output_func(indentString..key.."\t"..value)
      end
   end
end


