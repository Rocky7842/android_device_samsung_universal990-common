#!/bin/bash
# Copyright (C) 2023 The LineageOS Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

ANDROID_ROOT="${MY_DIR}/../../.."

HELPER="${ANDROID_ROOT}/tools/extract-utils/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Unable to find helper script at ${HELPER}"
    exit 1
fi
source "${HELPER}"

# Initialize the helper for common
setup_vendor "${DEVICE_COMMON}" "${VENDOR}" "${ANDROID_ROOT}" true

# Warning headers and guards
write_headers "x1s x1slte z3s"

# The standard common blobs
write_makefiles "${MY_DIR}/proprietary-files.txt" true

###################################################################################################
# CUSTOM PART START                                                                               #
###################################################################################################
OUTDIR=vendor/$VENDOR/$DEVICE_COMMON
(cat << EOF) >> $ANDROID_ROOT/$OUTDIR/Android.mk
include \$(CLEAR_VARS)

EGL_LIBS := libOpenCL.so libOpenCL.so.1 libOpenCL.so.1.1

EGL_32_SYMLINKS := \$(addprefix \$(TARGET_OUT_VENDOR)/lib/,\$(EGL_LIBS))
\$(EGL_32_SYMLINKS): \$(LOCAL_INSTALLED_MODULE)
	@echo "Symlink: EGL 32-bit lib: \$@"
	@mkdir -p \$(dir \$@)
	@rm -rf \$@
	\$(hide) ln -sf /vendor/lib/egl/libGLES_mali.so \$@

EGL_64_SYMLINKS := \$(addprefix \$(TARGET_OUT_VENDOR)/lib64/,\$(EGL_LIBS))
\$(EGL_64_SYMLINKS): \$(LOCAL_INSTALLED_MODULE)
	@echo "Symlink: EGL 64-bit lib : \$@"
	@mkdir -p \$(dir \$@)
	@rm -rf \$@
	\$(hide) ln -sf /vendor/lib64/egl/libGLES_mali.so \$@

ALL_DEFAULT_INSTALLED_MODULES += \$(EGL_32_SYMLINKS) \$(EGL_64_SYMLINKS)

EOF
###################################################################################################
# CUSTOM PART END                                                                                 #
###################################################################################################

# Finish
write_footers

if [ -s "${MY_DIR}/../${DEVICE}/proprietary-files.txt" ]; then
    # Reinitialize the helper for device
    setup_vendor "${DEVICE}" "${VENDOR}" "${ANDROID_ROOT}" false

    # Warning headers and guards
    write_headers

    # The standard device blobs
    write_makefiles "${MY_DIR}/../${DEVICE}/proprietary-files.txt" true

    # Finish
    write_footers
fi
