#!/bin/bash
set -e

# Install Ansible
python3 -m pip install --user ansible --no-warn-script-location
cd lima-kilo
pip3 install -r requirements.txt --no-warn-script-location