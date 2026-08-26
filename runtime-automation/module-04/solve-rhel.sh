#!/bin/sh
echo "Solving module-04: Push and Generate Keys" >> /tmp/progress.log

runuser -l rhel << 'RHEL_EOF'
. ~/.bashrc
podman tag rhhi-demo:hardened ${REGISTRY}/rhhi-demo:hardened
podman push --digestfile /home/rhel/image.digest ${REGISTRY}/rhhi-demo:hardened
export COSIGN_PASSWORD=""
cd ~
cosign generate-key-pair
# runuser -l has no XDG_RUNTIME_DIR, so skopeo's default authfile path is unreadable.
# Point it at a readable empty authfile (registry is unauthenticated).
mkdir -p /home/rhel/.config/containers
echo '{}' > /home/rhel/.config/containers/auth.json
export REGISTRY_AUTH_FILE=/home/rhel/.config/containers/auth.json
skopeo copy --all --remove-signatures --digestfile /home/rhel/python.digest docker://registry.access.redhat.com/hi/python:3.12 docker://${REGISTRY}/python:3.12
RHEL_EOF
echo "module-04 solve complete" >> /tmp/progress.log
