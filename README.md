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

### Initial Setup
Set up the environment and database:

```bash
./zeek_to_mysql.sh --setup
```

### Running the Script
Start the capture and processing:

```bash
./zeek_to_mysql.sh --run
```

### Stopping the Service
To stop a running service:

```bash
./zeek_to_mysql.sh --stop
```

## Enhancements

### GeoIP and ASN

To provide geographic and autonomous system information in your traffic analysis, integrate MaxMind's GeoIP databases into Zeek. This data enriches the logs with location and network ownership details, adding valuable context for security analysis.

### SSL/TLS Fingerprinting with JA3/JA4

Implement JA3 and JA4 fingerprinting to capture unique identifiers of SSL/TLS client and server handshakes. This helps in detecting and analyzing encrypted traffic patterns, contributing to more effective monitoring and threat detection.

### Setup Steps

#### Locate Prerequisites

For systems using `pacman`:

```bash
sudo pacman -Syu gcc make cmake flex bison libpcap openssl python3 swig zlib jemalloc
```

To find paths for GeoIP, OpenSSL, and pcap libraries:

```bash
locate GeoIP.dat
openssl version -a
locate libpcap.so
```

#### Download and Install Zeek

```bash
cd /opt
sudo git clone --recursive https://github.com/zeek/zeek
cd zeek
./configure --prefix=/opt/zeek && make -j$(nproc) && sudo make install
```

Configure Zeek to use the correct network interface:

```bash
sed -i 's/interface=eth0/interface=enp3s0/' /opt/zeek/etc/node.cfg
sudo /opt/zeek/bin/zeekctl deploy
```

#### Integration with MySQL

Run the SQL setup commands to configure your MySQL database for storing Zeek logs:

```sql
CREATE DATABASE zeek_logs;
CREATE USER 'zeek_user'@'localhost' IDENTIFIED BY 'new_password';
GRANT ALL PRIVILEGES ON zeek_logs.* TO 'zeek_user'@'localhost';
FLUSH PRIVILEGES;
```

## Troubleshooting

- **Script Fails to Start**: Check the `.env` file for correct settings and ensure that all dependencies are installed.
- **Missing Dependencies**: Verify that MySQL, Zeek, and required Python packages are installed and configured correctly.

## FAQ

**Q: What is Zeek?**  
A: Zeek is an open-source network security monitor that goes beyond signature-based attack detection, providing comprehensive logging of network transactions for detailed analysis.

**Q: How can I verify that Zeek is processing traffic?**  
A: Check the log files generated in the specified base directory. Zeek outputs various log files such as `conn.log`, `dns.log`, etc.

**Q: Can I change the network interface used for capturing traffic?**  
A: Yes, you can specify a different network interface in the `.env` file or update it using the `--update` option in the script.

## Contributing

Contributions to this project are welcome. Please ensure to update tests as appropriate.
