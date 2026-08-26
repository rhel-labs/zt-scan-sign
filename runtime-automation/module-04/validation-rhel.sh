#!/bin/sh
echo "Validating module-04" >> /tmp/progress.log

if [ ! -f /home/rhel/cosign.key ] || [ ! -f /home/rhel/cosign.pub ]; then
    echo "FAIL: cosign key pair not found" >> /tmp/progress.log
    echo "HINT: Did you run cosign generate-key-pair to create your signing keys?" >> /tmp/progress.log
    exit 1
fi

. /home/rhel/.bashrc 2>/dev/null || true

if ! runuser -u rhel -- podman image exists ${REGISTRY}/rhhi-demo:hardened 2>/dev/null; then
    echo "FAIL: rhhi-demo:hardened not found in local registry storage" >> /tmp/progress.log
    echo "HINT: Did you tag and push the image to ${REGISTRY} as shown in the module?" >> /tmp/progress.log
    exit 1
fi

if [ ! -f /home/rhel/image.digest ]; then
    echo "FAIL: image.digest file not found" >> /tmp/progress.log
    echo "HINT: Push with 'podman push --digestfile ~/image.digest ${REGISTRY}/rhhi-demo:hardened' to capture the digest" >> /tmp/progress.log
    exit 1
fi

if [ ! -f /home/rhel/python.digest ]; then
    echo "FAIL: python.digest not found (mirrored vendor image digest)" >> /tmp/progress.log
    echo "HINT: Mirror the vendor image with 'skopeo copy --all --digestfile ~/python.digest ...' as shown in the module" >> /tmp/progress.log
    exit 1
fi

if ! runuser -l rhel -c "skopeo inspect --raw docker://${REGISTRY}/python:3.12" >/dev/null 2>&1; then
    echo "FAIL: mirrored python:3.12 not found in ${REGISTRY}" >> /tmp/progress.log
    echo "HINT: Mirror the vendor image into your local registry with skopeo copy" >> /tmp/progress.log
    exit 1
fi

echo "PASS: cosign key pair exists, image pushed, digest captured, vendor image mirrored" >> /tmp/progress.log
exit 0
