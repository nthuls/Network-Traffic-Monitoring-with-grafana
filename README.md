# Zeek to MySQL Integration

This project includes a set of scripts designed to capture network traffic, process it using Zeek, and then convert the Zeek logs into a MySQL database for analysis and review.

## Project Structure

- `zeek_to_mysql.sh`: Shell script to manage the full lifecycle of traffic capturing, log processing, and database insertion.
- `zeek_to_mysql.py`: Python script to convert processed Zeek logs into MySQL.
- `.env`: Environment file to store configuration variables.

## Requirements

### Software Dependencies

- **Zeek**: Network analysis framework that identifies and logs network connections.
- **MySQL/MariaDB**: Database server to store and manage the log data.
- **tcpdump**: Tool for traffic capturing.
- **Python 3**: Required for running the Python script.
- **mysql-connector-python**: Python library to connect and interact with MySQL.

### Python Libraries

Install the required Python libraries using the following command:

```bash
pip install -r requirements.txt
```

`requirements.txt` should include:

```
mysql-connector-python==8.0.28
python-dotenv==0.20.0
```

## Configuration

Before running the scripts, ensure that the `.env` file is properly configured with the necessary database and network settings. Example:

```plaintext
INTERFACE=enp3s0
BASE_DIRECTORY=/path/to/base/directory
CAPTURE_DURATION=600
AUTO_RESTART=no
DB_NAME=zeek_logs
DB_USER=zeek_user
DB_PASSWORD=password123
DB_HOST=localhost
```

## Usage

To use the scripts, follow the steps below:

1. **Initial Setup**:
   Set up the environment and database:
   ```bash
   ./zeek_to_mysql.sh --setup
   ```
   
2. **Running the Script**:
   Start the capture and processing:
   ```bash
   ./zeek_to_mysql.sh --run
   ```

3. **Stopping the Service**:
   To stop a running service:
   ```bash
   ./zeek_to_mysql.sh --stop
   ```

## Database Setup

Run the following SQL commands in your MariaDB/MySQL shell to set up the necessary database and user:

```sql
DROP DATABASE IF EXISTS zeek_logs;
DROP USER IF EXISTS 'zeek_user'@'localhost';
DROP USER IF EXISTS 'zeek_user'@'%';
FLUSH PRIVILEGES;
CREATE DATABASE zeek_logs CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'zeek_user'@'localhost' IDENTIFIED BY 'new_password';
CREATE USER 'zeek_user'@'%' IDENTIFIED BY 'new_password';
GRANT ALL PRIVILEGES ON zeek_logs.* TO 'zeek_user'@'localhost';
GRANT ALL PRIVILEGES ON zeek_logs.* TO 'zeek_user'@'%';
FLUSH PRIVILEGES;
```

## Contributing

Contributions to this project are welcome. Please ensure to update tests as appropriate.
