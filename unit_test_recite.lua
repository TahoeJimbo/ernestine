
function recite_unittest()
   
   local saved_debug = DEBUG or nil

   playlist = {}

   playlist = recite.PRIV_make_phone_number_playlist(playlist, "9168011399")
   table_dump("9168011399", playlist)

   playlist = {}
   playlist = recite.PRIV_make_phone_number_playlist(playlist, "18314197859")
   table_dump("18314197859", playlist)

   playlist = {}
   playlist = recite.PRIV_make_phone_number_playlist(playlist, "19168011399")
   table_dump("19168011399", playlist)

   local playlist = {}
   playlist = recite.PRIV_make_phone_number_playlist(playlist, "4197859")
   table_dump("4197859", playlist)

   playlist = {}
   playlist = recite.PRIV_make_phone_number_playlist(playlist, "8011399")
   table_dump("8011399", playlist)

   playlist = {}
   playlsit = recite.PRIV_make_smart_digit_playlist(playlist, "9")
   table_dump("smart9", playlist)

   playlist = {}
   playlist = recite.PRIV_make_human_number_playlist(playlist, "9")
   table_dump("9", playlist)

   playlist = {}
   playlist = recite.PRIV_make_human_number_playlist(playlist, "43")
   table_dump("43", playlist)

   playlist = {}
   playlist = recite.PRIV_make_human_number_playlist(playlist, "123")
   table_dump("123", playlist)

   playlist = {}
   playlist = recite.PRIV_make_human_number_playlist(playlist, "8019")
   table_dump("8019", playlist)
   
   DEBUG = saved_debug
end
