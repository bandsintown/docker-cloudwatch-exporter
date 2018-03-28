#!/usr/bin/env bats
load helpers

# Declare the service
consul_service="consul"
address="$(dig +short ${consul_service})"
port="8500"
service="cloudwatch-exporter"

@test "Check '/config/config.yml' configuration is well rendered" {

  content="region: eu-west-1"
  template="/etc/consul-template/templates/config.ctmpl"
  file="/config/config.yml"

  # Remove the default configuration
  status=$(rm -f ${file};echo $?)
  [ "$status" -eq 0 ]

  # Register the file
  run register_key "service/${service}/config.yml" "${content}"
  [ "$status" -eq 0 ]

  # Call consul template to generate the configuration
  status=$(consul-template -consul-addr ${consul_service}:8500 -template ${template}:${file} -once;echo $?)
  [ "$status" -eq 0 ]

  # Check the expected configuration has been generated by consul-template
  status=$(test -f ${file};echo $?)
  [ "$status" -eq 0 ]

  # Check we can find the content
  status=$(grep "${content}" ${file} 2>&1 > /dev/null;echo $?)
  [ "$status" -eq 0 ]

}