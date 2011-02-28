#! /bin/bash

# Script: lamp_timer.sh
# Written by Charles Sullivan, 10 Jul 2006
# Revised as bash-only 17 Oct 2007
# When launched from the Heyu engine by an On signal to a module
# with Housecode|unit address Hu (which may be a Heyu alias), this
# script will start a countdown timer which will send an Off signal
# the argument number of minutes later.
# If re-launched with an On signal before the timer countdown is
# completed, the timer is restarted and the module will remain On
# for the full countdown.
# If launched by an Off signal, the countdown is cancelled.

# This script requires that commands 'at' and 'atrm' are installed
# on your system.

# Usage (all one line in the Heyu configuration file):
#   SCRIPT Hu gon goff anysrc :: path_to/lamp_timer.sh  Hu  minutes
#
# Example (assuming lamp_timer.sh is on your PATH):
#   ALIAS  hall_light A1  LM465
#   SCRIPT hall_light gon goff anysrc :: lamp_timer.sh hall_light 15

HuAddr=$1
JobName=$1
JobFile="/tmp/"$JobName".job"
HeyuTask="heyu off "$HuAddr
CancelTest="isOff"
Countdown=$2" minutes"
EnVar="x10_"$HuAddr

# If the argument Hu is a Housecode|Unit rather
# than an Alias, convert the environment variable
# name to upper case.

if [ "$EnVar" = "" ] ; then
   EnVar=`echo $EnVar | tr '[a-z]' '[A-Z]'`
fi

# If an Off signal is received, the countdown will
# be cancelled.

if [ $(($EnVar & $CancelTest)) -gt 0 ] ; then
   if [ -f $JobFile ]; then
      JobNum=`grep job $JobFile | cut -d" " -f2 -`
      atrm $JobNum
      unlink $JobFile
      echo "Cancel countdown for "$JobName" (AT job "$JobNum")" 
   fi
   exit
fi

# If an On signal is received while a countdown is already
# in progress, restart the countdown over again.  Otherwise
# start the countdown.

if [ -f $JobFile ]; then
  JobNum=`grep job $JobFile | cut -d" " -f2 -`
  atrm $JobNum
  echo "$HeyuTask ; unlink $JobFile" | at now + $Countdown 2> $JobFile
  JobNum=`grep job $JobFile | cut -d" " -f2 -`
  echo "Restart countdown for "$JobName" (AT job "$JobNum")"
else
  echo "$HeyuTask ; unlink $JobFile" | at now + $Countdown 2> $JobFile
  JobNum=`grep job $JobFile | cut -d" " -f2 -`
  echo "Start countdown for "$JobName" (AT job "$JobNum")"
fi


