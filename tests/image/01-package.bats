@test "'statsd_exporter' should be present" {
  run /bin/statsd_exporter -version
  [ $status -eq 0 ]
}