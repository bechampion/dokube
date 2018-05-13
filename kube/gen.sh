TOKEN=$(kubeadm token generate)
echo -e { \"token\" : \"$TOKEN\" }

