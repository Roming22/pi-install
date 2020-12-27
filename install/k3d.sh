#!/bin/bash
# Install k3d

install(){
    curl -s https://raw.githubusercontent.com/rancher/k3d/main/install.sh | bash
}

install
