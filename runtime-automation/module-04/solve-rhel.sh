#!/bin/sh
echo "Solving module-04: Push and Generate Keys" >> /tmp/progress.log

runuser -l rhel << 'RHEL_EOF'
. ~/.bashrc
podman tag rhhi-demo:hardened ${REGISTRY}/rhhi-demo:hardened
podman push --digestfile /home/rhel/image.digest ${REGISTRY}/rhhi-demo:hardened
export COSIGN_PASSWORD=""
cd ~
cosign generate-key-pair
skopeo copy --all --digestfile /home/rhel/python.digest docker://registry.access.redhat.com/hi/python:3.12 docker://${REGISTRY}/python:3.12
RHEL_EOF
echo "module-04 solve complete" >> /tmp/progress.log
