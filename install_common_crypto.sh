#!/bin/sh

COMMON_CRYPTO_DIR="${SDKROOT}/usr/include/CommonCrypto"

# Check if module map exists (Xcode 10). If not, generate a dummy module.
if [ -f "${COMMON_CRYPTO_DIR}/module.modulemap" ]; then
    echo "CommonCrypto module map already exists, so skipping the rest of the script."
    exit 0
fi

FRAMEWORK_DIR="${BUILT_PRODUCTS_DIR}/CommonCrypto.framework"

# Skip if directory already exists.
if [ -d "${FRAMEWORK_DIR}" ]; then
    echo "${FRAMEWORK_DIR} already exists, so skipping the rest of the script."
    exit 0
fi

mkdir -p "${FRAMEWORK_DIR}/Modules"
cat <<EOF > "${FRAMEWORK_DIR}/Modules/module.modulemap"
module CommonCrypto [system] {
    header "${COMMON_CRYPTO_DIR}/CommonCrypto.h"
    export *
}
EOF

ln -sf "${COMMON_CRYPTO_DIR}" "${FRAMEWORK_DIR}/Headers"
