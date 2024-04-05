#!/bin/bash


# Function to log changes

log_change() {

  local message=$1

  logger -p user.notice -t configure-host "$message"

  [ "$VERBOSE" = true ] && echo "$message"

}


# Function to update hostname

update_hostname() {

  local desired_name=$1

  local current_name=$(hostname)


  if [ "$desired_name" != "$current_name" ]; then

    echo "$desired_name" > /etc/hostname

    hostname "$desired_name"

    log_change "Hostname changed from $current_name to $desired_name"

  elif [ "$VERBOSE" = true ]; then

    log_change "Hostname is already set to $desired_name"

  fi

}


# Function to update IP address

update_ip_address() {

  local desired_ip=$1

  local interface=$(ip route | grep default | sed -e "s/^.*dev.//" -e "s/.proto.*//")


  # Assuming netplan is used for network configuration. Adjust for your network manager if different.

  local netplan_file=$(ls /etc/netplan/*.yaml | head -n 1)


  if [ -z "$netplan_file" ] || [ -z "$interface" ]; then

    log_change "Error: Unable to find netplan configuration or network interface."

    return 1

  fi


  # Check current IP address

  local current_ip=$(ip -4 addr show $interface | grep -oP '(?<=inet\s)\d+(\.\d+){3}')

  if [ "$desired_ip" != "$current_ip" ]; then

    sed -i "s/$current_ip/$desired_ip/g" "$netplan_file"

    netplan apply

    log_change "IP address for $interface changed from $current_ip to $desired_ip"

  elif [ "$VERBOSE" = true ]; then

    log_change "IP address for $interface is already set to $desired_ip"

  fi

}


# Function to update /etc/hosts entry

update_hosts_entry() {

  local name=$1

  local ip=$2

  if ! grep -q "$ip $name" /etc/hosts; then

    echo "$ip $name" >> /etc/hosts

    log_change "Added $name ($ip) to /etc/hosts"

  elif [ "$VERBOSE" = true ]; then

    log_change "$name ($ip) is already in /etc/hosts"

  fi

}


# Default verbose mode to false

VERBOSE=false


# Process command line arguments

while [[ "$#" -gt 0 ]]; do

  case $1 in

    -verbose) VERBOSE=true ;;

    -name) desired_name="$2"; shift ;;

    -ip) desired_ip="$2"; shift ;;

    -hostentry) hostentry_name="$2"; hostentry_ip="$3"; shift 2 ;;

    *) echo "Unknown parameter passed: $1"; exit 1 ;;

  esac

  shift

done


# Ignoring TERM, HUP, INT signals

trap '' TERM HUP INT


# Apply configurations

[ ! -z "$desired_name" ] && update_hostname "$desired_name"

[ ! -z "$desired_ip" ] && update_ip_address "$desired_ip"

[ ! -z "$hostentry_name" ] && [ ! -z "$hostentry_ip" ] && update_hosts_entry "$hostentry_name" "$hostentry_ip"
