#!/usr/bin/env bats

@test "Check consul is up and running" {
  # Check Consul is reachable
  run curl http://consul:8500/v1/catalog/service/consul
  [ "$status" -eq 0 ]
}