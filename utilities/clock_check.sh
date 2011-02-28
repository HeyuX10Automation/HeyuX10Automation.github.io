
#! /bin/sh

# clock_check.sh  by Charles W. Sullivan
#
# When launched by the Heyu State Engine, this script will
# send email via the local mail system when an X10 signal sent by an
# uploaded timer arrives too far from the expected time.
# Use it to verify that the CM11A clock hasn't drifted excessively.
#
# Usage:  path-to/clock_check.sh  TIME  MAX_ERROR  [RECIPIENTS]
#
# where:  TIME is the expected execution time in hh:mm
#         MAX_ERROR is the +/- max difference in seconds
#           between TIME and actual system time.
#         RECIPIENTS is a list of user IDs to receive email notification.
#           (If omitted, email is sent to the owner of the Heyu Engine
#            process.)
#
# Usage example:
# In the uploaded Heyu schedule file, include the lines:
#    timer smtwtfs 01/01-12/31 11:00 0:00 time_check null
#    macro time_check 0 on N6
#
# In the Heyu configuration file, include the line:
#    script N6 on rcvi sndm :: path-to/clock_check.sh 11:00 30
#
# (Run 'heyu engine' after making any changes to the
# configuration file.)
#
# Notes: 
# 1. Barring a power failure, the CM11A maintains its clock
# from the AC power line frequency and is likely to be more
# accurate than many PC internal clocks.  
# 2. If there is a power failure, the CM11A will request a
# clock update and Heyu will silently comply, so the CM11A
# clock may _appear_ to have been correctly set all along.
# 3. This script requires the X10_SysTime environment variable
# supplied when a script is launched by Heyu.


# Verify number of parameters
[ $# -lt 2 ] && \
  echo "Usage: "$0" time(hh:mm) max_error(seconds) [recipients]" && exit

# Verify Heyu X10_SysTime environment variable
[ "$X10_SysTime" = "" ] && \
  echo "X10_SysTime environment variable not found" && exit

#Expected signal time in seconds from argument hh:mm
HOURS=`echo $1 | cut -d: -f1 -`
MINUTES=`echo $1 | cut -d: -f2 -`

#Maximum clock error in seconds
MAX_ERROR=$2

#Email recipients
shift 2; MAILTO=$@

[ "$MAILTO" = "" ] && MAILTO=`whoami`

EXPECTED_TIME=$(($HOURS*3600 + $MINUTES*60))

# Allowable error in seconds between the system clock
# and the time the X10 signal is expected.

MIN_TIME=$(($EXPECTED_TIME - $MAX_ERROR))
MAX_TIME=$(($EXPECTED_TIME + $MAX_ERROR))

ERROR=$(($X10_SysTime - $EXPECTED_TIME))

SUBJ="Heyu attention!"
MSG="CM11A clock may need to be reset! Error = "$ERROR" seconds"

( [ $X10_SysTime -lt $MIN_TIME ] || [ $X10_SysTime -gt $MAX_TIME ] ) && \
   echo $MSG && \
   echo "$MSG" | mail -s "$SUBJ" $MAILTO

