This project includes a set of scripts designed to capture network traffic, process it using Zeek, and then convert the Zeek logs into a MySQL database for analysis and review.
Project Structure

    zeek_to_mysql.sh: Shell script to manage the full lifecycle of traffic capturing, log processing, and database insertion.
    zeek_to_mysql.py: Python script to convert processed Zeek logs into MySQL.
    .env: Environment file to store configuration variables.

Requirements
Software Dependencies

    Zeek: Network analysis framework that identifies and logs network connections.
    MySQL/MariaDB: Database server to store and manage the log data.
    tcpdump: Tool for traffic capturing.
    Python 3: Required for running the Python script.
    mysql-connector-python: Python library to connect and interact with MySQL.
