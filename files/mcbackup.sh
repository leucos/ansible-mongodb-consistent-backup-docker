#!/bin/bash

set -eu

## Logging functions

function prepare_date() {
  date "$@"
}

function log() {
  if [ -n "${LOG_FILE}" ]; then
     echo "$(prepare_date +%F_%H:%M:%S): ${*}" >> "${LOG_FILE}"
  else
     echo "$(prepare_date +%F_%H:%M:%S): ${*}"
  fi
}

function loginfo() {
  log "INFO: ${*}"
}

# Only used if -v --verbose is passed in
function logverbose() {
  if ${VERBOSE}; then
    log "DEBUG: ${*}"
  fi
}

# Pass errors to stderr.
function logerror() {
  log "ERROR: ${*}" >&2
  let ERROR_COUNT++
}

### Arguments validation

function validate() {
  if [ -z "${DOCKER}" ]; then
    logerror "Cannot find docker. Please make sure it is in the PATH"
    exit 1
  fi

  if [ -z "${REMOTE_SERVER}" ]; then
    logerror "Remote shard router server (-s) is not set"
    exit 1
  fi

  if [ -z "${REMOTE_PORT}" ]; then
    logerror "Remote shard router server (-s) is not set"
    exit 1
  fi

  if [ -z "${LOCAL_DESTINATION}" ]; then
    logerror "Local destination (-d) is not set"
    exit 1
  fi

  if [ ! -w "${LOCAL_DESTINATION}" ]; then
    logerror "Destination $LOCAL_DESTINATION does exist or is not writable"
    exit 1    
  fi

  re='^[0-9]+$'
  if ! [[ $KEEP =~ $re ]] ; then
    logerror "Provided keep count ($KEEP) is not a number"
  fi
}

## Backup
function backup() {
  loginfo "Creating backup in ${LOCAL_DESTINATION}/${REMOTE_SERVER}"

  DOCKER_OPTS="-ti --rm -v ${LOCAL_DESTINATION}:/opt ${DOCKER_MCB_IMAGE} -H ${REMOTE_SERVER} -P ${REMOTE_PORT} -n ${REMOTE_SERVER} -l /opt/"
  logverbose "Executing ${DOCKER} run ${DOCKER_OPTS}"

  ${DRY_RUN} || ${DOCKER} run ${DOCKER_OPTS} >> "${LOG_FILE}" 2>&1

  loginfo "Docker run exited with $?"

  sync
}

# Purge old backups
function purge() {
  if [ "$KEEP" -eq 0 ]; then
    loginfo "No backups will be purged (-k 0)"
    return
  fi

  shopt -s nullglob
  LOCATION="${LOCAL_DESTINATION}/${REMOTE_SERVER}"

  file_arr=(${LOCATION})
  CURRENT="${#file_arr[@]}"

  # Remove "current" symlink and requested keep so we end up with count of directories to remove
  COUNT=$((CURRENT - KEEP))

  if [ $COUNT -gt 0 ]; then
    loginfo "Erasing $COUNT old backups, keeping ${KEEP}"
    # shellcheck disable=SC2012
    for i in $(ls "${LOCATION}" | head -$COUNT); do
      loginfo "Erasing ${i}"
      ${DRY_RUN} || rm -rf "${LOCATION:?}/${i:?}"
    done
  else
    loginfo "No backup to purge (${CURRENT} present, ${KEEP} to keep)"
  fi
}

# Parse arguments

function parse() {
  DRY_RUN=false
  ERROR_COUNT=0
  KEEP=0                  # keep everything by default
  LOCAL_DESTINATION=""
  LOG_FILE="/dev/null"
  REMOTE_SERVER=""
  DOCKER=$(which docker 2> /dev/null) # find docker
  VERBOSE=false           # prints detailed information
  DOCKER_MCB_IMAGE=timvaillancourt/mongodb_consistent_backup

  for arg in "$@"
  do
    shift
    case "$arg" in
      "--port")        set -- "$@" "-p" ;;
      "--source")      set -- "$@" "-s" ;;
      "--destination") set -- "$@" "-d" ;;
      "--verbose")     set -- "$@" "-v" ;;
      "--log")         set -- "$@" "-l" ;;
      "--dry-run")     set -- "$@" "-n" ;;
      "--keep")        set -- "$@" "-k" ;;
      *)               set -- "$@" "$arg"

    esac
  done

  while getopts 'p:s:d:hvl:nh:k:' OPTION
  do
    case $OPTION in
      k) 
        KEEP="${OPTARG}"
        ;;
      s)
        REMOTE_SERVER="${OPTARG}"
        ;;
      p)
        REMOTE_PORT="${OPTARG}"
        ;;
      l)
        LOG_FILE="${OPTARG}"
        ;;      
      d)
        LOCAL_DESTINATION="${OPTARG}"
        ;;
      n)
        DRY_RUN=true
        ;;
      v)
        VERBOSE=true
        ;;
      h)  
        help
        exit 0
        ;;
    esac
  done
}

parse "$@"
validate
backup
purge

loginfo "Backup completed with ${ERROR_COUNT} errors"
