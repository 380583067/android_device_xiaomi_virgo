# SPDX-License-Identifier: Apache-2.0
LOCAL_PATH := $(call my-dir)
include $(CLEAR_VARS)
LOCAL_MODULE := libprotobuf-cpp-v29-virgo
LOCAL_MODULE_CLASS := SHARED_LIBRARIES
LOCAL_MODULE_SUFFIX := .so
LOCAL_MODULE_STEM := libprotobuf-cpp-v29
LOCAL_MULTILIB := 32
LOCAL_VENDOR_MODULE := true
LOCAL_PREBUILT_MODULE_FILE := hardware/lineage/compat/vndk/v29/arm/libprotobuf-cpp-lite.so
# Preserve the historical ABI; the blob has its original generic SONAME.
LOCAL_CHECK_ELF_FILES := false
LOCAL_STRIP_MODULE := false
include $(BUILD_PREBUILT)
