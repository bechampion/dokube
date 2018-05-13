output "kube-master-server address" {
    value = "${digitalocean_droplet.kube-master-server.ipv4_address}"
}
