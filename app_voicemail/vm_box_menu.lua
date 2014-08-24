
function vm_make_box_menu(mailbox_obj)

   local current_index = mailbox_obj.current_index;
   local mailbox_mode = mailbox_obj.Mode;

   local last = false;

   if (mailbox_obj[mailbox_mode] == current_index) then
      last = true;
   end

   local menu_list = {}
   local menu_index = 0;

   menu_index = menu_index + 1;
   menu_list[menu_index] = VM.."press-3-to-hear-envelope.wav";

   if (current_index > 1) then
      menu_index = menu_index + 1;
      menu_list[menu_index] = VM.."press-4-to-hear-prev-message.aiff";
   end

   menu_index = menu_index + 1;
   menu_list[menu_index] = VM.."press-5-to-hear-repeat-message.aiff";


   if (not last) then
      menu_index = menu_index + 1;
      menu_list[menu_index] = VM.."press-6-to-hear-next-message.aiff";
   end

   if (mailbox_obj.D[current_index]) then
      local disp_index = mailbox_obj.D;

      disposition = disp_index[current_index];
   else 
      disposition = "";
   end

   if (disposition == "deleted") then
      -- Already deleted... Should undelete instead...
      menu_index = menu_index + 1;
      menu_list[menu_index] = VM.."press-7-to-undelete-msg.wav";
      
   elseif (disposition == "saved") then
      menu_index = menu_index + 1;
      menu_list[menu_index] = VM.."press-7-delete-message.wav";
   else 
      menu_index = menu_index + 1;
      menu_list[menu_index] = VM.."press-7-delete-message.wav";
      menu_index = menu_index + 1;
      menu_list[menu_index] = VM.."press-OR-9-to-save-this-message.wav";
   end

   menu_index = menu_index + 1;
   menu_list[menu_index] = VM.."press-star-for-main-menu.wav";

   return menu_list;
end

function vm_box_execute_menu(mailbox_obj, fs_session)

   local exitRequested = false;
   local errorCount = 4;

   local played;
   local digits;

   mailbox_obj.D = {};
   mailbox_obj.current_index = 0;
   
   played, digits = mailbox_obj:next_message(fs_session);

   repeat 
      local disposition;
      local current_index = mailbox_obj.current_index;

      if (mailbox_obj.D[current_index]) then
	 disposition = mailbox_obj.D[current_index];
      else
	 disposition = ""
      end

      -- No response while message was being played?  Then
      -- play the menu...

      if (digits == "") then
	 local menu_list =  vm_make_box_menu(mailbox_obj);
	 digits = ivr.prompt_list(fs_session, menu_list, 2000);
      end

      -- Still no response?

      if (digits == "") then
	 errorCount = errorCount - 1;

      elseif (digits == "*") then
	 -- Exit has been explicitly requested.
	 exitRequested = true;

      elseif (digits == "3") then
	 digits = ""
	 mailbox_obj:announce_envelope(fs_session);

      -- Playback control(4==prev, 5=current, 6=next)

      elseif (digits == "4") then
	 played, digits = mailbox_obj:previous_message(fs_session);
	 
	 if (not played) then
	    ivr.play(fs_session, SOUNDS.."Conference/conf-errormenu.wav");
	    errorCount = errorCount - 1;
	    digits = ""
	 end

      elseif (digits == "5") then
	 played, digits = mailbox_obj:play_current(fs_session);

      elseif (digits == "6") then
	 played, digits = mailbox_obj:next_message(fs_session);

	 if (not played) then 
	    ivr.play(fs_session, SOUNDS.."Conference/conf-errormenu.wav");
	    errorCount = errorCount - 1;
	    digits = ""
	 end

      -- 7 = delete 9 = save

      elseif (digits == "9") then
	 digits = "";

	 if (disposition == "saved") then
	    ivr.play(fs_session, SOUNDS.."Conference/conf-errormenu.wav");
	    errorCount = errorCount - 1;
	 else
	    ivr.play(fs_session, VM.."saved.wav");
	    disposition = "saved"
	    status, digits = mailbox_obj:next_message(fs_session);
	 end
	 mailbox_obj.D[current_index] = disposition;

      elseif (digits == "7") then
	 digits = "";

	 if (disposition == "deleted") then
	    ivr.play(fs_session, VM.."message-undeleted.wav");
	    disposition = "";
	 else
	    ivr.play(fs_session, VM.."message-deleted.wav");
	    disposition = "deleted";
	    status, digits = mailbox_obj:next_message(fs_session);
	 end
	 mailbox_obj.D[current_index] = disposition;

      else
	 ivr.play(fs_session, SOUNDS.."Conference/conf-errormenu.wav");
	 digits = "";
      end

      if (errorCount <= 0) then
	 break;
      end

   until (exitRequested);

   -- process the changes to the mailbox

   if DEBUG_MAILBOX then logInfo("Cleaning up mailbox..."); end

   mailbox_obj:cleanup();

   if DEBUG_MAILBOX then logInfo("Returning to main menu..."); end

   return "";
end
