############################
### RKE Cluster
###########################
resource "rke_cluster" "rancher_server" {
  depends_on = [null_resource.wait_for_docker]

  dynamic nodes {
    for_each = aws_instance.rancher-master
    content {
      address          = nodes.value.public_ip
      internal_address = nodes.value.private_ip
      user             = "ubuntu"
      role             = ["controlplane", "etcd", "worker"]
      ssh_key          = tls_private_key.ssh.private_key_pem
    }
  }

  dynamic nodes {
    for_each = aws_instance.rancher-worker
    content {
      address          = nodes.value.public_ip
      internal_address = nodes.value.private_ip
      user             = "ubuntu"
      role             = ["worker"]
      ssh_key          = tls_private_key.ssh.private_key_pem
    }
  }

  cluster_name = "rancher-management"
  addons       = file("${path.module}/files/addons.yaml")
  kubernetes_version = local.kubernetes_version

  services_etcd {
    # for etcd snapshots
    backup_config {
      interval_hours = 12
      retention      = 6
      # s3 specific parameters
      #s3_backup_config {
      #  bucket_name = aws_s3_bucket.etcd-backups.id
      #  region      = "us-east-1"
      #  endpoint    = "s3.us-east-1.amazonaws.com"
      #}
    }
  }
}

resource "local_file" "kube_cluster_yaml" {
  filename = "${path.root}/outputs/kube_config_cluster.yml"
  content  = rke_cluster.rancher_server.kube_config_yaml
}
