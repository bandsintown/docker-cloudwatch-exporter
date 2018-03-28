#----------------------------------------------------------------------------------------------------------------------
FROM bandsintown/alpine:3.6 as builder

#----------------------------------------------------------------------------------------------------------------------
FROM prom/cloudwatch-exporter:latest

ENV S6_OVERLAY_VERSION="1.19.1.1" GODNSMASQ_VERSION="1.0.7" CONSUL_TEMPLATE_VERSION="0.19.4"

COPY --from=builder /usr/local/bin/consul-template /usr/local/bin/consul-template
COPY --from=builder /usr/sbin/go-dnsmasq /usr/sbin/go-dnsmasq
COPY --from=builder /etc/cont-init.d /etc/cont-init.d
COPY --from=builder /etc/services.d /etc/services.d
COPY --from=builder /root /root