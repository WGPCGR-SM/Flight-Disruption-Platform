# Flight Disruption Platform

A real-time flight disruption alert system built on Confluent Cloud that watches for
passengers who are about to miss a connecting flight because their first flight got
delayed. Built for airline operations teams, or any airline app that wants to warn
passengers before they land instead of after.

## What it does

- An **MQTT Source Connector** ingests simulated aircraft telemetry (position, delay
  status, ETA) as raw messages onto the `flight-telemetry` topic.
- A **Flink SQL job** parses those raw MQTT messages (JSON payload, no native schema
  support on this connector) into a structured, typed stream: `flight_telemetry_parsed`.
- A **Datagen Source Connector** generates synthetic passenger booking data (seat
  assignments, connecting flights, loyalty tiers) onto `passenger-manifests`.
- A second **Flink SQL job** continuously joins the parsed telemetry stream with the
  passenger manifests, calculates each passenger's remaining connection buffer, and
  flags any booking with less than 45 minutes to spare as a `MISSED_CONNECTION_RISK`,
  writing the result to `passenger-disruption-events`.
- An **HTTP Sink Connector** delivers those flagged events to a notification endpoint.
- **Schema Registry** enforces data contracts across the processed topics, and
  **Stream Lineage** was used to trace and verify the full end-to-end data flow.

## Business impact

Missed connections are expensive for airlines — every rebooking costs agent time,
sometimes a hotel voucher or lounge access, and almost always a frustrated customer.
Catching at-risk connections while the first flight is still in the air (instead of
after the passenger reaches the gate) means ground staff can pre-arrange rebooking
proactively. That's fewer missed connections, lower compensation costs, less pressure
on staff during irregular operations, and better passenger retention — the kind of
pipeline where shaving minutes off detection time translates into measurable savings
at scale.

## Connectors used

1. **MQTT Source Connector** — ingests simulated flight telemetry
2. **Datagen Source Connector** — generates synthetic passenger manifest data
3. **HTTP Sink Connector** — delivers disruption alerts to a notification endpoint

## Repo structure

```
flight-disruption-platform/
├── README.md
├── schemas/
│   ├── passenger-manifests-datagen-schema.json   # Datagen custom Avro schema
│   ├── flight-telemetry-parsed-columns.json      # Flink-derived table structure
│   └── passenger-disruption-events.avsc          # Avro schema (Schema Registry)
├── flink/
│   ├── 01_parse_flight_telemetry.sql             # raw MQTT bytes -> typed stream
│   └── 02_disruption_join.sql                    # the temporal join + filter
└── mqtt/
    ├── publish_commands.md
    └── sample_messages/
        ├── message1.json
        ├── message2.json
        └── message3.json
```

## How to reproduce

See `flink/01_parse_flight_telemetry.sql` and `flink/02_disruption_join.sql` for the
exact statements run in Confluent Cloud for Apache Flink. See `mqtt/publish_commands.md`
for how test telemetry was published via `mosquitto_pub` against the public
`test.mosquitto.org` broker.

All Confluent Cloud resources (cluster, connectors, Flink compute pool) were torn down
after capturing evidence (Stream Lineage screenshot, topic contents) to avoid ongoing
cost — this was a one-time build-and-verify exercise, not a persistently running
deployment.
