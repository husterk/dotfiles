#!/bin/bash
# Wrapper script to SSH to host with dynamic username

if [ -z "$HOST_USER" ]; then
    echo "Error: HOST_USER environment variable not set"
    exit 1
fi

exec ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$HOST_USER@host.docker.internal"
