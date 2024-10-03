# Zeek to MySQL Integration

## Project Overview

This project provides a comprehensive solution for capturing network traffic, processing it with Zeek (formerly Bro), and storing the enriched logs into a MySQL database for further analysis and visualization. It includes scripts and configurations to enhance Zeek's capabilities with GeoIP, ASN data, and JA3/JA4 fingerprinting, enabling detailed network security monitoring and analysis.

## Features

- **Traffic Capture**: Utilizes `tcpdump` to capture live network traffic.
- **Log Processing**: Processes captured traffic with Zeek, enriched with GeoIP, ASN, and JA3/JA4 data.
- **Data Storage**: Converts Zeek logs into a MySQL database for easy querying and analysis.
- **Automation**: Includes scripts to automate the entire process and run it as a service.
- **Customization**: Allows customization of network interfaces, capture durations, and database configurations.

## Project Structure

- `zeek_to_mysql.sh`: Shell script to manage traffic capturing, Zeek processing, and database insertion.
- `zeek_to_mysql.py`: Python script to convert processed Zeek logs into MySQL.
- `asn_enrichment.zeek`: Zeek script for ASN and GeoIP enrichment.
- `.env` / `zeek_to_mysql_config.ini`: Configuration files to store environment variables.
- `setup.sh`: Enhanced setup script for initial configuration and automation.
- `README.md`: Documentation and usage instructions.

## Requirements

### Software Dependencies

- **Zeek**: Network analysis framework for monitoring network traffic.
- **MySQL/MariaDB**: Database server to store and manage the log data.
- **tcpdump**: Tool for capturing network traffic.
- **Python 3**: Required for running the Python script.
- **gcc, make, cmake, flex, bison, libpcap, openssl, swig, zlib, jemalloc**: Required for compiling Zeek from source.
- **MaxMind GeoIP Databases**: For GeoIP and ASN enrichment.
- **JA3/JA4 Zeek Packages**: For SSL/TLS fingerprinting.

### Python Libraries

Install the required Python libraries using the following command:

```bash
pip install -r requirements.txt
```

`requirements.txt`:

```plaintext
mysql-connector-python==8.0.28
python-dotenv==0.20.0
```

## Installation

### 1. System Preparation

Update your system and install essential build tools:

```bash
sudo pacman -Syu gcc make cmake flex bison libpcap openssl python3 swig zlib jemalloc
```

### 2. Install Zeek

#### a. Download Zeek Source Code

```bash
cd /opt
sudo git clone --recursive https://github.com/zeek/zeek
cd zeek
```

#### b. Configure and Compile Zeek

```bash
./configure --prefix=/opt/zeek
make -j$(nproc)
sudo make install
```

#### c. Update Network Interface in Zeek Configuration

Edit `/opt/zeek/etc/node.cfg`:

```ini
[zeek]
type=standalone
host=localhost
interface=enp3s0  # Replace with your actual network interface
```

#### d. Deploy Zeek Configuration

```bash
sudo /opt/zeek/bin/zeekctl deploy
```

### 3. Install Zeek Packages for GeoIP, ASN, and JA3/JA4

#### a. Install Zeek Package Manager (zkg)

If not already installed, install `zkg`:

```bash
pip install zkg
```

#### b. Install Required Packages

```bash
sudo zkg install ja3
sudo zkg install zeek/anthonykasza/ja4
sudo zkg install geoip-conn
```

#### c. Download MaxMind GeoIP Databases

- **Sign Up and Download**: Visit [MaxMind’s website](https://www.maxmind.com) and sign up for an account. Download the GeoLite2 City and ASN databases.
- **Place Databases**: Place the `.mmdb` files in a directory, e.g., `/usr/share/GeoIP/`.

#### d. Configure Zeek for MaxMind Integration

Edit `local.zeek` or create a new Zeek script:

```zeek
@load protocols/conn
@load policy/protocols/ssl/ja3
@load policy/protocols/ssl/ja4
redef GeoIP::db_dir = "/usr/share/GeoIP/";
```

### 4. Database Setup

#### a. Install MySQL/MariaDB

```bash
sudo pacman -S mariadb
sudo systemctl start mariadb
sudo systemctl enable mariadb
```

#### b. Secure MySQL Installation

```bash
sudo mysql_secure_installation
```

#### c. Create Database and User

Run the following SQL commands in the MySQL shell:

```sql
CREATE DATABASE zeek_logs CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'zeek_user'@'localhost' IDENTIFIED BY 'password123';
CREATE USER 'zeek_user'@'%' IDENTIFIED BY 'password123';
GRANT ALL PRIVILEGES ON zeek_logs.* TO 'zeek_user'@'localhost';
GRANT ALL PRIVILEGES ON zeek_logs.* TO 'zeek_user'@'%';
FLUSH PRIVILEGES;
EXIT;
```

#### d. Adjust MySQL Configuration (If Needed)

Edit `/etc/mysql/my.cnf` or `/etc/mysql/mariadb.conf.d/50-server.cnf`:

```ini
bind-address = 0.0.0.0
```

Restart MySQL:

```bash
sudo systemctl restart mariadb
```

### 5. Configure the Environment

Create and edit the `.env` file or `zeek_to_mysql_config.ini`:

```ini
INTERFACE=enp3s0
BASE_DIRECTORY=/path/to/base/directory
CAPTURE_DURATION=600
AUTO_RESTART=no
DB_NAME=zeek_logs
DB_USER=zeek_user
DB_PASSWORD=password123
DB_HOST=localhost
```

### 6. Install Python Dependencies

```bash
pip install mysql-connector-python python-dotenv
```

## Usage

### Initial Setup

Run the setup script to configure the environment and database connections:

```bash
./zeek_to_mysql.sh --setup
```

### Running the Capture and Analysis

Start capturing and processing traffic:

```bash
./zeek_to_mysql.sh --run
```

### Stopping the Service

To stop the running service:

```bash
./zeek_to_mysql.sh --stop
```

### Running as a Service

Create a systemd service file `/etc/systemd/system/zeek_capture.service`:

```ini
[Unit]
Description=Zeek Capture Service
After=network.target

[Service]
ExecStart=/path/to/zeek_to_mysql.sh --run
ExecStop=/path/to/zeek_to_mysql.sh --stop
WorkingDirectory=/path/to/
StandardOutput=journal
StandardError=journal
Restart=always

[Install]
WantedBy=multi-user.target
```

Enable and start the service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable zeek_capture.service
sudo systemctl start zeek_capture.service
```

## Populating Zeek with GeoIP, ASN, and JA3/JA4 Data

### GeoIP and ASN Data

1. **Download MaxMind Databases**: Place the `GeoLite2-City.mmdb` and `GeoLite2-ASN.mmdb` files in `/usr/share/GeoIP/`.
2. **Configure Zeek**: Edit Zeek configuration to include GeoIP data:

   ```zeek
   @load base/protocols/conn
   redef GeoIP::db_dir = "/usr/share/GeoIP/";
   ```

3. **Enrich Logs**: Use the `asn_enrichment.zeek` script to enrich logs with ASN and GeoIP data.

### JA3 and JA4 Fingerprinting

1. **Install Packages**:

   ```bash
   sudo zkg install ja3
   sudo zkg install zeek/anthonykasza/ja4
   ```

2. **Load Scripts in Zeek**:

   ```zeek
   @load policy/protocols/ssl/ja3
   @load policy/protocols/ssl/ja4
   ```

3. **Verify Integration**: Ensure `ssl.log` includes `ja3` and `ja3s` fields.

### Extracting SSL Issuer Information

1. **Load SSL Script**:

   ```zeek
   @load protocols/ssl
   ```

2. **Modify SSL Logging**:

   ```zeek
   redef record SSL::Info += {
       issuer: string &optional &log;
   };
   ```

3. **Add Event Handler**:

   ```zeek
   event ssl_server_hello(c: connection) {
       if ( c$ssl?$cert_chain && |c$ssl$cert_chain| > 0 ) {
           c$ssl$issuer = c$ssl$cert_chain[0]$issuer;
       }
   }
   ```

## Troubleshooting

- **Script Fails to Start**: Ensure all environment variables are set correctly and that the database is accessible.
- **Missing Dependencies**: Verify that all required software is installed and correctly configured.
- **Zeek Not Capturing Traffic**: Ensure the correct network interface is specified and that Zeek has the necessary permissions.
- **Database Connection Errors**: Check the MySQL credentials and network accessibility.

## FAQs

**Q: What is Zeek?**  
A: Zeek is an open-source network analysis framework focused on security monitoring. It provides detailed logs of network activity for analysis.

**Q: How can I verify that Zeek is processing traffic?**  
A: Check the log files generated in the specified base directory. Zeek outputs various log files such as `conn.log`, `dns.log`, `ssl.log`, etc.

**Q: Can I change the network interface used for capturing traffic?**  
A: Yes, you can specify a different network interface in the `.env` file or update it using the `--update` option in the script.

**Q: How do I integrate MaxMind GeoIP data?**  
A: Download the GeoIP databases from MaxMind, place them in a directory (e.g., `/usr/share/GeoIP/`), and configure Zeek to use them by setting `redef GeoIP::db_dir`.

**Q: How do I extract SSL issuer information with Zeek?**  
A: Load the SSL script in Zeek and modify the logging to include the issuer information. See the [Extracting SSL Issuer Information](#extracting-ssl-issuer-information) section.

## Contributing

Contributions to this project are welcome. Please submit pull requests or issues on the project's repository. Ensure that any scripts or code are thoroughly tested and that documentation is updated accordingly.

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.

## Additional Resources

- **Zeek Documentation**: [https://docs.zeek.org/en/current/](https://docs.zeek.org/en/current/)
- **MaxMind GeoIP Databases**: [https://www.maxmind.com/en/home](https://www.maxmind.com/en/home)
- **JA3 Fingerprinting**: [https://github.com/salesforce/ja3](https://github.com/salesforce/ja3)
- **JA4 Fingerprinting**: [https://github.com/anthonykasza/ja4](https://github.com/anthonykasza/ja4)

---
SAMPLE DASHBOARD 
![image](https://github.com/user-attachments/assets/745f3750-a6f2-4c65-9bdd-6761be439ec3)

Feel free to adjust paths, filenames, and other specifics according to your project's setup and requirements. This README provides a structured and comprehensive guide to setting up, configuring, and using the Zeek to MySQL integration with enhanced features for network security monitoring.
