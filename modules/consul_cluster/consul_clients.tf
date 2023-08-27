# creates Consul autoscaling group for clients
resource "aws_autoscaling_group" "consul_clients" {
  count = var.consul_clients > 0 ? 1 : 0

  name                      = aws_launch_configuration.consul_clients.name
  launch_configuration      = aws_launch_configuration.consul_clients.name
  availability_zones        = data.aws_availability_zones.available.names
  min_size                  = var.consul_clients
  max_size                  = var.consul_clients
  desired_capacity          = var.consul_clients
  wait_for_capacity_timeout = "480s"
  health_check_grace_period = 15
  health_check_type         = "EC2"

  tag {
    key                 = "Name"
    value               = "${var.name_prefix}-consul-client"
    propagate_at_launch = true
  }
  tag {
    key                 = "Cluster-Version"
    value               = var.consul_cluster_version
    propagate_at_launch = true
  }
  tag {
    key                 = "Environment-Name"
    value               = "${var.name_prefix}-consul"
    propagate_at_launch = true
  }
  tag {
    key                 = "owner"
    value               = var.owner
    propagate_at_launch = true
  }

  depends_on = [aws_autoscaling_group.consul_servers]

  lifecycle {
    create_before_destroy = true
  }
}

# provides a resource for a new autoscaling group launch configuration
resource "aws_launch_configuration" "consul_clients" {
  name            = "${random_id.environment_name.hex}-consul-clients-${var.consul_cluster_version}"
  image_id        = data.aws_ami.ubuntu.id
  instance_type   = var.instance_type
  key_name        = var.key_name
  security_groups = [aws_security_group.consul.id]
  user_data = templatefile("${path.module}/scripts/install_hashitools_consul_client.sh.tpl",
    {
      ami              = data.aws_ami.ubuntu.id,
      environment_name = "${var.name_prefix}-consul",
      consul_version   = var.consul_version,
      datacenter       = data.aws_region.current.name,
      gossip_key       = random_id.consul_gossip_encryption_key.b64_std,
  })
  associate_public_ip_address = var.public_ip
  iam_instance_profile        = aws_iam_instance_profile.instance_profile.name
  root_block_device {
    volume_size = 10
  }

  lifecycle {
    create_before_destroy = true
  }
}
