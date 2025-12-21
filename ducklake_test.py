# /// script
# requires-python = ">=3.13"
# dependencies = [
#     "duckdb",
#     "requests",
# ]
# ///
import duckdb
import subprocess
import requests
import atexit
import time

def wait_for_pods():
    print("Waiting for postgres...")
    while True:
        result = subprocess.run(['kubectl', 'get', 'pods', '-n', 'databases', '-l', 'app=postgres', '-o', 'jsonpath={.items[0].status.phase}'], capture_output=True, text=True)
        if result.stdout.strip() == 'Running':
            break
        time.sleep(5)
    print("Waiting for rclone-s3...")
    while True:
        result = subprocess.run(['kubectl', 'get', 'pods', '-n', 'databases', '-l', 'app=rclone-s3', '-o', 'jsonpath={.items[0].status.phase}'], capture_output=True, text=True)
        if result.stdout.strip() == 'Running':
            break
        time.sleep(5)

def setup_port_forwards():
    """Setup kubectl port forwards and return process objects"""
    wait_for_pods()
    print("Setting up port forwards...")

    # Port forward for rclone-s3
    s3_proc = subprocess.Popen([
        'kubectl', 'port-forward', 'service/rclone-s3', '30080:80', '-n', 'databases'
    ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    # Port forward for postgres
    pg_proc = subprocess.Popen([
        'kubectl', 'port-forward', 'service/postgres', '30432:5432', '-n', 'databases'
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

def create_s3_bucket(bucket_name="data"):
    """Create bucket via kubectl exec since rclone serve s3 doesn't support CreateBucket"""
    subprocess.run([
        'kubectl', 'exec', '-n', 'databases', 'statefulset/rclone-s3', '--',
        'mkdir', '-p', f'/data/{bucket_name}'
    ], capture_output=True)

def create_ducklake_db():
    """Create the ducklake database in postgres if it doesn't exist"""
    import subprocess
    subprocess.run([
        'kubectl', 'exec', '-n', 'databases', 'deploy/postgres', '--',
        'psql', '-U', 'postgres', '-c', "CREATE DATABASE ducklake;"
    ], capture_output=True)

def main() -> None:
    setup_port_forwards()
    create_s3_bucket()
    create_ducklake_db()

    con = duckdb.connect()
    con.execute("INSTALL ducklake; INSTALL postgres; INSTALL httpfs; LOAD ducklake; LOAD postgres; LOAD httpfs;")
    con.execute("SET s3_endpoint='localhost:30080'; SET s3_use_ssl=false; SET s3_url_style='path'; SET s3_access_key_id=''; SET s3_secret_access_key='';")

    # Simple postgres connection - user/password from secret
    con.execute("ATTACH 'ducklake:postgres:dbname=ducklake host=localhost port=30432 user=postgres password=changeme' AS my_ducklake (DATA_PATH 's3://data/');")
    con.execute("USE my_ducklake;")

    print("Loading NY Taxi sample data...")
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
