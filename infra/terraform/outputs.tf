output "instance_public_ip" {
  description = "Elastic IP of the lab host. Point your /etc/hosts or DNS 'lab.local' entries at this."
  value       = aws_eip.lab_eip.public_ip
}

output "ssh_command" {
  value = "ssh -i ~/.ssh/devops_lab_key ubuntu@${aws_eip.lab_eip.public_ip}"
}

output "app_urls" {
  value = {
    edge_https        = "https://${aws_eip.lab_eip.public_ip}/  (add -k, or map lab.local in /etc/hosts, since cert is self-signed)"
    python_url_routed = "https://${aws_eip.lab_eip.public_ip}/python/"
    node_url_routed   = "https://${aws_eip.lab_eip.public_ip}/node/"
    java_url_routed   = "https://${aws_eip.lab_eip.public_ip}/java/"
    grafana           = "http://${aws_eip.lab_eip.public_ip}:3001  (admin/admin)"
    prometheus        = "http://${aws_eip.lab_eip.public_ip}:9090"
  }
}
