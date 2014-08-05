
----- MAIN MENU ---------------------------------------------------------------

--
-- get_mailbox(session)
--
-- returns the mailbox number, or "failed"
--
function get_mailbox(aLeg)

   local digits, status;

   for x=1, MAX_AUTH_ATTEMPTS do
      digits, status = ivr.prompt_multi_digit(aLeg,
				      VM.."enter-mailbox.wav", "#");
      if (status == "valid") then
	 if (config[digits]) then
	    -- We have a box!
	    return digits;
	 else
	    ivr.play(aLeg, VM.."extension.wav")
	    recite.phone_number(aLeg, digits);
	    aLeg:sleep(500);
	 end
      end
   end

   return "failed"
end

--
-- get_password(session, mailbox)
--
-- returns "valid" or "invalid"
--

function get_password(aLeg, mailbox_number)

   local prompt = SOUNDS.."Call_Center/agent-pass.wav";
   local digits, status;

   for x=1, MAX_AUTH_ATTEMPTS do
      digits, status = ivr.prompt_multi_digit(aLeg, prompt, "#");

      if (status == "valid") then
	 local box_config = config[mailbox_number];
	 if (box_config.password == digits) then
	    return "valid";
	 else 
	    prompt = VM.."auth-incorrect.wav";
	 end
      else
	 prompt = SOUNDS.."Call_Center/agent-pass.wav";
      end
   end

   return "invalid";
end


-- returns mailbox_obj if successful, or nil otherwise.

function authenticate(aLeg, mailbox_number)

   local mailbox_obj;
   local status;

   -- Get the mailbox first, if we don't have it already...   

   if (mailbox_number == nil) then
      mailbox_number = get_mailbox(aLeg);
      
      if (mailbox_number == "failed") then
	 ivr.play(aLeg, ANNOUNCEMENTS.."sorry-youre-having-problems.wav");
	 ivr.play(aLeg, ANNOUNCEMENTS.."hangup-try-again.wav");
	 return nil;
      end
   end

   -- Get the password.

   status = get_password(aLeg, mailbox_number);

   if (status == "invalid") then
      ivr.play(aLeg, ANNOUNCEMENTS.."sorry-youre-having-problems.wav");
      ivr.play(aLeg, ANNOUNCEMENTS.."hangup-try-again.wav");
      return nil;
   end

   mailbox_obj = mailbox.open(mailbox_number);

   return mailbox_obj;
end


function main_menu(aLeg, mailbox_obj)

   local digits = "";
   local errors = 4;
   local status = ""

   --- Say the number of new and saved messages...

   repeat

      mailbox_obj = mailbox.reopen(mailbox_obj);

      digits = mailbox.announce_stats(mailbox_obj, aLeg)

      repeat
	 if (aLeg:ready()) then

	 -- Start menu

	    local box_menu = {}
	    local box_index = 0;

	    if (mailbox_obj.N > 0) then
	       box_index = box_index + 1;
	       box_menu[box_index] = VM.."press-1-to-hear-new-msgs.wav";
	    end

	    if (mailbox_obj.S > 0) then
	       box_index = box_index + 1;
	       box_menu[box_index] = VM.."press-2-to-hear-svd-msgs.wav";
	    end

	    if (box_index ~= 0) then
	       digits = ivr.prompt_list(aLeg, box_menu, 4000);
	       if (digits == "") then
		  errors = errors - 1;
	       else
		  break;
	       end
	    else
	       aLeg:sleep(1000);
	       return;
	    end
	 else
	    return;
	 end
      until (errors <=0);

      if (errors <= 0) then
	 ivr.play(aLeg, ANNOUNCEMENTS.."sorry-youre-having-problems.wav");
	 ivr.play(aLeg, ANNOUNCEMENTS.."hangup-try-again.wav");
	 return;
      end

      if (digits == "1" and mailbox_obj.N > 0) then
	 mailbox.set_mode(mailbox_obj, "N");
	 status = mailbox_play_menu(mailbox_obj, aLeg);
      elseif (digits == "2" and mailbox_obj.S > 0) then
	 mailbox.set_mode(mailbox_obj, "S");
	 status = mailbox_play_menu(mailbox_obj, aLeg);
      else
	 ivr.play(aLeg, SOUNDS.."Conference/conf-errormenu.wav");
	 errors = errors - 1;
      end

   until ((not aLeg:ready()) or (errors >= 5) or (status == "error"));

   if (errors <= 0) then
      ivr.play(aLeg, ANNOUNCEMENTS.."sorry-youre-having-problems.wav");
      ivr.play(aLeg, ANNOUNCEMENTS.."hangup-try-again.wav");
   end
end
