#!/bin/sh
echo "Solving module-05: Sign and Verify" >> /tmp/progress.log

# Load REGISTRY from bashrc
. /home/rhel/.bashrc 2>/dev/null || true

IMAGE_DIGEST=$(cat /home/rhel/image.digest 2>/dev/null)

# Sign the image using the digest and local key
export COSIGN_PASSWORD=""
/usr/local/bin/cosign sign --tlog-upload=false \
  --yes --key /home/rhel/cosign.key \
  ${REGISTRY}/rhhi-demo@${IMAGE_DIGEST}

# Verify the signature with the public key
/usr/local/bin/cosign verify --insecure-ignore-tlog=true \
  --key /home/rhel/cosign.pub \
  ${REGISTRY}/rhhi-demo@${IMAGE_DIGEST}

echo "module-03 solve complete" >> /tmp/progress.log
