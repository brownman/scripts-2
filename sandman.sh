#!/bin/bash

function usage {
cat << EOF
usage: $0 options

Make processes sleepy.

OPTIONS:
   -h      Help
   -p      Process ID
   -r      Ratio of sleep:awake (0-1, 1 being a coma)
   -s      Seconds of a sleep cycle
   -v      Verbose

Make process 5678 sleep for 5 seconds out of every 10:
$0 -p 5678 -r 0.5 -s 10 -v
EOF
}

# If verbose is enabled echo the given message
function v {
  if [ $verbose -ne 0 ]
  then
    echo $*
  fi
}

# Make sure the process stays awake after quitting
function ctrlc {
  v Waking $pid before quitting
  kill -sigcont $pid
  exit
}

pid=
ratio=0.5
span=5
verbose=0

while getopts "hp:r:s:v" OPTION
do
  case $OPTION in
    h)
      usage
      exit
      ;;
    p)
      pid=$OPTARG
      ;;
    r)
      ratio=$OPTARG
      ;;
    s)
      span=$OPTARG
      ;;
    v)
      verbose=1
      ;;
  esac
done

if [ -z $pid ]
then
  echo "A process ID is required"
  usage
  exit 1
fi

sleep_span=$(awk "BEGIN { print $span * $ratio }")
wake_span=$(awk "BEGIN { print $span - $sleep_span }")

# handle control-c and make sure the script ends with the process awake
trap ctrlc SIGINT

# Sleep/Wake cycle
while true
do
  v Sleeping \#$pid for $sleep_span seconds
  kill -sigstop $pid
  sleep $sleep_span

  v WAKE UP \#$pid for $wake_span seconds
  kill -sigcont $pid
  sleep $wake_span
done