# Stage 1: Pull OpenTelemetry Collector image (this gives us the otelcol-contrib binary)
FROM otel/opentelemetry-collector-contrib:0.108.0 as otel

# Stage 2: Create an Alpine-based image with bash and the copied binary
FROM alpine:latest

# Install bash and other utilities you may need (like curl, ca-certificates)
RUN apk update && apk add --no-cache bash curl ca-certificates

# Copy the OpenTelemetry Collector binary from the previous stage
COPY --from=otel /otelcol-contrib /otelcol-contrib

# Expose necessary ports (same as the default config)
EXPOSE 13133 4317 4318 55679
