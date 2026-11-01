# Copyright (C) 2014 The CyanogenMod Project
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

# Inherit from those products. Most specific first.
# product_launched_with_k.mk imports runtime_libart.mk, so set this before
# that first inheritance: ENG keeps its debuggable/root properties while
# using the release ART APEX that is compatible with the device's old vendor
# runtime and 32-bit userspace.
PRODUCT_ART_TARGET_INCLUDE_DEBUG_BUILD := false

$(call inherit-product, $(SRC_TARGET_DIR)/product/product_launched_with_k.mk)

# Inherit from virgo device
$(call inherit-product, device/xiaomi/virgo/virgo.mk)

# vendor/lineage reads this while loading its common product config. Set it
# first so only the optional recovery editor is omitted on virgo's 16-MiB
# recovery partition; normal system nano, recovery UI, and ADB stay enabled.
TARGET_DISABLE_NANO_RECOVERY := true

# Inherit some common Mokee stuff.
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)

# The ENG build sets ro.adb.secure=0. Android 14's property post-processing
# then adds adb to persist.sys.usb.config automatically; leave the Qualcomm
# USB init rules intact so their normal function composition is preserved.

PRODUCT_NAME := lineage_virgo
PRODUCT_DEVICE := virgo
PRODUCT_BRAND := Xiaomi
PRODUCT_MANUFACTURER := Xiaomi
PRODUCT_MODEL := MI NOTE LTE

PRODUCT_GMS_CLIENTID_BASE := android-xiaomi

TARGET_CONTINUOUS_SPLASH_ENABLED := true
