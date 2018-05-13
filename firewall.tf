resource "digitalocean_firewall" "kube-firewall" {
  name = "only-22"

  droplet_ids = ["${digitalocean_droplet.kube-master-server.id}"]

  inbound_rule = [
    {
      protocol           = "tcp"
      port_range         = "22"
      source_addresses   = ["2.24.166.73"]
    },
    {
      protocol           = "tcp"
      port_range         = "6443"
      source_addresses   = ["0.0.0.0/0"]
    }
  ]
	outbound_rule  = [
		{
			protocol                = "tcp"
			port_range              = "1-1024"
			destination_addresses   = ["0.0.0.0/0", "::/0"]
		},
		{
			protocol                = "udp"
			port_range              = "1-1024"
			destination_addresses   = ["0.0.0.0/0", "::/0"]
		}
]
}
