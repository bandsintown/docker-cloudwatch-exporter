[![dockeri.co](http://dockeri.co/image/bandsintown/statsd-exporter)](https://hub.docker.com/r/bandsintown/statsd-exporter/)

[![Build status](https://badge.buildkite.com/e3af3f8a581ca8f2e426f7bbd0535340dbc62d77aa7ad4368c.svg)](https://buildkite.com/bandsintown/docker-statsd-exporter)
[![GitHub issues](https://img.shields.io/github/issues/bandsintown/docker-statsd-exporter.svg "GitHub issues")](https://github.com/bandsintown/docker-statsd-exporter)
[![GitHub stars](https://img.shields.io/github/stars/bandsintown/docker-statsd-exporter.svg "GitHub stars")](https://github.com/bandsintown/docker-statsd-exporter)
[![Docker layers](https://images.microbadger.com/badges/image/bandsintown/statsd-exporter.svg)](https://microbadger.com/images/bandsintown/statsd-exporter)

# What is statsd_exporter?
The statsd_exporter is tool that receives StatsD-style metrics and exports them as Prometheus metrics.

* [Documentation](https://github.com/prometheus/statsd_exporter)


## Motivation

We built this image to use Consul and Consul Template to be able to configure statsd_exporter dynamically.

In particular we want to be able to add mappings.

This image allows to define the mapping configuration file ``statsd_exporter.config`` file as a Consul key.

## Configuration through Consul

To manage the statsd_exporter mapping configuration through Consul you have to create a Consul key at `service/statsd_exporter/statsd_exporter.config`

## Configuration file Example

### Metric Mapping and Configuration

The `statsd_exporter` can be configured to translate specific dot-separated StatsD
metrics into labeled Prometheus metrics via a simple mapping language. A
mapping definition starts with a line matching the StatsD metric in question,
with `*`s acting as wildcards for each dot-separated metric component. The
lines following the matching expression must contain one `label="value"` pair
each, and at least define the metric name (label name `name`). The Prometheus
metric is then constructed from these labels. `$n`-style references in the
label value are replaced by the n-th wildcard match in the matching line,
starting at 1. Multiple matching definitions are separated by one or more empty
lines. The first mapping rule that matches a StatsD metric wins.

Metrics that don't match any mapping in the configuration file are translated
into Prometheus metrics without any labels and with any non-alphanumeric
characters, including periods, translated into underscores.

In general, the different metric types are translated as follows:

    StatsD gauge   -> Prometheus gauge

    StatsD counter -> Prometheus counter

    StatsD timer   -> Prometheus summary                    <-- indicates timer quantiles
                   -> Prometheus counter (suffix `_total`)  <-- indicates total time spent
                   -> Prometheus counter (suffix `_count`)  <-- indicates total number of timer events

An example mapping configuration:

```yaml
mappings:
- match: test.dispatcher.*.*.*
  name: "dispatcher_events_total"
  labels:
    processor: "$1"
    action: "$2"
    outcome: "$3"
    job: "test_dispatcher"
- match: *.signup.*.*
  name: "signup_events_total"
  labels:
    provider: "$2"
    outcome: "$3"
    job: "${1}_server"
```

This would transform these example StatsD metrics into Prometheus metrics as
follows:

    test.dispatcher.FooProcessor.send.success
     => dispatcher_events_total{processor="FooProcessor", action="send", outcome="success", job="test_dispatcher"}

    foo_product.signup.facebook.failure
     => signup_events_total{provider="facebook", outcome="failure", job="foo_product_server"}

    test.web-server.foo.bar
     => test_web_server_foo_bar{}

Each mapping in the configuration file must define a `name` for the metric.

If the default metric help text is insufficient for your needs you may use the YAML
configuration to specify a custom help text for each mapping:
```yaml
mappings:
- match: http.request.*
  help: "Total number of http requests"
  name: "http_requests_total"
  labels:
    code: "$1"
```

In the configuration, one may also set the timer type to "histogram". The 
default is "summary" as in the plain text configuration format.  For example,
to set the timer type for a single metric:

```yaml
mappings:
- match: test.timing.*.*.*
  timer_type: histogram
  buckets: [ 0.01, 0.025, 0.05, 0.1 ]
  name: "my_timer"
  labels:
    provider: "$2"
    outcome: "$3"
    job: "${1}_server"
```

Another capability when using YAML configuration is the ability to define matches
using raw regular expressions as opposed to the default globbing style of match.
This may allow for pulling structured data from otherwise poorly named statsd
metrics AND allow for more precise targetting of match rules. When no `match_type`
paramter is specified the default value of `glob` will be assumed:

```yaml
mappings:
- match: (.*)\.(.*)--(.*)\.status\.(.*)\.count
  match_type: regex
  name: "request_total"
  labels:
    hostname: "$1"
    exec: "$2"
    protocol: "$3"
    code: "$4"
```

Note, that one may also set the histogram buckets.  If not set, then the default
[Prometheus client values](https://godoc.org/github.com/prometheus/client_golang/prometheus#pkg-variables) are used: `[.005, .01, .025, .05, .1, .25, .5, 1, 2.5, 5, 10]`. `+Inf` is added
automatically.

`timer_type` is only used when the statsd metric type is a timer. `buckets` is
only used when the statsd metric type is a timerand the `timer_type` is set to
"histogram."

One may also set defaults for the timer type, buckets and match_type. These will be used
by all mappings that do not define these.

```yaml
defaults:
  timer_type: histogram
  buckets: [.005, .01, .025, .05, .1, .25, .5, 1, 2.5 ]
  match_type: glob
mappings:
# This will be a histogram using the buckets set in `defaults`.
- match: test.timing.*.*.*
  name: "my_timer"
  labels: 
    provider: "$2"
    outcome: "$3"
    job: "${1}_server"
# This will be a summary timer.
- match: other.timing.*.*.*
  timer_type: summary
  name: "other_timer"
  labels: 
    provider: "$2"
    outcome: "$3"
    job: "${1}_server_other"
```

## Architecture

To pipe metrics from an existing StatsD environment into Prometheus, configure
StatsD's repeater backend to repeat all received metrics to a `statsd_exporter`
process. This exporter translates StatsD metrics to Prometheus metrics via
configured mapping rules.

    +----------+                         +-------------------+                        +--------------+
    |  StatsD  |---(UDP/TCP repeater)--->|  statsd_exporter  |<---(scrape /metrics)---|  Prometheus  |
    +----------+                         +-------------------+                        +--------------+
