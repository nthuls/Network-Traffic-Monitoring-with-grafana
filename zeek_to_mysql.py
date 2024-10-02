import os
import csv
import sys
import mysql.connector
from mysql.connector import errorcode
import logging
from dotenv import load_dotenv

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

def load_environment():
    """Load environment variables from the .env file."""
    base_directory = os.path.dirname(os.path.realpath(__file__))
    dotenv_path = os.path.join(base_directory, '.env')
    load_dotenv(dotenv_path)

def test_db_connection(config):
    """Test the database connection and log the outcome."""
    try:
        with mysql.connector.connect(**config) as conn:
            logging.info(f"Successfully connected to the database: {config['database']}")
            return True
    except mysql.connector.Error as err:
        logging.error(f"Failed to connect to the database: {err}")
        return False

def create_table(cursor, table_name, columns):
    """Create a table with dynamic columns."""
    column_definitions = ', '.join([f"`{col}` TEXT" for col in columns])
    sql_query = f"CREATE TABLE IF NOT EXISTS `{table_name}` ({column_definitions});"
    cursor.execute(sql_query)
    logging.info(f"Table `{table_name}` created or verified.")

def insert_data(cursor, table_name, columns, data):
    """Insert data into the specified table."""
    placeholders = ', '.join(['%s' for _ in columns])
    sql_query = f"INSERT INTO `{table_name}` ({', '.join([f'`{col}`' for col in columns])}) VALUES ({placeholders});"
    cursor.executemany(sql_query, data)
    logging.info(f"Inserted data into `{table_name}`.")

def process_zeek_logs(directory, db_config):
    """Process each Zeek log file in the directory and store data in MySQL."""
    try:
        conn = mysql.connector.connect(**db_config)
        cursor = conn.cursor()
        logging.info("Database connection established.")

        for filename in os.listdir(directory):
            if filename.endswith(".log"):
                table_name = filename.replace('.log', '').replace('-', '_')
                file_path = os.path.join(directory, filename)
                logging.info(f"Processing file: {file_path}")

                with open(file_path, 'r') as file:
                    reader = csv.reader(file, delimiter='\t')
                    columns = next((row[1:] for row in reader if row[0].startswith('#fields')), None)
                    if not columns:
                        logging.warning(f"No columns found in {filename}. Skipping.")
                        continue
                    create_table(cursor, table_name, columns)
                    data = [row for row in reader if not row[0].startswith('#')]
                    if data:
                        insert_data(cursor, table_name, columns, data)

        conn.commit()
    except mysql.connector.Error as err:
        logging.error(f"Database error: {err}")
    finally:
        cursor.close()
        conn.close()
        logging.info("Database connection closed.")

if __name__ == "__main__":
    load_environment()
    db_config = {
        'user': os.getenv('DB_USER'),
        'password': os.getenv('DB_PASSWORD'),
        'host': os.getenv('DB_HOST', 'localhost'),
        'database': os.getenv('DB_NAME'),
        'charset': 'utf8mb4',
        'collation': 'utf8mb4_unicode_ci'
    }

    if test_db_connection(db_config):
        logs_directory = os.path.join(os.path.dirname(os.path.realpath(__file__)))
        process_zeek_logs(logs_directory, db_config)
    else:
        logging.error("Exiting due to failed database connection.")
        sys.exit(1)
