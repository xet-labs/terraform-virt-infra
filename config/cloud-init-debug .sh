# clean state (necessary if configuring a base image and if it was booted)
sudo cloud-init clean --logs
sudo rm -rf /var/lib/cloud/*
sudo shutdown -h now


sudo cloud-init status --long
# check data source
sudo cloud-init query ds

# reinit
sudo cloud-init init
sudo cloud-init modules --mode=config
sudo cloud-init modules --mode=final
# view logs
sudo tail -f /var/log/cloud-init.log /var/log/cloud-init-output.log
# sudo tail -f /var/log/cloud-init.log
# sudo tail -f /var/log/cloud-init-output.log


 
# Purge Remove cloud-init package and state
sudo apt remove --purge -y cloud-init
sudo apt autoremove -y
sudo rm -rf /etc/cloud/ /var/lib/cloud/ /var/log/cloud-init*

# (Optional) Reset network config if cloud-init had modified it
sudo rm -f /etc/netplan/50-cloud-init.yaml