[
  {
    "name": "${project}-${environment}-node",
    "cpu": ${task_cpu},
    "memory": ${task_memory},
    "image": "${docker_image}",
    "essential": true,
    "portMappings": [
      %{ if tls_ui_enabled == "true" }
      {
        "containerPort": ${tls_ui_port},
        "hostPort": ${tls_ui_port}
      },
      %{ endif }
      %{ if networking_stack == "V1" || networking_stack == "V1V2" }
      {
        "containerPort": ${listen_port_v1},
        "hostPort": ${announce_port_v1}
      },
      %{ endif }
      %{ if networking_stack == "V1V2" || networking_stack == "V2" }
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
  }
]
