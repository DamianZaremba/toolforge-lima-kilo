#!/bin/bash

set -e

# Install Ansible
python3 -m pip install --user ansible --no-warn-script-location
cd lima-kilo
pip3 install -r requirements.txt --no-warn-script-location

# so the base user can use kubectl and others
echo 'export PATH=$PATH:/home/vagrant/.local/bin:/home/vagrant/.toolforge-lima-kilo/bin' >> ~/.bashrc

# so the toolforge clis can reach the local api-gateway
sudo mkdir /etc/toolforge
sudo bash -c "cat >/etc/toolforge/common.yaml <<EOC
api_gateway:
  url: https://172.19.0.1:30003
EOC
"

# instal k9s for everyone in the VM
curl -L https://github.com/derailed/k9s/releases/download/v0.27.4/k9s_Linux_amd64.tar.gz | sudo tar xvzf - -C /usr/local/bin k9s