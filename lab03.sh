#!/bin/bashx


# Define remote server details

SERVER1_USER="remoteadmin"

SERVER1_HOST="server1-mgmt"

SERVER2_USER="remoteadmin"

SERVER2_HOST="server2-mgmt"


# Location to copy the script on the remote server

REMOTE_SCRIPT_PATH="/root/configure-host.sh"


# Verbose mode flag

VERBOSE=""


# Check for verbose flag in command-line arguments

for arg in "$@"

do

  if [ "$arg" == "-verbose" ]; then

    VERBOSE="-verbose"

    echo "Verbose mode enabled"

  fi

done


# Function to transfer and execute the configure-host.sh script

deploy_script() {

  local user=$1

  local host=$2

  local name=$3

  local ip=$4

  local hostentry_name=$5

  local hostentry_ip=$6


  # Securely copy the script to the server

  scp configure-host.sh ${user}@${host}:${REMOTE_SCRIPT_PATH}

  if [ $? -ne 0 ]; then

    echo "Error copying configure-host.sh to ${host}"

    exit 1

  fi


  # Execute the script remotely with specified options

  ssh ${user}@${host} "bash ${REMOTE_SCRIPT_PATH} ${VERBOSE} -name ${name} -ip ${ip} -hostentry ${hostentry_name} ${hostentry_ip}"

  if [ $? -ne 0 ]; then

    echo "Error executing configure-host.sh on ${host}"

    exit 1

  fi

}


# Deploy to server1

deploy_script $SERVER1_USER $SERVER1_HOST "loghost" "192.168.16.3" "webhost" "192.168.16.4"


# Deploy to server2

deploy_script $SERVER2_USER $SERVER2_HOST "webhost" "192.168.16.4" "loghost" "192.168.16.3"


# Additionally, update the local /etc/hosts file

./configure-host.sh $VERBOSE -hostentry "loghost" "192.168.16.3"

./configure-host.sh $VERBOSE -hostentry "webhost" "192.168.16.4"


echo "Deployment complete."
