#/bin/bash
# only download if it doesn't exist
if [ ! -f stations.csv ]; then
    wget https://github.com/trainline-eu/stations/raw/refs/heads/master/stations.csv
fi

clickhouse-local wrangler.sql
