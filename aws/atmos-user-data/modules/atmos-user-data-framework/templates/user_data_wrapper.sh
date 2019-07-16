#!/usr/bin/env bash

# fail fast
set -e

wrapper_log=/var/log/user-data.log

exec > >(tee $wrapper_log|logger -t user-data -s 2>/dev/console) 2>&1

echo "Starting Atmos User-Data"

function report_exit {
    result=$?
    if [[ $result != 0 ]]; then
        echo -e "Atmos User-Data FAILURE, env:\n$(env)" >&2
    else
        echo "Atmos User-Data Completed"
    fi
}

trap "report_exit" EXIT

# Source environment variables passed in from terraform
echo "Sourcing Atmos User-Data environment"
[[ -f /etc/profile.d/atmos_env.sh ]] && source /etc/profile.d/atmos_env.sh

# Turn on debugging if set
if ((DEBUG_USER_DATA)); then set -x; fi

# Loop through all scripts in $USER_DATA_DIR and execute them
if [[ -d "$USER_DATA_DIR" ]]; then
    # Create log directory if needed
    [[ -d "$USER_DATA_LOG_DIR" ]] || mkdir $USER_DATA_LOG_DIR

    for file in $(ls -v $USER_DATA_DIR/); do

        file="$USER_DATA_DIR/$file"
        if [[ -f "$file" && -x "$file" ]]; then

          maybe_debug=""
          if ((DEBUG_USER_DATA)); then
            if file "$file" | grep -qi "Bourne-Again shell script"; then
              maybe_debug="bash -x"
            fi
          fi

          name=$(basename $file | sed 's/^[0-9]*-//')
          echo "Starting execution of user-data script: $file"
          if ! $maybe_debug "$file" > "$USER_DATA_LOG_DIR/$name.log" 2>&1; then
            echo "Atmos User-Data FAILURE while executing $file:"
            cat "$USER_DATA_LOG_DIR/$name.log"
            exit 1
          fi

          echo "Completed execution of user-data script: $file"

        fi
    done
fi

exit 0
