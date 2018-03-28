FROM prom/cloudwatch-exporter:latest

ENV S6_LOGGING=1 S6_OVERLAY_VERSION="1.19.1.1" CONSUL_TEMPLATE_VERSION="0.19.4"

RUN curl -Ls https://releases.hashicorp.com/consul-template/${CONSUL_TEMPLATE_VERSION}/consul-template_${CONSUL_TEMPLATE_VERSION}_linux_amd64.zip -o consul-template.zip
RUN unzip consul-template.zip -d /usr/local/bin
RUN curl -Ls https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-amd64.tar.gz | tar -xz -C /
RUN echo -n "Bandsintown CloudWatch exporter\n" >> /root/.built && \
    echo -n "- with S6 Overlay: $S6_OVERLAY_VERSION, Consul Template: $CONSUL_TEMPLATE_VERSION\n" >> /root/.built

COPY rootfs /

ENTRYPOINT ["/init"]
CMD ["consul-template", "-config", "/etc/consul-template/conf"]