
-----RECITATION UTILITIES------------------------------------------------------

recite = {}

numbers={ }
numbers["0"] = "cardinal/0.wav"
numbers["1"] = "cardinal/1.wav"
numbers["2"] = "cardinal/2.wav"
numbers["3"] = "cardinal/3.wav"
numbers["4"] = "cardinal/4.wav"
numbers["5"] = "cardinal/5.wav"
numbers["6"] = "cardinal/6.wav"
numbers["7"] = "cardinal/7.wav"
numbers["8"] = "cardinal/8.wav"
numbers["9"] = "cardinal/9.wav"
numbers["@"] = "cardinal/at.wav"
numbers["-"] = "cardinal/dash.wav"
numbers["$"] = "cardinal/dollar.wav"
numbers["."] = "cardinal/dot.wav"
numbers["="] = "cardinal/equals.wav"
numbers["!"] = "cardinal/exclamation-point.wav"
numbers["-"] = "cardinal/minus.wav"
numbers["#"] = "cardinal/pound.wav"
numbers["/"] = "cardinal/slash.wav"
numbers[" "] = "cardinal/space.wav"

function recite.from_list(call_leg, list)
   for _, file in ipairs(list) do
      ivr.play(call_leg, file);
   end
end

-----DEFINITIONS---------------------------------------------------------------

-- Recitation style:

-- * "phone" tries to speak the number in a way that sounds pleasant to
--   humans, with special emphasis on the standard US phone number format.
--
-- * "smart digit" tries to speak the digits of a number with a 
--   two digit cadence, and two or three digits in the final chunk
--   depending on the number of digits.
--
-- * "monatone digit" speaks every digit the same.
--
-- * "smart number" tries to speak the given number as if you were
--   spelling it out in english words.  123 = "one hundred twenty three"
--


-----PRIVATE UTILITIES---------------------------------------------------------


-- PHONE NUMBER CHUNKIFYING --

-- US Phone numbers have a specific cadence to them.
-- (AAA) XXX-YYZZ
--
-- numeric digits in the chunkifying code are treated as either
-- a "beginning" digit (higher pitch, longer duration)
-- a "mid-short" digit (normal pitch, short duration)
-- a "mid-long" digit (normal pitch, longer duration)
-- an "end" digit (lower pitch, longer duration)
-- 
-- AAA: "area code" + beg,mid-short,mid-long
-- XXX: beg,mid-short,mid-long
-- YY:  beg,mid-long
-- ZZ:  mid-short, end

function recite.PRIV_make_phone_two_digit_playlist(list, digits, isLast)

   assert(#digits == 2)

   local file_name

   -- Prevoiced digits?

   if (isLast) then
      file_name = NUMBERS.."phone/"..digits.."-end.wav"
   else
      file_name = NUMBERS.."phone/"..digits.."-beg.wav"
   end

   if (file_exists(file_name)) then

      -- YUP!

      table_append(list, file_name)
      return list
   end

   -- Nope.  Construct it by hand.


   local x = string.sub(digits, 1, 1)
   local y = string.sub(digits, 2, 2)

   if (isLast) then
      table_append(list, NUMBERS.."phone/"..x.."-mid-short.wav")
      table_append(list, NUMBERS.."phone/"..y.."-end.wav")
   else
      table_append(list, NUMBERS.."phone/"..x.."-beg.wav")
      table_append(list, NUMBERS.."phone/"..y.."-mid-long.wav")
   end

   return list
end

function recite.PRIV_make_phone_prefix_playlist(list, digits)

   assert(#digits == 3)

   -- Pre-voiced complete prefix?

   local file_name = NUMBERS.."phone/"..digits.."-beg.wav"

   if (file_exists(file_name)) then

      -- YUP!

      table_append(list, file_name);
      return list
   end

   -- Construct the thing by hand.

   for index=1, 3 do
      local x = string.sub(digits, index, index)
      
      if (index == 1) then
	 tag = "-beg.wav"
      end

      if (index == 2) then
	 tag = "-mid-short.wav"
      end

      if (index == 3) then
	 tag = "-mid-long.wav"
      end

      file_name = NUMBERS.."phone/"..x..tag
      
      if (file_exists(file_name)) then
	 table_append(list, file_name)
      end
   end

   return list
end

function recite.PRIV_make_phone_areacode_playlist(list, digits)

   -- Pre-voiced complete areacode?

   file_name = NUMBERS.."phone/ac-"..digits..".wav"
   if (file_exists(file_name)) then

      -- YUP!

      table_append(list, file_name);
      return list
   end

   -- Nope.  Have to construct one...

   table_append(list, NUMBERS.."phone/area-code.wav")

   return recite.PRIV_make_phone_prefix_playlist(list, digits)

end

function recite.PRIV_make_smart_digit_playlist(list, digits)
   
   local len = #digits
   local digits_left = len
   local digit_index = 1

   while (digits_left > 3) do
      --
      -- get the next two digits. 
      --
      local x = string.sub(digits, digit_index, digit_index + 1)

      list = recite.PRIV_make_phone_two_digit_playlist(list, x, false)

      digit_index = digit_index + 2
      digits_left = digits_left - 2
   end

   -- OK, now we have 1, two or three digits left...

   if (digits_left == 1) then
      local x = string.sub(digits, digit_index, digit_index)
      table_append(list, NUMBERS.."phone/"..x.."-end.wav")
   end

   if (digits_left == 2) then
      local x = string.sub(digits, digit_index, digit_index + 1)
      list = recite.PRIV_make_phone_two_digit_playlist(list, x, true)
   end

   if (digits_left == 3) then
      local x = string.sub(digits, digit_index, digit_index)
      local y = string.sub(digits, digit_index + 1, digit_index + 1)
      local z = string.sub(digits, digit_index + 2, digit_index + 2)

      if (len == 3) then
	 table_append(list, NUMBERS.."phone/"..x.."-beg.wav")
      else
	 table_append(list, NUMBERS.."phone/"..x.."-mid-long.wav")
      end
      
      table_append(list, NUMBERS.."phone/"..y.."-mid-short.wav")
      table_append(list, NUMBERS.."phone/"..z.."-end.wav")
   end

   return list
end

function recite.PRIV_make_phone_number_playlist(list, digits)

   local len=#digits
   local area_code
   local prefix
   local number1, number2

   -- 7, 10, and 11 digit numbers are most likey US style numbers, so they
   -- get special treatment. Anything else just gets a standard digit
   -- recitation.

   
   local not_usa_format = true

   if (len == 7 or len == 10 or 
       (len == 11 and string.sub(digits,1, 1) == "1")) then

      not_usa_format = false
   end

   if (not_usa_format) then
      list = recite.PRIV_make_smart_digit_playlist(list, digits)
      return list;
   end

   -- Yay! We've got the north american format!

   -- 11 digit numbers beginning with "1" get special treatment.  We 
   -- skip the 1

   if ((len == 11) or (len == 10)) then

      if (len == 11) then
	 start = 1
      else 
	 start = 0
      end

      area_code = string.sub(digits, start+1, start+3)
      prefix = string.sub(digits, start+4, start+6)
      number1 = string.sub(digits, start+7, start+8)
      number2 = string.sub(digits, start+9, start+10)
   end

   if (len == 7) then
      area_code = nil;
      prefix = string.sub(digits, 1, 3)
      number1 = string.sub(digits, 4, 5)
      number2 = string.sub(digits, 6, 7)
   end

   if (area_code) then
      list = recite.PRIV_make_phone_areacode_playlist(list, area_code)
   end

   list = recite.PRIV_make_phone_prefix_playlist(list, prefix)
   list = recite.PRIV_make_phone_two_digit_playlist(list, number1, false)
   list = recite.PRIV_make_phone_two_digit_playlist(list, number2, true)

   return list;
end

--
-- Make a number between "one" and "nine-hundred-ninety-nine"
--

function recite.PRIV_make_human_triple(list, number)

   if (number == 0 or number > 999) then
      logError("make_human_triple: "..number.." is out of range.")
   end

   local hundreds = math.floor(number/100)
   number = number % 100

   local tens = math.floor(number/10)
   local ones = number % 10

   if (hundreds > 0) then
      table_append(list, NUMBERS.."cardinal/"..hundreds..".wav")
      table_append(list, NUMBERS.."cardinal/hundred.wav")
   end

   if (number <= 20) then
      -- Use the pre-constructed numbers through 20.
      table_append(list, NUMBERS.."cardinal/"..number..".wav")
      return list
   end

   if (tens > 0) then 
      table_append(list, NUMBERS.."cardinal/"..tens.."0.wav")
   end

   if (ones > 0) then
      table_append(list, NUMBERS.."cardinal/"..ones..".wav")
   end

   return list
end

-- Convert a number into an array of filenames to be played.
-- Arguments:
--  menu: the array to append filenames to.
--  number: The integer to recite

-- EXAMPLE:  320 = "three-hundred twenty"

function recite.PRIV_make_human_number_playlist(list, number)

   number = number + 0

   if (number < 0 or number > 999999999) then
      logError("make_human_number: "..number.." is out of range.")
   end

   if (number == 0) then 
      table_append(list, NUMBERS.."cardinal/0.wav")
      return list
   end

   local millions = math.floor(number/1000000)
   number = number % 1000000

   if (millions > 0) then
      list = recite.PRIV_make_human_triple(list, millions)
      table_append(list, NUMBERS.."cardinal/million.wav")
   end

   local thousands = math.floor(number/1000)
   number = number % 1000

   if (thousands > 0) then
      list = recite.PRIV_make_human_triple(list, thousands)
      table_append(list, NUMBERS.."cardinal/thousand.wav")
   end

   if (number > 0) then
      list = recite.PRIV_make_human_triple(list, number)
   end

   return list
end


-----PUBLIC--------------------------------------------------------------------

---------------------------
-- RECITE DIGIT BY DIGIT --
---------------------------

-- EXAMPLE: "123.23" = "one two three point two three"

-- Recite a number (provided as a string), digit by dight (including special characters)

function recite.number_digits_monotone(leg, digits_as_string)

   local len=#digits_as_string

   for index=1,len do
      local x = string.sub(digits_as_string, index, index)

      file_name = numbers[x]
      
      if (file_name ~= nil) then
	 file_name = NUMBERS..file_name
	 if (file_exists(file_name)) then
	    ivr.play(leg, file_name)
	 end
      end
   end
end

function recite.number_digits_smart(leg, digits_as_string)
   local list = {}

   list = recite.PRIV_make_smart_digit_playlist(list, digits_as_string)
   recite.from_list(leg, list)
end



-----------------------------
-- RECITE LIKE A HUMAN WOULD
-----------------------------
--
-- EXAMPLE:  320 = "three-hundred twenty"
--

function recite.number_as_human(leg, number)

   local list = {}

   list = recite.PRIV_make_human_number_playlist(list, number)
   recite.from_list(leg, list);

end

function recite.make_human_number_playlist(list, number)
   return recite.PRIV_make_human_number_playlist(list, number)
end

-------------------------
-- RECITE A PHONE NUMBER
-------------------------

function recite.phone_number(leg, phone_number)

   local list = {};

   list = recite.PRIV_make_phone_number_playlist(list, phone_number)
   recite.from_list(leg, list);

end

-------------------------
-- RECITE ORDINAL NUMBER
-------------------------
--
-- EXAMPLE: 3 = "third"

function recite.ordinal(leg, number)

   -- Add zero to convert our number argument to an integer if it isn't
   -- one.

   number = number + 0;

   if (number <= 20) then
      ivr.play(leg, SOUNDS.."Numbers/ordinal/h"..number..".wav");
      return;
   end

   if (number <= 89) then
      local tens = math.floor(number/10);
      local ones = number % 10;

      ivr.play(leg, SOUNDS.."Numbers/cardinal/"..tens.."0.wav");
      ivr.play(leg, SOUNDS.."Numbers/ordinal/h-"..ones..".wav");
      return;
   end

   logError("recite.ordinal: Vocabulary not big enough for \""..number.."\"");
end

--------------------------
-- RECITE A RELATIVE DATE
--------------------------
--
-- EXAMPLE: if the current date is 2014-May-05, the following would happen:
-- arg: 2015-May-05 4:15pm = "Today, four fifteen pm"
-- arg: 2015-May-04 11:00am = "Yesterday, 11 o-clock"

function recite.relative_date(leg, secondsSinceEpoch)
   
   local time_epoch = os.time()
   local yesterday_localtime_parts = os.date("*t", time_epoch - 86400);
   local current_localtime_parts = os.date("*t", time_epoch);
   local object_time_parts = os.date("*t", secondsSinceEpoch);

   if (current_localtime_parts["year"] == object_time_parts["year"] and
       current_localtime_parts["month"] == object_time_parts["month"] and
       current_localtime_parts["day"] == object_time_parts["day"]) then

      ivr.play(leg, SOUNDS.."Calendar/today.wav");

   elseif (yesterday_localtime_parts["year"] == object_time_parts["year"] and
           yesterday_localtime_parts["month"] == object_time_parts["month"] and
	   yesterday_localtime_parts["day"] == object_time_parts["day"]) then

      ivr.play(leg, SOUNDS.."Calendar/yesterday.wav");
      
   else
      ivr.play(leg, SOUNDS.."Calendar/day-"..(object_time_parts["wday"]-1)..".wav");
      ivr.play(leg, SOUNDS.."Calendar/mon-"..(object_time_parts["month"]-1)..".wav");
      recite.ordinal(leg, current_localtime_parts["day"]);
   end

   aLeg:sleep(300);

   -- Now the time...

   local am;
   local hour;

   if (object_time_parts["hour"] >= 0 and object_time_parts["hour"] <= 12) then
      am = true;
      hour = object_time_parts["hour"];
      if (hour == 0) then
	 hour = 12;
      end
   else
      am = false;
      hour = object_time_parts["hour"] - 12;
   end

   recite.number_as_human(leg, hour);
   
   if (object_time_parts["min"] == 0) then
      ivr.play(leg, SOUNDS.."Time/oclock.wav");
   else
      if (object_time_parts["min"] < 10) then
	 ivr.play(leg, SOUNDS.."Time/oh.wav");
      end

      recite.number_as_human(leg, object_time_parts["min"]);
   end

   if (am) then
      ivr.play(leg, SOUNDS.."Time/a-m.wav");
   else
      ivr.play(leg, SOUNDS.."Time/p-m.wav");
   end
end


