#
# Copyright (C) 2015 The CyanogenMod Project
# Copyright (C) 2017 The LineageOS Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
-include device/xiaomi/msm8974-common/BoardConfigCommon.mk

# Lineage launches a separate kernel make with all online CPUs by default.
# Cap the nested kernel build so it follows the requested j8 build limit.
TARGET_KERNEL_ADDITIONAL_FLAGS += -j8

DEVICE_PATH := device/xiaomi/virgo

# Assertions
TARGET_OTA_ASSERT_DEVICE := virgo,cancro

# Display
TARGET_SCREEN_DENSITY := 350

# The stock virgo rawprogram layout reserves exactly 32768 sectors (16 MiB)
# for recovery. Keep the build guard at that physical partition size so the
# generated image can never silently overwrite the neighboring partition.
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 16777216

# The planned virgo GPT layout allocates 3072 MiB (3 GiB) to system. Keep the
# Android image-size limit aligned with that repartitioned layout so the full
# Android 14 product set fits without dropping device or framework features.
BOARD_SYSTEMIMAGE_PARTITION_SIZE := 3221225472

# Recovery uses its own resource density; this does not change Android's
# 400-dpi display setting. The hdpi recovery assets keep the full recovery UI
# while reducing its PNG payload enough for virgo's fixed 16-MiB partition.
TARGET_RECOVERY_DENSITY := hdpi

# EROFS is read-only, so recovery does not need the image-creation utility.
# Keep mkfs.erofs in Android userspace and on the build host, but omit its
# duplicate recovery copy to leave OTA headroom in virgo's 16-MiB partition.
BOARD_RECOVERY_IMAGE_PREPARE = rm -f $(TARGET_RECOVERY_ROOT_OUT)/system/bin/mkfs.erofs

# Dual sim solution in virgo
CONFIG_EAP_PROXY_DUAL_SIM := true

# HIDL
DEVICE_MANIFEST_FILE += $(DEVICE_PATH)/manifest.xml

# FCM 5 in this Android 14 port does not enumerate several legacy HIDL
# services still shipped by virgo. Add them as a product-scoped framework
# compatibility extension so VINTF checks the real HALs without editing AOSP
# framework matrices or removing the services from the device manifest.
DEVICE_PRODUCT_COMPATIBILITY_MATRIX_FILE += $(DEVICE_PATH)/compatibility_matrix_product.xml

# ReleaseTools
TARGET_RELEASETOOLS_EXTENSIONS := $(DEVICE_PATH)/releasetools

# Vendor Init
TARGET_INIT_VENDOR_LIB      := libinit_virgo
TARGET_LIBINIT_DEFINES_FILE := $(DEVICE_PATH)/init/init_virgo.cpp

-include vendor/xiaomi/virgo/BoardConfigVendor.mk

# This device uses a legacy Linux 3.4 kernel that predates the Clang target
# configuration expected by the Android 14 kernel build wrapper. Build this
# kernel with the bundled ARM GCC 4.9 toolchain; Android userspace stays Clang.
TARGET_KERNEL_CLANG_COMPILE := false
# Use the real GCC driver directly; its legacy wrapper requires /usr/bin/python.
KERNEL_CC = CC=$(BUILD_TOP)/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin/real-arm-linux-androideabi-gcc

#BOARD_HAVE_QCOM_FM := true
# WCNSS integrates FM firmware; there is no external patch downloader.
#TARGET_QCOM_NO_FM_FIRMWARE := true

# Virgo KCAL display-mode service.
BOARD_VENDOR_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy
