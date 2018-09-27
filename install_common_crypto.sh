#!/bin/sh

FRAMEWORK_DIR="${BUILT_PRODUCTS_DIR}/CommonCrypto.framework"

# Check if module map exists (Xcode 10). If not, generate a dummy module.

# Skip if directory already exists.
if [ -d "${FRAMEWORK_DIR}" ]; then
    echo "${FRAMEWORK_DIR} already exists, so skipping the rest of the script."
    exit 0
fi

mkdir -p "${FRAMEWORK_DIR}/Modules"
cat <<EOF > "${FRAMEWORK_DIR}/Modules/module.modulemap"
module CommonCrypto [system] {
    header "${SDKROOT}/usr/include/CommonCrypto/CommonCrypto.h"
    export *
}
EOF

ln -sf "${SDKROOT}/usr/include/CommonCrypto" "${FRAMEWORK_DIR}/Headers"
