#!/bin/bash

set -e

# Install Ansible
python3 -m pip install --user ansible --no-warn-script-location
echo 'export PATH=$PATH:/home/vagrant/.local/bin' >> ~/.bashrc && source ~/.bashrc

if [ ! -d "lima-kilo" ]; then
  git clone https://gitlab.wikimedia.org/repos/cloud/toolforge/lima-kilo.git
else
  cd lima-kilo
  git fetch && git merge
  cd ..
fi

cd lima-kilo
pip3 install -r requirements.txt --no-warn-script-location
