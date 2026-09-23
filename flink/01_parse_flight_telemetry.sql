-- The MQTT Source Connector has no Schema Registry support and writes raw bytes
-- (BYTES key, BYTES val) to the flight-telemetry topic. This job parses those raw
-- JSON payloads into a proper typed table, continuously.

-- Check the raw inferred table's column names first if reproducing this:
-- DESCRIBE `flight-telemetry`;

CREATE TABLE flight_telemetry_parsed (
    flight_id STRING,
    aircraft_registration STRING,
    current_latitude DOUBLE,
    current_longitude DOUBLE,
    estimated_arrival_time BIGINT,
    delay_minutes INT,
    flight_status STRING
) WITH (
    'connector' = 'confluent',
    'value.format' = 'json-registry'
);

INSERT INTO flight_telemetry_parsed
SELECT
    JSON_VALUE(CAST(`val` AS STRING), '$.flight_id') AS flight_id,
    JSON_VALUE(CAST(`val` AS STRING), '$.aircraft_registration') AS aircraft_registration,
    CAST(JSON_VALUE(CAST(`val` AS STRING), '$.current_latitude') AS DOUBLE) AS current_latitude,
    CAST(JSON_VALUE(CAST(`val` AS STRING), '$.current_longitude') AS DOUBLE) AS current_longitude,
    CAST(JSON_VALUE(CAST(`val` AS STRING), '$.estimated_arrival_time') AS BIGINT) AS estimated_arrival_time,
    CAST(JSON_VALUE(CAST(`val` AS STRING), '$.delay_minutes') AS INT) AS delay_minutes,
    JSON_VALUE(CAST(`val` AS STRING), '$.flight_status') AS flight_status
FROM `flight-telemetry`;
