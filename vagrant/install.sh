#!/bin/bash
HARBOR_IP="172.19.0.1"
API_GATEWAY_IP=$HARBOR_IP

set -e

# Install Ansible
python3 -m pip install --user ansible --no-warn-script-location
cd lima-kilo
pip3 install -r requirements.txt --no-warn-script-location

# so the base user can use kubectl and others
echo 'export PATH=$PATH:/home/vagrant/.local/bin:/home/vagrant/.toolforge-lima-kilo/bin:/home/vagrant/lima-kilo/helpers' >> ~/.bashrc
# if you want to deploy builds-* component from source, so it uses the right harbor ip
echo "export HARBOR_IP=$HARBOR_IP" >> ~/.bashrc

# so the toolforge clis can reach the local api-gateway
sudo mkdir -p /etc/toolforge
sudo bash -c "cat >/etc/toolforge/common.yaml <<EOC
api_gateway:
  url: https://$API_GATEWAY_IP:30003
EOC
"

# add vagrant specifics
mkdir -p /home/vagrant/.toolforge-lima-kilo
cat >/home/vagrant/.toolforge-lima-kilo/userconfig.yaml<<EOAC
lima_kilo_docker_addr: $HARBOR_IP
EOAC

# instal k9s for everyone in the VM
curl -L https://github.com/derailed/k9s/releases/download/v0.27.4/k9s_Linux_amd64.tar.gz | sudo tar xvzf - -C /usr/local/bin k9s