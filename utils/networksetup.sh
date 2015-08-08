#!/bin/bash
#Assign existing hostname to $hostn
hostn=$(cat /etc/hostname)

#Display existing hostname
echo "Existing hostname is $hostn"

#Ask for new hostname $newhost
echo "Enter new hostname: "
read newhost

#Get New Ip
echo "Enter ip:"
read ip

#change hostname in /etc/hosts & /etc/hostname
sudo sed -i "s/$hostn/$newhost/g" /etc/hosts
sudo sed -i "s/$hostn/$newhost/g" /etc/hostname

#display new hostname
echo "Your new hostname is $newhost"

# ip address
echo -e "auto lo eth0\niface lo inet loopback\niface eth0 inet static\naddress $ip\nnetmask 255.255.255.0\ngateway 192.168.2.1" | sudo tee /etc/network/interfaces

#Press a key to reboot
read -s -n 1 -p "Press any key to reboot"
sudo reboot
