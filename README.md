# pi-install

Automate the creation of a bootable USB/SD-Card drive for a Raspberry Pi 4, with some flavor of Kubernetes baked in.

## Usage

* Run `./configure` to enter the information of the new server. The ssh key is taken from `~/.ssh/id_rsa.pub`.
* Run `sudo ./make.sh`, plug the drive and follow the instructions.
* Plug the drive in your Rapsberry Pi and power it on. The device should NOT be used until it has completed the first boot setup and rebooted. 
* You can monitor the first boot with `ssh default_user@ip tail -f /var/log/cloud-init-output.log`.

