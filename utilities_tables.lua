
function table_append(table, item)
   local index = #table;

   index = index + 1;
   table[index] = item;
end

table_private = {}
table_private.spaces="                                "

function table_private.dump_recursive(theTable, indent)
   
   -- sort the keys to lend a deterministic flair to things.
   -- (And to not confuse the unit-test output comparator.)

   local sorted_keys = {}
   local key

   for key in pairs(theTable) do sorted_keys[#sorted_keys + 1] = key; end

   table.sort(sorted_keys)
   
   for _, key in ipairs(sorted_keys) do
      local value = theTable[key]

      if (value == nil) then value = "(nil)"; end

      if type(value) == "table" then
	 local indentString = table_private.spaces:sub(1, indent * 3)
	 print(indentString..key.." is a table:")
	 table_private.dump_recursive(value, indent + 1)
      else
	 local indentString = table_private.spaces:sub(1,indent * 3)
	 print(indentString..key.."\t"..value)
      end
   end
end

function table_dump(header, theTable)
   local key, value;

   print(header);

   table_private.dump_recursive(theTable, 0)
end

