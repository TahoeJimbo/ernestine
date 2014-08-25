
----- MAIN MENU ---------------------------------------------------------------

--
-- get_mailbox(session)
--
-- Asks the caller to enter a mailbox number
--
-- returns the mailbox number, or "failed"
--
function get_mailbox(fs_session)

   local digits, status;

   for x=1, MAX_AUTH_ATTEMPTS do
      digits, status = ivr.prompt_multi_digit(fs_session,
					      VM.."enter-mailbox.wav", "#");
      if (status == "valid") then
	 if (config[digits]) then
	    -- We have a box!
	    return digits;
	 else
	    ivr.play(fs_session, VM.."extension.wav")
	    recite.phone_number(fs_session, digits);
	    fs_session:sleep(500);
	 end
      end
   end

   return "failed"
end

--
-- get_password(session, mailbox)
--
-- Asks the caller to enter a password
--
-- returns "valid" or "invalid"
--

function get_password(fs_session, mailbox_number)

   local prompt = SOUNDS.."Call_Center/agent-pass.wav";
   local digits, status;

   for x=1, MAX_AUTH_ATTEMPTS do
      digits, status = ivr.prompt_multi_digit(fs_session, prompt, "#");

      if (status == "valid") then
	 local box_config = g_vm_config.config[mailbox_number];
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

function authenticate(fs_session, mailbox_number)

   local mailbox_obj
   local mailbox_config
   local status

   mailbox_config = g_vm_config.config[mailbox_number]

   -- Get the mailbox first, if we don't have it already...   

   if (mailbox_number == nil) then
      mailbox_number = get_mailbox(fs_session);
      
      if (mailbox_number == "failed") then
	 ivr.play(fs_session, ANNOUNCEMENTS.."sorry-youre-having-problems.wav");
	 ivr.play(fs_session, ANNOUNCEMENTS.."hangup-try-again.wav");
	 return nil;
      end
   end

   -- Get the password.

   if mailbox_config.auto_password and mailbox_config.auto_password == true then
      local source_digits = fs_session:getVariable("sip_from_user_stripped")
      
      local allowed_extensions
      
      if mailbox_config.notify_list and mailbox_config.notify_list ~= "" then
	 allowed_extensions = ":"..mailbox_config.notify_list..":"

	 if allowed_extensions:match(":"..source_digits..":") then
	    return Mailbox:open_box(mailbox_number)
	 end
      else
	 if mailbox_number == source_digits then
	    return Mailbox:open_box(mailbox_number)
	 end
      end
   end

   status = get_password(fs_session, mailbox_number);

   if (status == "invalid") then
      ivr.play(fs_session, ANNOUNCEMENTS.."sorry-youre-having-problems.wav");
      ivr.play(fs_session, ANNOUNCEMENTS.."hangup-try-again.wav");
      return nil;
   end

   mailbox_obj = Mailbox:open_box(mailbox_number);

   return mailbox_obj;
end


function main_menu(fs_session, mailbox_obj)

   local digits = "";
   local errors = 4;
   local status = ""

   --- Say the number of new and saved messages...

   repeat

      mailbox_obj = Mailbox:open_box(mailbox_obj.box_number);

      digits = mailbox_obj:announce_stats(fs_session)

      repeat
	 if (fs_session:ready()) then

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
	       digits = ivr.prompt_list(fs_session, box_menu, 4000);
	       if (digits == "") then
		  errors = errors - 1;
	       else
		  break;
	       end
	    else
	       fs_session:sleep(1000);
	       return;
	    end
	 else
	    return;
	 end
      until (errors <=0);

      if (errors <= 0) then
	 ivr.play(fs_session, ANNOUNCEMENTS.."sorry-youre-having-problems.wav");
	 ivr.play(fs_session, ANNOUNCEMENTS.."hangup-try-again.wav");
	 return;
      end

      if (digits == "1" and mailbox_obj.N > 0) then
	 mailbox_obj:set_mode("N");
	 status = vm_box_execute_menu(mailbox_obj, fs_session);
      elseif (digits == "2" and mailbox_obj.S > 0) then
	 mailbox_obj:set_mode("S");
	 status = vm_box_execute_menu(mailbox_obj, fs_session);
      else
	 ivr.play(fs_session, SOUNDS.."Conference/conf-errormenu.wav");
	 errors = errors - 1;
      end

   until ((not fs_session:ready()) or (errors >= 5) or (status == "error"));

   if (errors <= 0) then
      ivr.play(fs_session, ANNOUNCEMENTS.."sorry-youre-having-problems.wav");
      ivr.play(fs_session, ANNOUNCEMENTS.."hangup-try-again.wav");
   end
end
