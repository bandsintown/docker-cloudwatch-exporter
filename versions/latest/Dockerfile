# ----------------------------------------------------------------------------------------------------------------------
FROM bandsintown/alpine:3.6 as builder

# ----------------------------------------------------------------------------------------------------------------------
FROM prom/cloudwatch-exporter:latest

ENV S6_LOGGING=1 S6_OVERLAY_VERSION="1.19.1.1"

COPY --from=builder /usr/local/bin/consul-template /usr/local/bin/consul-template
COPY --from=builder /usr/sbin/go-dnsmasq /usr/sbin/go-dnsmasq
COPY --from=builder /etc/cont-init.d /etc/cont-init.d
COPY --from=builder /etc/services.d /etc/services.d
COPY --from=builder /root /root

COPY rootfs /

RUN curl -Ls https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-amd64.tar.gz | tar -xz -C /

ENTRYPOINT ["/init"]
CMD ["consul-template", "-config", "/etc/consul-template/conf"]