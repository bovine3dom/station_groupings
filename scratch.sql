WITH stations as (
  SELECT *
  FROM 'stations.csv' l
  WHERE latitude IS NOT NULL 
    AND longitude IS NOT NULL 
    AND uic IS NOT NULL
    AND country != 'RU'
  SETTINGS format_csv_delimiter = ';'
)
select l.country, l.name, r.country, r.name,
round(geoDistance(l.longitude, l.latitude, r.longitude, r.latitude)/1000) wgs84distance
from stations l
cross join stations r
where l.name > r.name
order by wgs84distance desc
limit 100
into outfile 'furthest_station_pairs.csv' TRUNCATE FORMAT CSVWithNames;
