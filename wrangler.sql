-- clickhouse-local
-- grouping stations by ~5 min walking distance, ~500m
-- tweak distances in geoToH3=10 and h3kRing=2
-- https://clupasq.github.io/h3-viewer/ is handy for eyeballing it
WITH raw_clusters AS (
    SELECT arraySort(groupUniqArray(name)) AS stations
    FROM (
        SELECT 
            (name, uic, country) as name,
            geoToH3(assumeNotNull(latitude), assumeNotNull(longitude), 10) AS point_cell,
            h3kRing(point_cell, 2) AS cluster_cells
        FROM 'stations.csv'
        WHERE latitude IS NOT NULL 
          AND longitude IS NOT NULL 
          AND uic IS NOT NULL
        SETTINGS format_csv_delimiter = ';'
    ) 
    ARRAY JOIN cluster_cells AS cluster_cell
    GROUP BY cluster_cell
),
unique_clusters AS (
    SELECT DISTINCT stations 
    FROM raw_clusters
),
clusters_with_id AS (
    SELECT 
        cityHash64(toString(stations)) AS cid, -- this saves extraordinary amounts of memory
        stations, 
        length(stations) AS len
    FROM unique_clusters
),
exploded AS ( -- get cluster membership of every station
    SELECT cid, len, station 
    FROM clusters_with_id
    ARRAY JOIN stations AS station
),
subsets AS (
    SELECT e1.cid
    FROM exploded AS e1
    JOIN exploded AS e2 
      ON e1.station = e2.station
    WHERE e1.len < e2.len -- supersets are larger
    GROUP BY e1.cid, e1.len, e2.cid
    HAVING count() = e1.len
)
SELECT 
    stations
    --len AS station_count
FROM clusters_with_id
WHERE cid NOT IN (SELECT cid FROM subsets) -- filter out subsets => only left with supersets
ORDER BY len DESC
INTO OUTFILE 'station_groups.csv' TRUNCATE FORMAT CSVWithNames;
