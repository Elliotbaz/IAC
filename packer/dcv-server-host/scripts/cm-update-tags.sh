#!/bin/bash

# Get the instance ID from the instance metadata
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

# Get the region from the instance metadata
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)

# Get the container ID running on port 8443
CONTAINER_ID=$(docker ps --filter "publish=8443" --format "{{.ID}}" | head -n1)

if [ -z "$CONTAINER_ID" ]; then
    echo "No container found running on port 8443"
    # If no container is found, remove the tag
    aws ec2 delete-tags \
        --region $REGION \
        --resources $INSTANCE_ID \
        --tags Key=8443-container
else
    echo "Container ID: $CONTAINER_ID"
    # Update the EC2 instance tag
    aws ec2 create-tags \
        --region $REGION \
        --resources $INSTANCE_ID \
        --tags Key=8443-container,Value=$CONTAINER_ID
fi