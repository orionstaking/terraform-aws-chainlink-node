[
  {
    "name": "${project}-${environment}-node",
    "cpu": ${cpu},
    "memory": ${memory},
    "image": "${docker_image}",
    "essential": true,
    "portMappings": [
      {
        "containerPort": ${port_ui},
        "hostPort": ${port_ui}
      },
      %{ if https_ui_enabled == "true" }
      {
        "containerPort": ${tls_port_ui},
        "hostPort": ${tls_port_ui}
      },
      %{ endif }
      {
        "containerPort": ${port_node},
        "hostPort": ${port_node}
      }
    ],
    "entryPoint": ["/bin/bash"],
    "command": ["-c", "${init_script}"],
    "environment" : [
      %{~ for definition in node_config ~}
      { "name" : "${definition.name}", "value" : "${definition.value}" },
      %{~ endfor ~}
      { "name" : "CHAINLINK_PORT", "value" : "${port_ui}" },
      { "name" : "HTTPS_UI_ENABLED", "value" : "${https_ui_enabled}" },
      { "name" : "CHAINLINK_TLS_PORT", "value" : "${tls_port_ui}" },
      { "name" : "P2P_ANNOUNCE_PORT", "value" : "${port_node}" },
      { "name" : "P2P_LISTEN_PORT", "value" : "${port_node}" },
      { "name" : "JSON_CONSOLE", "value" : "true" },
      { "name" : "SUBNET_MAP", "value" : "${subnet_mapping}" }
    ],
    "secrets": [
      {
        "name": "KEYSTORE_PASSWORD",
        "valueFrom": "${keystore_password}"
      },
      %{ if https_ui_enabled == "true" }
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
        "name": "API_CREDENTIALS",
        "valueFrom": "${api_credentials}"
      },
      {
        "name": "DATABASE_URL",
        "valueFrom": "${database_url}"
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
