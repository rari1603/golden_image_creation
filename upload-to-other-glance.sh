#!/bin/bash
set -e

# Set environment for target OpenStack (destination)
export OS_AUTH_URL="https://100.65.247.153:13000"
export OS_USERNAME="admin"
export OS_PASSWORD="eoZ37jP3T9DP4lePjUgZ0CwNQ"
export OS_PROJECT_NAME="admin"
export OS_USER_DOMAIN_NAME="Default"
export OS_PROJECT_DOMAIN_NAME="Default"
export OS_COMPUTE_API_VERSION=2.88
export OS_IMAGE_API_VERSION=2
export OS_INSECURE=true

# Upload the image
IMAGE_FILE=$1
IMAGE_NAME=$2

if [[ -z "$IMAGE_FILE" || -z "$IMAGE_NAME" ]]; then
  echo "Usage: $0 <image_file> <image_name>"
  exit 1
fi

echo "Uploading $IMAGE_FILE to target OpenStack as $IMAGE_NAME..."
openstack image create "$IMAGE_NAME" --disk-format qcow2 --container-format bare --file "$IMAGE_FILE" --public
