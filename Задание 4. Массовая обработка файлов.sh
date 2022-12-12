#!/bin/bash

#doesn't work on mas os terminal
#subproc=$(nproc)
#subproc=$(grep processor /proc/cpuinfo | wc -l)
subproc=$(getconf NPROCESSORS_ONLN)
#echo "Cores: $subproc:"
dirpath=$PWD
filemask='*'

print_usage() {
  echo "Usage: [--path dirpath] [--mask mask] [--number number] command"
  exit 1
}

POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
  case $1 in
  --path)
    dirpath="$2"
    [ -z "$filemask" ] && echo "Error: provided directory path is empty" && exit 1
    [ ! -d "${dirpath}" ] && echo "Error: dir ${dirpath} doesn't exist" && exit
    shift
    shift
    ;;
  --mask)
    filemask="$2"
    [ -z "$filemask" ] && echo "Error: mask is empty" && exit 1
    shift
    shift
    ;;
  --number)
    subproc="$2"
    re='^[0-9]+$'
    if ! [[ $subproc =~ $re ]]; then
      echo "Error: incorrect --number"
      exit 1
    fi
    if [ $subproc -lt 1 ]; then
      echo "Error: --number must be greater than 0"
    fi
    shift
    shift
    ;;
  -* | --*)
    print_usage
    ;;
  *)
    POSITIONAL_ARGS+=("$1")
    shift
    ;;
  esac
done

set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

if [[ -n $1 ]]; then
  command=$1
#  echo "Command: $command"
else
  print_usage
fi

if [[ "${filemask}" == "*" ]]; then
  files=($(ls -al | grep '^-' |  awk '{print $9}'))
else
  files=($(ls -al | grep '^-' |  awk '{print $9}' | grep $filemask))
fi


for file in "${files[@]}"
do
  tmp_command="$command $file"
  $tmp_command &
  if ((++pid_count > subproc)); then
    wait
    ((pid_count--))
  fi
done

duration=$SECONDS
echo ""
#echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."
