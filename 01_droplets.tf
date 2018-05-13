#token cca8a6.850cab87e1a6b4da
# resource "digitalocean_droplet" "api-server" {
#  ;image  = "ubuntu-16-04-x64"
#  ;name   = "etcd-1"
#  ;region = "lon1"
#  ;size   = "1024mb"
#  ;private_networking = true
#G ;ssh_keys = [ "${var.ssh_fingerprint}" ]
#	;connection {
#		;user = "root"
#		;type = "ssh"
#		;private_key = "${file(var.pvt_key)}"
#		;timeout = "2m"
#	;}
#	;provisioner "file" {
#		;source = "etcd.service"
#		;destination = "/etc/systemd/system/etcd.service"
#	;}
#	;provisioner "remote-exec" {
#3		;inline =  [
#			;"sudo apt-get update",
#			;"useradd etcd",
#			;"curl -L  https://github.com/coreos/etcd/releases/download/v2.0.9/etcd-v2.0.9-linux-amd64.tar.gz -o etcd-v2.0.9-linux-amd64.tar.gz",
#			;"tar xzvf etcd-v2.0.9-linux-amd64.tar.gz",
#			;"cd etcd-v2.0.9-linux-amd64",
#			;"mkdir /var/etcd",
#			;"mv etcd /usr/bin",
#			;"mv etcdctl /usr/bin",
#			;"chown etcd: /var/etcd -R",
#			;"systemctl start etcd.service"
#		;]
#	;}
#;}
##end
data "external" "token" {
	program = ["bash" , "kube/gen.sh" ] 
}

resource "digitalocean_droplet" "kube-master-server" {
  image  = "ubuntu-16-04-x64"
  name   = "kube-master"
  region = "lon1"
  size   = "1gb"
  private_networking = "true"
  ssh_keys = [ "${var.ssh_fingerprint}" ]
	connection {
		user = "root"
		type = "ssh"
		private_key = "${file(var.pvt_key)}"
		timeout = "2m"
	}
	provisioner "file" {
		source = "kube/nginx-deployment.yaml"
		destination = "nginx-deployment.yaml"
	}
	provisioner "file" {
		source = "kube/svc-nginx.yaml"
		destination = "svc-nginx.yaml"
	}
	provisioner "remote-exec" {
		inline =  [
			"apt-get update && apt-get install -y curl apt-transport-https",
			"curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -",
			"echo deb https://download.docker.com/linux/$(lsb_release -si | tr '[:upper:]' '[:lower:]') $(lsb_release -cs) stable >  /etc/apt/sources.list.d/docker.list",
			"curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -",
			"echo deb http://apt.kubernetes.io/ kubernetes-xenial main > /etc/apt/sources.list.d/kubernetes.list",
			"apt-get update && apt-get install -y docker-ce=$(apt-cache madison docker-ce | grep 17.03 | head -1 | awk '{print $3}')  kubelet kubeadm kubectl kubernetes-cni",
			"kubeadm init --token ${data.external.token.result.token} --pod-network-cidr=10.244.0.0/16",
			"mkdir -p $HOME/.kube",
			"sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config",
			"sudo chown $(id -u):$(id -g) $HOME/.kube/config",
			"kubectl get ns",
			"kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml",
			"kubectl taint nodes kube-master node-role.kubernetes.io/master:NoSchedule-",
			"kubectl create -f nginx-deployment.yaml",
			"kubectl create -f svc-nginx.yaml"

		]
	}
}
resource "digitalocean_droplet" "kube-node" {
	count = 1
  image  = "ubuntu-16-04-x64"
  name   = "kube-node-${count.index}"
  region = "lon1"
  size   = "1gb"
  private_networking = "true"
  ssh_keys = [ "${var.ssh_fingerprint}" ]
	connection {
		user = "root"
		type = "ssh"
		private_key = "${file(var.pvt_key)}"
		timeout = "2m"
	}
	provisioner "remote-exec" {
		inline =  [
			"apt-get update && apt-get install -y curl apt-transport-https",
			"curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -",
			"echo deb https://download.docker.com/linux/$(lsb_release -si | tr '[:upper:]' '[:lower:]') $(lsb_release -cs) stable >  /etc/apt/sources.list.d/docker.list",
			"curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -",
			"echo deb http://apt.kubernetes.io/ kubernetes-xenial main > /etc/apt/sources.list.d/kubernetes.list",
			"apt-get update && apt-get install -y docker-ce=$(apt-cache madison docker-ce | grep 17.03 | head -1 | awk '{print $3}')  kubelet kubeadm kubectl kubernetes-cni",
      "kubeadm join --token ${data.external.token.result.token} ${digitalocean_droplet.kube-master-server.ipv4_address_private}:6443 --discovery-token-unsafe-skip-ca-verification"
			
		
		]
	}
}
