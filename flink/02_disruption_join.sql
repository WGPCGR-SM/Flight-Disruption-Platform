-- Continuously joins parsed flight telemetry with Datagen-generated passenger
-- manifests, flagging any booking whose connection buffer drops under 45 minutes.
--
-- Explicit target column list is required: passenger-disruption-events also has
-- no key schema registered, so Flink adds a raw `key` column automatically that
-- this SELECT doesn't produce. Naming the target columns tells Flink to leave it null.

INSERT INTO `passenger-disruption-events` (
    event_id,
    pnr_code,
    passenger_id,
    affected_flight_id,
    buffer_time_remaining_minutes,
    disruption_type,
    recommended_action,
    `timestamp`
)
SELECT
    UUID() AS event_id,
    p.pnr_code,
    p.passenger_id,
    t.flight_id AS affected_flight_id,
    CAST((p.connecting_departure_time - t.estimated_arrival_time) / 60000 AS INT) AS buffer_time_remaining_minutes,
    'MISSED_CONNECTION_RISK' AS disruption_type,
    'AUTOMATED_REBOOKING_REQUIRED' AS recommended_action,
    UNIX_TIMESTAMP() * 1000 AS `timestamp`
FROM flight_telemetry_parsed AS t
JOIN `passenger-manifests` AS p ON t.flight_id = p.flight_id
WHERE t.flight_status = 'DELAYED'
  AND (p.connecting_departure_time - t.estimated_arrival_time) / 60000 < 45;
