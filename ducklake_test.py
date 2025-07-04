# /// script
# requires-python = ">=3.13"
# dependencies = [
#     "duckdb",
#     "requests",
# ]
# ///
import duckdb
import subprocess
import base64
import json
import requests
import atexit
import time

def wait_for_postgres():
    while True:
        # Below needs better targeting
        result = subprocess.run(['kubectl', 'get', 'pods', '-n', 'everest', '-l', 'app.kubernetes.io/name=postgres01', '-o', 'jsonpath={.items[0].status.phase}'], capture_output=True, text=True)
        if result.stdout.strip() == 'Running':
            break
        time.sleep(30)

def setup_port_forwards():
    # TODO: wait_for_postgres()
    """Setup kubectl port forwards and return process objects"""
    print("Setting up port forwards...")

    # Port forward for s3proxy
    s3_proc = subprocess.Popen([
        'kubectl', 'port-forward', 'service/s3proxy', '30080:80', '-n', 'everest'
    ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    # Port forward for postgres
    pg_proc = subprocess.Popen([
        'kubectl', 'port-forward', 'service/postgres01-pgbouncer', '30432:5432', '-n', 'everest'
    ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    # Wait for port forwards to be ready
    time.sleep(3)

    # Register cleanup function
    def cleanup():
        print("Cleaning up port forwards...")
        s3_proc.terminate()
        pg_proc.terminate()
        s3_proc.wait()
        pg_proc.wait()

    atexit.register(cleanup)
    return s3_proc, pg_proc

def create_s3_bucket(bucket_name="data", s3_endpoint="localhost:30080"):
    requests.put(f"http://{s3_endpoint}/{bucket_name}")

def get_attach(secret="everest-secrets-postgres01", ns="everest"):
    result = subprocess.run(['kubectl', 'get', 'secret', secret, '-n', ns, '-o', 'json'], capture_output=True, text=True, check=True)
    secret_data = json.loads(result.stdout)['data']
    user = base64.b64decode(secret_data['user']).decode('utf-8')
    password = base64.b64decode(secret_data['password']).decode('utf-8')
    return f"ATTACH 'ducklake:postgres:dbname=postgres host=localhost port=30432 user={user} password={password}' AS my_ducklake (DATA_PATH 's3://data/');"

def main() -> None:
    setup_port_forwards()
    create_s3_bucket()

    con = duckdb.connect()
    con.execute("INSTALL ducklake; INSTALL postgres; INSTALL httpfs; LOAD ducklake; LOAD postgres; LOAD httpfs;")
    con.execute("SET s3_endpoint='localhost:30080'; SET s3_use_ssl=false; SET s3_url_style='path'; SET s3_access_key_id=''; SET s3_secret_access_key='';")

    con.execute(get_attach())
    con.execute("USE my_ducklake;")

    print("Loading all NY Taxi data...")
    con.execute("""
        CREATE TABLE IF NOT EXISTS ny_taxi AS 
        SELECT * FROM read_parquet('https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2023-01.parquet');
    """)

    print("Row count:", con.execute("SELECT COUNT(*) FROM ny_taxi;").fetchone()[0])

    print("\nDaily trip summary:")
    result = con.execute("""
        SELECT 
            DATE(tpep_pickup_datetime) as trip_date,
            COUNT(*) as total_trips,
            ROUND(AVG(trip_distance), 2) as avg_distance,
            ROUND(AVG(total_amount), 2) as avg_fare,
            ROUND(SUM(total_amount), 2) as total_revenue
        FROM ny_taxi 
        WHERE tpep_pickup_datetime IS NOT NULL
        GROUP BY DATE(tpep_pickup_datetime)
        ORDER BY trip_date
        LIMIT 10;
    """).fetchall()

    for row in result:
        print(f"Date: {row[0]}, Trips: {row[1]}, Avg Distance: {row[2]}mi, Avg Fare: ${row[3]}, Revenue: ${row[4]}")

if __name__ == "__main__":
    main()
