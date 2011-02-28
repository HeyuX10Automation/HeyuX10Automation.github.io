#! /bin/sh

# UR81A_Action.sh  version 1.0  2007-10-21
# Written by Charles W. Sullivan
# Email ID: cwsulliv01  Email Domain: heyu.org

# This is a user-modifiable script which translates RF codes
# received by the Heyu auxiliary daemon from an X-10 UR81A
# "Entertainment Anywhere" RF remote in PC mode. Although
# the button names may be different, this script ought to
# work with any X-10 RF remote which is sold bundled with
# an X-10 MR26A RF Receiver, e.g., the UR61A "MP3 Anywhere"
# remote.  Note: the X-10 "Lola" and "Pan 'n Tilt" remotes
# transmit RF codes which are not received by the MR26A
# or the other RF receivers currently supported by Heyu.
#
# As distributed, it merely displays a message in the Heyu
# log file with the name of the UR81A remote button which
# generated the RF signal.  For actual functionality, the
# command to be executed for each button must be added to
# the stanza for that button in the 'case' statement below.
#
# As an example, commands to control playback of audio files
# with the 'xmms' Audio Player (with 'amixer' for volume 
# control via the ALSA soundcard driver) have been added
# (but commented out) for the Play, Pause, Stop, Chan+,
# Chan-, Vol+, Vol-, and M (Mute) buttons.  (Heyu flag 15
# is used to implement a toggle for the Mute button.)
#
# Usage: Copy this script (with a new name) to a directory
# on your system and make it executable.  Modify as required.
# In your Heyu configuration file (~/.heyu/x10config or
# /etc/heyu/x10.conf), add an ALIAS directive to map the
# Heyu UR81A module type to an unused housecode|unit
# address (Hu) plus a SCRIPT directive to execute your
# modified copy of the script:
#    ALIAS my_remote Hu UR81A
#    SCRIPT Hu vdata rcva :: /path_to/my_ur81a_action.sh

# Reference: UR81A button code list (hex).  Kindly
# notify the author if button codes not in this list
# are found to be transmitted by your remote.
# 02 12 22 38 3A 40 42 52 60 62 70 72 82 92 A0 A2
# B0 B6 B8 BA C0 C2 C9 D1 D2 D3 D4 D5 D6 D8 D9 E0
# E2 F0 F2 FF

VDATA=`printf "0x%X" $X10_Vdata`

case $VDATA in
   0xB0)
       # Play
       echo "       Play button" 
#       xmms -p
       ;;
   0x72)
       # Pause
       echo "       Pause button" 
#       xmms -u
       ;;
   0x70)
       # Stop
       echo "       Stop button" 
#       xmms -s
       ;;
   0x40)
       # Chan+ (Skip>|)
       echo "       ChanUp button" 
#       xmms -f
       ;;
   0xC0)
       # Chan- (|<Skip)
       echo "       ChanDown button" 
#       xmms -r
       ;;
   0x60)
       # Vol+
       echo "       VolUp button" 
#       amixer sset Master 10%+ >/dev/null
       ;;
   0xE0)
       # Vol-
       echo "       VolDown button" 
#       amixer sset Master 10%- >/dev/null
       ;;
   0xA0)
       # M[ute]
       echo "       Mute button" 
#       if [ $(($X10_Flag15)) -eq 0 ] ; then
#          amixer sset Master mute >/dev/null
#          heyu setflag 15
#       else
#          amixer sset Master unmute >/dev/null
#          heyu clrflag 15
#       fi
       ;;
   0x52)
       # Enter and OK
       echo "       Enter button" 
       ;;
   0x2)
       # Zero
       echo "       Zero button" 
       ;;
   0x82)
       # One
       echo "       One button" 
       ;;
   0x42)
       # Two
       echo "       Two button" 
       ;;
   0xC2)
       # Three
       echo "       Three button" 
       ;;
   0x22)
       # Four
       echo "       Four button" 
       ;;
   0xA2)
       # Five
       echo "       Five button" 
       ;;
   0x62)
       # Six
       echo "       Six button" 
       ;;
   0xE2)
       # Seven
       echo "       Seven button" 
       ;;
   0x12)
       # Eight
       echo "       Eight button" 
       ;;
   0x92)
       # Nine
       echo "       Nine button" 
       ;;
   0xD5)
       # ArrowUp
       echo "       ArrowUp button" 
       ;;
   0xD3)
       # ArrowDown
       echo "       ArrowDown button" 
       ;;
   0xD1)
       # ArrowRight
       echo "       ArrowRight button" 
       ;;
   0xD2)
       # ArrowLeft
       echo "       ArrowLeft button" 
       ;;
   0x3A)
       # A (Display)
       echo "       A button" 
       ;;
   0xD8)
       # B (Return)
       echo "       B button" 
       ;;
   0xD6)
       # C
       echo "       C button" 
       ;;
   0xD9)
       # D
       echo "       D button" 
       ;;
   0xB6)
       # Menu
       echo "       Menu button" 
       ;;
   0xBA)
       # A-B
       echo "       A-B button" 
       ;;
   0xF2)
       # Last (Recall)
       echo "       Last button" 
       ;;
   0xB8)
       # F.F.
       echo "       FastFwd button" 
       ;;
   0x38)
       # Rewind
       echo "       Rewind button" 
       ;;
   0xFF)
       # Record
       echo "       Record button" 
       ;;
   0xF0)
       # Power
       echo "       Power button" 
       ;;
   0xC9)
       # Exit
       echo "       Exit button" 
       ;;
   0xD4)
       # PC (Subtitle)
       echo "       PC button" 
       ;;
      *)
       # Unknown
       echo "       Unknown button code "$VDATA
esac
