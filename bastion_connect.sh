#!/bin/bash

if [[ -z "$KEY_PATH" ]]; then
  echo "KEY_PATH env var is expected"
  exit 5
fi

if [[ -z "$1" ]]; then
  echo "Please provide bastion IP address"
  exit 5
fi

BASTION_IP=$1
TARGET_IP=$2

if [[ -z "$TARGET_IP" ]]; then
  # Case 2: connect directly to bastion
  ssh -i "$KEY_PATH" -o StrictHostKeyChecking=no ubuntu@$BASTION_IP
else
  # Case 1/3: connect to target instance via bastion
  shift 2
  ssh -i "$KEY_PATH" -o StrictHostKeyChecking=no -o ProxyCommand="ssh -i $KEY_PATH -o StrictHostKeyChecking=no -W %h:%p ubuntu@$BASTION_IP" ubuntu@$TARGET_IP "$@"
fi
