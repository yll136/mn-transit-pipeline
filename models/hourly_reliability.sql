{{ config(materialized='table') }}
WITH ranked AS (
  SELECT
    bus.trip_id,
    st.stop_id,
    s.stop_name,
    COALESCE(r.route_long_name, CAST(r.route_short_name AS STRING)) AS route_name,
    ROUND( ST_DISTANCE(
      ST_GEOGPOINT(bus.longitude, bus.latitude),
      ST_GEOGPOINT(s.stop_lon, s.stop_lat)
    ), 0) AS distance,
    ROW_NUMBER() OVER (
    PARTITION BY CAST(bus.trip_id AS INT), st.stop_id
    ORDER BY ST_DISTANCE(
      ST_GEOGPOINT(bus.longitude, bus.latitude),
      ST_GEOGPOINT(s.stop_lon, s.stop_lat)
    )
  ) AS stop_rank,
    bus.collected_at,
    DATETIME(TIMESTAMP(bus.collected_at, "Europe/Belgrade"), "America/Chicago") AS actual_local,
  st.arrival_time AS scheduled_time,
    TIME_DIFF(
  TIME(DATETIME(TIMESTAMP(bus.collected_at, "Europe/Belgrade"), "America/Chicago")),
  SAFE.PARSE_TIME("%H:%M:%S", st.arrival_time),
  MINUTE
) AS minutes_late,
    EXTRACT(HOUR FROM DATETIME(TIMESTAMP(collected_at, "Europe/Belgrade"), "America/Chicago")) AS hour,
    st.stop_sequence
  FROM `project-2eb301e4-cadc-49d8-9bb.transit.bus_positions` AS bus
  JOIN `project-2eb301e4-cadc-49d8-9bb.transit.stop_times` AS st
    ON CAST(bus.trip_id AS INT) = st.trip_id
  JOIN `project-2eb301e4-cadc-49d8-9bb.transit.stops` AS s 
    ON s.stop_id = st.stop_id
  JOIN `project-2eb301e4-cadc-49d8-9bb.transit.trips` AS t
    ON CAST(bus.trip_id AS INT) = t.trip_id        
  JOIN `project-2eb301e4-cadc-49d8-9bb.transit.routes` AS r
    ON CAST(t.route_id AS STRING) = CAST(r.route_id AS STRING)       
  )
SELECT
  hour,
  ROUND(AVG(minutes_late), 1) AS avg_minutes_late,
  COUNT(*) AS num_arrivals
FROM ranked
WHERE stop_rank = 1 AND distance < 150 AND minutes_late BETWEEN -5 AND 60
GROUP BY hour
ORDER BY hour