#!/bin/sh
echo "Solving module-04: Push and Generate Keys" >> /tmp/progress.log

runuser -l rhel << 'RHEL_EOF'
. ~/.bashrc
podman tag rhhi-demo:v1 ${REGISTRY}/rhhi-demo:v1
podman push --digestfile /home/rhel/image.digest ${REGISTRY}/rhhi-demo:v1
export COSIGN_PASSWORD=""
cd ~
cosign generate-key-pair
RHEL_EOF
echo "module-02 solve complete" >> /tmp/progress.log
