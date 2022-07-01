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
      { "name" : "P2P_ANNOUNCE_PORT", "value" : "${port_node}" },
      { "name" : "P2P_LISTEN_PORT", "value" : "${port_node}" },
      { "name" : "JSON_CONSOLE", "value" : "true"},
      { "name" : "SUBNET_MAP", "value" : "${subnet_mapping}" }
    ],
    "secrets": [
      {
        "name": "KEYSTORE_PASSWORD",
        "valueFrom": "${keystore_password}"
      },
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
