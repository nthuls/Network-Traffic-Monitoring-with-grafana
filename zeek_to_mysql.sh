#!/bin/bash

export BASE_DIRECTORY=$(dirname "$(readlink -f "$0")")
DEFAULT_INTERFACE="enp3s0"
DEFAULT_BASE_DIR=$(dirname "$(readlink -f "$0")")
DEFAULT_CAPTURE_DURATION=600
ENV_FILE="$DEFAULT_BASE_DIR/.env"
LOG_FILE="$DEFAULT_BASE_DIR/zeek_capture.log"
PID_FILE="$DEFAULT_BASE_DIR/zeek_capture.pid"
ZEEK_LOG_PATH="BASE_DIRECTORY/zeek_output"

check_program() {
    if ! command -v $1 &> /dev/null; then
        echo "$1 could not be found, please install $1"
        exit 1
    fi
}

check_permissions() {
    touch "$1/test.tmp" 2>/dev/null
    if [ $? -ne 0 ]; then
        echo "Permission denied for writing in $1"
        exit 1
    fi
    rm "$1/test.tmp"
}

ensure_directory() {
    if [ ! -d "$1" ]; then
        mkdir -p "$1"
        echo "Created directory: $1"
    fi
}

show_sql_instructions() {
    echo "Please run the following SQL commands in your MariaDB shell to create the database and user:"
    echo "------------------------------------------------------------"
    echo "DROP DATABASE IF EXISTS zeek_logs;"
    echo "DROP USER IF EXISTS 'zeek_user'@'localhost';"
    echo "DROP USER IF EXISTS 'zeek_user'@'%';"
    echo "FLUSH PRIVILEGES;"
    echo "CREATE DATABASE zeek_logs CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    echo "CREATE USER 'zeek_user'@'localhost' IDENTIFIED BY 'new_password';"
    echo "CREATE USER 'zeek_user'@'%' IDENTIFIED BY 'new_password';"
    echo "GRANT ALL PRIVILEGES ON zeek_logs.* TO 'zeek_user'@'localhost';"
    echo "GRANT ALL PRIVILEGES ON zeek_logs.* TO 'zeek_user'@'%';"
    echo "FLUSH PRIVILEGES;"
    echo "------------------------------------------------------------"
    echo "Once you've run these commands, rerun the script."
}

log() {
    LOG_MAX_SIZE=104857600  # 100MB

    if [ -f "$LOG_FILE" ] && [ "$(stat -c%s "$LOG_FILE")" -ge "$LOG_MAX_SIZE" ]; then
        mv "$LOG_FILE" "${LOG_FILE}.old"
        log "Log file rotated"
    fi

    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Function to create or update the .env file
create_or_update_env() {
    read -p "Enter the base directory for storing files [$BASE_DIRECTORY]: " input_base_directory
    if [ -n "$input_base_directory" ]; then
        BASE_DIRECTORY="$input_base_directory"
        export BASE_DIRECTORY
    fi

    read -p "Enter the network interface to capture traffic from [$DEFAULT_INTERFACE]: " INTERFACE
    INTERFACE="${INTERFACE:-$DEFAULT_INTERFACE}"

    read -p "Enter the base directory for storing files [$DEFAULT_BASE_DIR]: " BASE_DIRECTORY
    BASE_DIRECTORY="${BASE_DIRECTORY:-$DEFAULT_BASE_DIR}"

    read -p "Enter the duration for each capture in seconds [$DEFAULT_CAPTURE_DURATION]: " CAPTURE_DURATION
    CAPTURE_DURATION="${CAPTURE_DURATION:-$DEFAULT_CAPTURE_DURATION}"

    read -p "Should the service automatically restart after the capture duration? (yes/no) [no]: " AUTO_RESTART
    AUTO_RESTART="${AUTO_RESTART:-no}"

    read -p "Enter the database name: " DB_NAME
    DB_NAME=${DB_NAME}

    read -p "Enter the database user: " DB_USER
    DB_USER=${DB_USER}

    read -p "Enter the Host: " DB_HOST
    DB_HOST=${DB_HOST}

    read -s -p "Enter the database password: " DB_PASSWORD
    echo ""
    DB_PASSWORD=${DB_PASSWORD}

    ensure_directory "$BASE_DIRECTORY"

    ENV_FILE="$BASE_DIRECTORY/.env"

    echo "INTERFACE=$INTERFACE" > "$ENV_FILE"
    echo "BASE_DIRECTORY=$BASE_DIRECTORY" >> "$ENV_FILE"
    echo "CAPTURE_DURATION=$CAPTURE_DURATION" >> "$ENV_FILE"
    echo "AUTO_RESTART=$AUTO_RESTART" >> "$ENV_FILE"
    echo "DB_NAME=$DB_NAME" >> "$ENV_FILE"
    echo "DB_USER=$DB_USER" >> "$ENV_FILE"
    echo "DB_PASSWORD=$DB_PASSWORD" >> "$ENV_FILE"
    echo "DB_HOST=$DB_HOST" >> "$ENV_FILE"

    log "Configuration saved to $ENV_FILE"
    echo "Configuration updated successfully and saved to $ENV_FILE"
}

load_env_config() {
    if [ -f "$ENV_FILE" ]; then
        while IFS='=' read -r key value; do
            if [[ "$key" =~ ^[[:space:]]*# || "$key" == "" ]]; then
                continue
            fi
            key=$(echo "$key" | tr -d '[:space:]')
            value=$(echo "$value" | tr -d '[:space:]')
            case "$key" in
                "INTERFACE") INTERFACE="$value" ;;
                "BASE_DIRECTORY") BASE_DIRECTORY="$value" ;;
                "CAPTURE_DURATION") CAPTURE_DURATION="$value" ;;
                "AUTO_RESTART") AUTO_RESTART="$value" ;;
                "DB_NAME") DB_NAME="$value" ;;
                "DB_USER") DB_USER="$value" ;;
                "DB_PASSWORD") DB_PASSWORD="$value" ;;
                "DB_HOST") DB_HOST="$value" ;;
                *) echo "Unknown key: $key" ;;
            esac
        done < "$ENV_FILE"
        echo "Configuration loaded from $ENV_FILE"
    else
        echo "Configuration file not found: $ENV_FILE"
        exit 1
    fi
}

load_env_and_set_vars() {
    ENV_FILE="$BASE_DIRECTORY/.env"

    if [ -f "$ENV_FILE" ]; then
        while IFS='=' read -r key value; do
            if [[ "$key" =~ ^[[:space:]]*# || "$key" == "" || "$key" =~ ^\[.*\]$ ]]; then
                continue
            fi
            key=$(echo "$key" | tr -d '[:space:]')  # Trim spaces
            value=$(echo "$value" | sed 's/^ *//;s/ *$//')  # Trim leading/trailing spaces
            export "$key=$value"  # Export as environment variable
        done < "$ENV_FILE"
        echo "Configuration loaded and exported as environment variables from $ENV_FILE"
    else
        echo "Configuration file not found: $ENV_FILE"
        exit 1
    fi

    if [[ -z "$DB_USER" || -z "$DB_PASSWORD" || -z "$DB_HOST" || -z "$DB_NAME" ]]; then
        echo "Error: Database credentials are not set. Please ensure your configuration file is complete."
        exit 1
    fi
    echo "DB_USER=$DB_USER, DB_PASSWORD=$DB_PASSWORD, DB_HOST=$DB_HOST, DB_NAME=$DB_NAME"
}

check_env_variables() {
    if [[ -z "$DB_USER" || -z "$DB_PASSWORD" || -z "$DB_HOST" || -z "$DB_NAME" ]]; then
        echo "Error: Database credentials are not set as environment variables."
        echo "Please export the following environment variables before running the script:"
        echo "------------------------------------------------------------"
        echo "export DB_USER=your_username"
        echo "export DB_PASSWORD=your_password"
        echo "export DB_HOST=localhost"
        echo "export DB_NAME=zeek_logs"
        echo "export BASE_DIRECTORY=(/working/directory)"
        echo "------------------------------------------------------------"
        exit 1
    fi
}

test_db_connection() {
    echo "Testing MySQL connection with user: $DB_USER"

    mariadb -u"$DB_USER" -p"$DB_PASSWORD" -h"$DB_HOST" -e "USE $DB_NAME;" >/dev/null 2>&1
    if [[ $? -eq 0 ]]; then
        echo "Database connection successful."
    else
        echo "Error: Unable to connect to the database. Please check your database setup."
        show_sql_instructions
        exit 1
    fi
}

capture_traffic() {
    OUTPUT_DIR="$BASE_DIRECTORY/pcap"
    ensure_directory "$OUTPUT_DIR"

    OUTPUT_FILE="${OUTPUT_DIR}/capture_$(date +\%Y\%m\%d\%H\%M\%S).pcap"

    log "Starting packet capture on interface $INTERFACE..."
    sudo tcpdump -i "$INTERFACE" -w "$OUTPUT_FILE" -G "$CAPTURE_DURATION" -W 1

    if [ $? -ne 0 ]; then
        log "Error during tcpdump capture"
        safe_exit
    fi

    log "Packet capture completed: $OUTPUT_FILE"

}

run_zeek() {
    ZEEK_OUTPUT_DIR="$BASE_DIRECTORY/zeek_output"
    ensure_directory "$ZEEK_OUTPUT_DIR"

    log "Running Zeek on captured traffic..."
    sudo zeek -C -r "$OUTPUT_FILE" "$BASE_DIRECTORY/asn_enrichment.zeek"

    if [ $? -ne 0 ]; then
        log "Error during Zeek processing"
        safe_exit
    fi

    log "Zeek processing completed. Logs stored in $ZEEK_OUTPUT_DIR"
    sudo rm -f "$OUTPUT_FILE"
}

convert_logs_to_mysql() {
    log "Converting Zeek logs to MySQL..."
    python3 "$BASE_DIRECTORY/zeek_to_mysql.py"
    log "Conversion completed."
}


safe_exit() {
    log "Exiting the script safely."
    exit 0
}

stop_service() {
    if [ -f "$PID_FILE" ]; then
        log "Stopping Zeek Capture Service..."
        kill -TERM "$(cat $PID_FILE)"
        rm -f "$PID_FILE"
        log "Service stopped."
    else
        log "No running service found."
    fi
    safe_exit
}

cleanup() {
    log "Cleaning up resources..."
    if [ -f "$PID_FILE" ]; then
        rm -f "$PID_FILE"
        log "PID file removed."
    else
        log "No PID file found to remove."
    fi
}

trap cleanup EXIT SIGINT SIGTERM

case "$1" in
    "--setup" | "--update")
        create_or_update_env
        test_db_connection
        ;;
    "--run")
        load_env_and_set_vars
        load_env_config

        if [ -f "$PID_FILE" ]; then
            log "Another instance of this script is already running. Exiting."
            exit 1
        fi

        echo $$ > "$PID_FILE"

        check_program "zeek"
        check_program "tcpdump"
        check_program "mariadb"
        check_permissions "$DEFAULT_BASE_DIR"
        check_env_variables

        keep_running=true
        trap 'keep_running=false' SIGINT SIGTERM

        while $keep_running; do
            capture_traffic
            run_zeek
            convert_logs_to_mysql

            sudo rm -f "$OUTPUT_FILE"
            log "Cleaned up pcap files."

            if [[ "$AUTO_RESTART" != "yes" ]]; then
                break
            fi

            log "Service is configured to restart automatically after 1 seconds."
            sleep 2
        done

        safe_exit
        ;;
    "--stop")
        stop_service
        ;;
    *)
        echo "Usage: $0 --setup | --update | --run | --stop"
        echo "--setup : Initial setup and configuration"
        echo "--update : Update existing configuration"
        echo "--run : Run the full process (capture, Zeek processing, MySQL conversion)"
        echo "--stop : Stop the running service"
        exit 1
        ;;
esac
