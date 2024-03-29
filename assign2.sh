#!/bin/bash


# Function to print section headers

print_section_header() {

  echo "=================================================================="

  echo " $1"

  echo "=================================================================="

}


# Function to print sub-section headers

print_sub_section_header() {

  echo "------------------------------------------------------------------"

  echo " $1"

  echo "------------------------------------------------------------------"

}


# Function to print messages with formatting

print_message() {

  echo "* $1"

}


# Function to print errors with formatting

print_error() {

  echo "[ERROR] $1" >&2

}


# Function to check if a package is installed

package_installed() {

  dpkg -l "$1" &> /dev/null

}


# Function to install packages if not already installed

install_package() {

  if ! package_installed "$1"; then

    print_sub_section_header "Installing $1"

    apt-get update && apt-get install -y "$1"

  fi

}


# Function to configure network interface

configure_network_interface() {

  print_section_header "Configuring Network Interface"

  # Check if network interface configuration file exists

  if [[ -f /etc/netplan/50-cloud-init.yaml ]]; then

    print_message "Updating netplan configuration file"

    # Update netplan configuration

    cat << EOF > /etc/netplan/50-cloud-init.yaml

network:

  version: 2

  ethernets:

    eth0:

      addresses: [10.87.193.200/24]

      routes:

       - to: default

        via: 10.87.193.1

      nameservers:

        addresses: [10.87.193.1]

        search: [home.arpa, localdomain]

    eth1:

      addresses: [192.168.100.200/24]

    eth2:

      addresses: [172.16.1.200/24]

EOF

    # Apply netplan configuration

    netplan apply

    print_message "Network interface configured successfully"

  else

    print_error "Netplan configuration file not found"

  fi

}



# Function to update /etc/hosts file

update_hosts_file() {

  print_section_header "Updating /etc/hosts file"

  # Check if server1 entry already exists

  if grep -q "192.168.100.200\s*server1" /etc/hosts; then

    print_message "/etc/hosts already updated for server1"

  else

    print_message "Adding server1 entry to /etc/hosts"

    echo "192.168.100.200 server1" >> /etc/hosts

  fi

}


# Function to configure firewall

configure_firewall() {

  print_section_header "Configuring Firewall (UFW)"

  # Enable firewall

  echo "yes" | sudo ufw enable

  # Allow SSH on mgmt network

  ufw allow ssh

  # Allow HTTP on both interfaces

  ufw allow http

  # Allow web proxy on both interfaces

  ufw allow 3128

  print_message "Firewall configured successfully"

}


# Function to create user accounts

create_user_accounts() {

  print_section_header "Creating User Accounts"

  # Define user list

  users=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")

  # Loop through users

  for user in "${users[@]}"; do

    print_sub_section_header "Creating user: $user"

    # Check if user already exists

    if id "$user" &> /dev/null; then

      print_message "User $user already exists"

    else

      # Create user with home directory and bash shell

      useradd -m -s /bin/bash "$user"

      # Generate SSH keys if not already generated

sshpubKey="sh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI $user@server1"

      if [[ ! -f /home/$user/.ssh/id_rsa ]]; then

        sudo -u "$user" ssh-keygen -t rsa -N "" -f /home/$user/.ssh/id_rsa -q

      fi


      # Add public keys to authorized_keys file

      echo "$sshpubKey" >> /home/$user/.ssh/authorized_keys

      print_message "User $user created successfully"

    fi

  done

}


# Main function

main() {

  configure_network_interface

  update_hosts_file

  install_package "apache2"

  install_package "squid"

  configure_firewall

  create_user_accounts

}


# Execute main function

main


# End of script
