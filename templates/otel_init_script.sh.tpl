mkdir -p /etc/otelcol-contrib
echo $OTEL_CONFIG | base64 -d > /etc/otelcol-contrib/config.yaml
/otelcol-contrib --config /etc/otelcol-contrib/config.yaml