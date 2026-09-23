# Publishing test telemetry

The MQTT Source Connector subscribes to `aviation/telemetry` on the public
`test.mosquitto.org` broker. Test messages were published from a local terminal
using `mosquitto_pub`, reading from a file (avoids shell quote-escaping issues
with inline `-m` JSON):

```bash
mosquitto_pub -h test.mosquitto.org -t aviation/telemetry -f sample_messages/message1.json
mosquitto_pub -h test.mosquitto.org -t aviation/telemetry -f sample_messages/message2.json
mosquitto_pub -h test.mosquitto.org -t aviation/telemetry -f sample_messages/message3.json
```

Each file is a single valid JSON object matching the fields expected by the
`flight_telemetry_parsed` Flink job (see `flink/01_parse_flight_telemetry.sql`).
