
--
-- Where everything lives..
--

FREESWITCH="/usr/local/freeswitch/"

SOUNDS=  FREESWITCH.."sounds/en/us/kevin/"
SCRIPTS= FREESWITCH.."scripts/"

ANNOUNCEMENTS= SOUNDS.."Announcement/"
VM=            SOUNDS.."VM/"
NUMBERS=       SOUNDS.."Numbers/"
CARPECHAOS=    SOUNDS.."CarpeChaos/"

VM_DIR=             FREESWITCH.."var/Voicemail/"
VM_CONFIG=          VM_DIR.."VM.config"
VM_CONFIG_BACKUP =  VM_CONFIG..".bak."
VM_MAILBOX_PREFIX = VM_DIR.."box-"

LOC_CONFIG =        VM_DIR.."LOC.config"

--
-- SYSTEM WIDE PARAMETERS
--

INTERNAL_IP = "10.11.0.3"
EXTERNAL_IP = "104.52.146.106"

MAX_AUTH_ATTEMPTS = 3
