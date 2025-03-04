[
  {
    "name": "${project}-${environment}-node",
    "cpu": ${task_cpu - 128},
    "memory": ${task_memory - 256},
    "image": "${docker_image}",
    "essential": true,
    "portMappings": [
      %{ if tls_ui_enabled == "true" }
      {
        "containerPort": ${tls_ui_port},
        "hostPort": ${tls_ui_port}
      },
      %{ endif }
      %{ if networking_stack == "V2" }
      {
        "containerPort": ${listen_port_v2},
        "hostPort": ${announce_port_v2}
      },
      %{ endif }
      {
        "containerPort": ${ui_port},
        "hostPort": ${ui_port}
      }
    ],
    "entryPoint": ["/bin/bash"],
    "command": ["-c", "${init_script}"],
    "environment" : [
      %{~ for definition in env_vars ~}
      { "name" : "${definition.name}", "value" : "${definition.value}" },
      %{~ endfor ~}
      %{ if tls_ui_enabled == "true" }
      { "name" : "TASK_TLS_CERT_PATH", "value" : "${tls_cert_path}" },
      { "name" : "TASK_TLS_KEY_PATH", "value" : "${tls_key_path}" },
      %{ endif }
      { "name" : "TOML_CONFIG_ENABLED", "value" : "true" }
    ],
    "secrets": [
      %{ if tls_ui_enabled == "true" }
      {
        "name": "TLS_CERT",
        "valueFrom": "${tls_cert}"
      },
      {
        "name": "TLS_KEY",
        "valueFrom": "${tls_key}"
      },
      %{ endif }
      {
        "name": "CONFIG",
        "valueFrom": "${config}"
      },
      {
        "name": "SECRETS",
        "valueFrom": "${secrets}"
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
          "awslogs-region": "${aws_region}",
          "awslogs-group": "/aws/ecs/${project}-${environment}-node",
          "awslogs-stream-prefix": "node"
      }
    }
  },
  {
    "name": "${project}-${environment}-otel",
    "cpu": 128,
    "memory": 256,
    "image": "orionstaking/opentelemetry-collector-contrib:0.108.0",
    "essential": false,
    "portMappings": [
      {
        "containerPort": 13133,
        "hostPort": 13133,
        "protocol": "tcp"
      },
      {
        "containerPort": 4317,
        "hostPort": 4317,
        "protocol": "tcp"
      },
      {
        "containerPort": 4318,
        "hostPort": 4318,
        "protocol": "tcp"
      },
      {
        "containerPort": 55679,
        "hostPort": 55679,
        "protocol": "tcp"
      }
    ],
    "entryPoint": ["/bin/bash"],
    "command": ["-c", "${otel_init_script}"],
    "environment": [],
    "secrets": [
      {
        "name": "OTEL_CONFIG",
        "valueFrom": "${otel_config}"
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-region": "${aws_region}",
        "awslogs-group": "/aws/ecs/${project}-${environment}-otel",
        "awslogs-stream-prefix": "otel"
      }
    }
  }
]
