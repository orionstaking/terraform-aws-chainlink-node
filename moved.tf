# Dropped count after P2P V1 support was removed. These keep the existing
# listener, target group, and its name suffix instead of creating new ones.
moved {
  from = random_string.alb_prefix_node_v2[0]
  to   = random_string.alb_prefix_node_v2
}

moved {
  from = aws_lb_target_group.node_v2[0]
  to   = aws_lb_target_group.node_v2
}

moved {
  from = aws_lb_listener.node_v2[0]
  to   = aws_lb_listener.node_v2
}

moved {
  from = aws_security_group_rule.ingress_allow_node_v2[0]
  to   = aws_security_group_rule.ingress_allow_node_v2
}

# The validate task was created with count. This keeps that task definition.
moved {
  from = aws_ecs_task_definition.validate[0]
  to   = aws_ecs_task_definition.validate
}
