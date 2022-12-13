[
  {
    "name": "${project}-${environment}-node",
    "cpu": ${cpu},
    "memory": ${memory},
    "image": "${docker_image}",
    "essential": true,
    "portMappings": [
      %{ if tls_ui_enabled == "true" }
      {
        "containerPort": ${tls_port_ui},
        "hostPort": ${tls_port_ui}
      },
      %{ endif }
      %{ if networking_stack == "V1" || networking_stack == "V1V2" }
      {
        "containerPort": ${port_node_v1},
        "hostPort": ${port_node_v1}
      },
      %{ endif }
      %{ if networking_stack == "V1V2" || networking_stack == "V2" }
      {
        "containerPort": ${port_node_v2},
        "hostPort": ${port_node_v2}
      },
      %{ endif }
      {
        "containerPort": ${port_ui},
        "hostPort": ${port_ui}
      }
    ],
    "entryPoint": ["/bin/bash"],
    "command": ["-c", "${init_script}"],
    "environment" : [
      %{~ for definition in node_config ~}
      { "name" : "${definition.name}", "value" : "${definition.value}" },
      %{~ endfor ~}
      { "name" : "CHAINLINK_PORT", "value" : "${port_ui}" },
      { "name" : "TLS_UI_ENABLED", "value" : "${tls_ui_enabled}" },
      { "name" : "CHAINLINK_TLS_PORT", "value" : "${tls_port_ui}" },
      { "name" : "P2P_NETWORKING_STACK", "value" : "${networking_stack}" },
      %{ if networking_stack == "V1" || networking_stack == "V1V2" }
      { "name" : "P2P_ANNOUNCE_PORT", "value" : "${port_node_v1}" },
      { "name" : "P2P_LISTEN_PORT", "value" : "${port_node_v1}" },
      %{ endif }
      %{ if networking_stack == "V1V2" || networking_stack == "V2" }
      { "name" : "P2P_ANNOUNCE_PORT_V2", "value" : "${port_node_v2}" },
      { "name" : "P2P_LISTEN_PORT_V2", "value" : "${port_node_v2}" },
      %{ endif }
      { "name" : "P2P_LISTEN_IP", "value" : "${listen_ip}" },
      { "name" : "JSON_CONSOLE", "value" : "true" },
      { "name" : "SUBNET_MAP", "value" : "${subnet_mapping}" }
    ],
    "secrets": [
      {
        "name": "KEYSTORE_PASSWORD",
        "valueFrom": "${keystore_password}"
      },
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
