#!/bin/bash
set -x
trap 'echo "FATAL: setup failed at line ${LINENO}" >> /tmp/progress.log; exit 1' ERR

echo "Adding wheel" > /root/post-run.log
usermod -aG wheel rhel

echo "Setup build host for day2 lab" > /tmp/progress.log
chmod 666 /tmp/progress.log

# Not on EUS image, this will fail
# Register and install git before library fetch
#dnf -y remove katello-ca-consumer-* 2>/dev/null || true
#subscription-manager clean
#subscription-manager register --activationkey="${ACTIVATION_KEY}" --org="${ORG_ID}" --force
#dnf install -y git podman skopeo

LIBDIR=/tmp/lab-lib-$$
git clone --depth=1 https://github.com/rhel-labs/lab-setup "${LIBDIR}"
. "${LIBDIR}/common.sh"


# Fetch setup files from the lab git repository
fetch_setup_files content/modules/ROOT/examples/flask
echo "Setup files staged" >> /tmp/progress.log

# Install grype
GRYPE_VERSION=v0.111.0
curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | \
  sh -s -- -b /usr/local/bin ${GRYPE_VERSION}
runuser -l rhel -c "grype db update"
echo "Grype installed" >> /tmp/progress.log

# Install cosign
COSIGN_VERSION=v2.6.3
curl -LO https://github.com/sigstore/cosign/releases/download/${COSIGN_VERSION}/cosign-linux-amd64
install -m 755 cosign-linux-amd64 /usr/local/bin/cosign
rm cosign-linux-amd64
echo "Cosign installed" >> /tmp/progress.log

# Install syft
SYFT_VERSION=v1.42.4
curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | \
  sh -s -- -b /usr/local/bin ${SYFT_VERSION}
echo "Syft installed" >> /tmp/progress.log

# Get a ZeroSSL cert and start the unauthenticated TLS registry, retrying the cert
# against transient ACME failures and confirming the registry responds before continuing
REGISTRY_HOST="registry-${GUID}.${DOMAIN}"
setup_ssl_registry "${REGISTRY_HOST}"

persist_env_var REGISTRY "${REGISTRY_HOST}"

# Pull base images for the Flask demo app
pull_public_images rhel "registry.access.redhat.com/hi/python:3.12-builder" \
  "registry.access.redhat.com/hi/python:3.12" \
  "registry.access.redhat.com/ubi10/ubi" \
  "ghcr.io/rhel-labs/rhhi-demo:ubi" \
  "ghcr.io/rhel-labs/rhhi-demo:hardened"
echo "Base images pulled" >> /tmp/progress.log

# Tag published demo images with short names, then remove the ghcr.io tags so only
# the short names appear in podman images output
runuser -l rhel -c "podman tag ghcr.io/rhel-labs/rhhi-demo:hardened rhhi-demo:hardened && \
  podman tag ghcr.io/rhel-labs/rhhi-demo:ubi rhhi-demo:ubi && \
  podman rmi ghcr.io/rhel-labs/rhhi-demo:hardened ghcr.io/rhel-labs/rhhi-demo:ubi"
echo "Demo images tagged" >> /tmp/progress.log

# Copy Flask app files from the lab repo
mkdir -p /home/rhel/flask
cp $SETUP_FILES/* /home/rhel/flask/
chown -R rhel:rhel /home/rhel/flask
echo "Flask app files copied" >> /tmp/progress.log

# Cleanup
cleanup_subscription
cleanup_tmpfiles
cleanup_certbot

echo "Setup complete" >> /tmp/progress.log
