#!/bin/bash

LOG_DIR="."
CHECK_INTERVAL="10s"
MONITOR_PATH="/"

echo_fail() {
    echo -en "\e[1;31mFAIL\e[0m: "
}

log_fail() {
    echo_fail
    echo "$1"
}

monitor_disk_usage() {
    local log_file="$LOG_DIR/disk_usage_$(date +%Y_%m_%d_%H_%M_%S).csv"
    echo "timestamp,disk_usage,inode_usage" >> "$log_file"
    while true; do
        current_date=$(date +%Y-%m-%d)
        if [[ "$current_date" != "$last_date" ]]; then
            log_file="$LOG_DIR/disk_usage_$(date +%Y_%m_%d_%H_%M_%S).csv"
            last_date="$current_date"
        fi

        df_info=$(df -h /)
        inode_info=$(df -i /)

        echo "$(date +%Y-%m-%d_%H:%M:%S),$(echo "$df_info" | awk 'NR==2 {print $5}'),$(echo "$inode_info" | awk 'NR==2 {print $5}')" >> "$log_file"

        sleep $CHECK_INTERVAL
    done
}

is_running() {
    echo "$LOG_DIR/monitor.pid"
    if [ -f "$LOG_DIR/monitor.pid" ]; then
        PID=$(cat "$LOG_DIR/monitor.pid")
        if ps -p $PID > /dev/null 2>&1; then
            return 0
        else
            return 1
        fi
    else
        return 1
    fi
}

start() {
    if is_running; then
        echo "Process is already running: PID $(cat $LOG_DIR/monitor.pid)"
    else
        mkdir -p $LOG_DIR
        
        last_date=$(date +%Y-%m-%d)
        monitor_disk_usage &
        PID=$!
        echo $PID > "$LOG_DIR/monitor.pid"
        echo "Process is started: PID $PID"
    fi
}

stop() {
    if is_running; then
        PID=$(cat "$LOG_DIR/monitor.pid")
        kill $PID
        rm "$LOG_DIR/monitor.pid"
        echo "Process $PID is killed"
    else
        echo "Process is not running"
    fi
}

status() {
    if is_running; then
        echo "Process is already running: PID $(cat $LOG_DIR/monitor.pid)"
    else
        echo "Process is not running"
    fi
}

main() {

case "$1" in
    START)
        start
        ;;
    STOP)
        stop
        ;;
    STATUS)
        status
        ;;
    *)
        log_fail "$0 {START|STOP|STATUS}"
        exit 1
        ;;
esac
    
}

main $*