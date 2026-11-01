DEVICE_PATH := device/xiaomi/virgo

$(call inherit-product, device/xiaomi/msm8974-common/msm8974-common.mk)
$(call inherit-product, vendor/xiaomi/virgo/virgo-vendor.mk)

# Overlays
DEVICE_PACKAGE_OVERLAYS += $(DEVICE_PATH)/overlay

# System properties
-include $(DEVICE_PATH)/system_prop.mk

# Audio
PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/audio/audio_platform_info.xml:system/vendor/etc/audio_platform_info.xml \
    $(DEVICE_PATH)/audio/diracmobile.config:system/vendor/etc/diracmobile.config \
    $(DEVICE_PATH)/audio/mixer_paths.xml:system/vendor/etc/mixer_paths.xml \
    $(DEVICE_PATH)/audio/acdb/MTP/MTP_Bluetooth_cal.acdb:system/etc/acdbdata/MTP/MTP_Bluetooth_cal.acdb \
    $(DEVICE_PATH)/audio/acdb/MTP/MTP_General_cal.acdb:system/etc/acdbdata/MTP/MTP_General_cal.acdb \
    $(DEVICE_PATH)/audio/acdb/MTP/MTP_Global_cal.acdb:system/etc/acdbdata/MTP/MTP_Global_cal.acdb \
    $(DEVICE_PATH)/audio/acdb/MTP/MTP_Handset_cal.acdb:system/etc/acdbdata/MTP/MTP_Handset_cal.acdb \
    $(DEVICE_PATH)/audio/acdb/MTP/MTP_Hdmi_cal.acdb:system/etc/acdbdata/MTP/MTP_Hdmi_cal.acdb \
    $(DEVICE_PATH)/audio/acdb/MTP/MTP_Headset_cal.acdb:system/etc/acdbdata/MTP/MTP_Headset_cal.acdb \
    $(DEVICE_PATH)/audio/acdb/MTP/MTP_Speaker_cal.acdb:system/etc/acdbdata/MTP/MTP_Speaker_cal.acdb

# KeyLayout
PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/keylayout/cyttsp_button.kl:system/vendor/usr/keylayout/cyttsp_button.kl \
    $(DEVICE_PATH)/keylayout/fts.kl:system/vendor/usr/keylayout/fts.kl \
    $(DEVICE_PATH)/keylayout/synaptics_dsx.kl:system/vendor/usr/keylayout/synaptics_dsx.kl    

# Ramdisk
PRODUCT_PACKAGES += \
    ueventd.qcom.rc

# Restore USB debugging after persistent properties load so an older /data
# configuration cannot disable ADB before the SetupWizard is available.
ifeq ($(TARGET_BUILD_VARIANT),eng)
PRODUCT_COPY_FILES += \
    device/xiaomi/virgo/rootdir/etc/init.virgo.eng.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/init.virgo.eng.rc
endif

# Sensor
PRODUCT_PACKAGES += \
    sensors.msm8974

# Touch
PRODUCT_PACKAGES += \
    vendor.lineage.touch@1.0-service.virgo

# WiFi
PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/wifi/WCNSS_qcom_wlan_nv.bin:system/vendor/firmware/wlan/prima/WCNSS_qcom_wlan_nv.bin \
    $(DEVICE_PATH)/wifi/WCNSS_qcom_wlan_nv_x5gbl.bin:system/vendor/firmware/wlan/prima/WCNSS_qcom_wlan_nv_x5gbl.bin

# Network validation URLs and the WCNSS FM application.
PRODUCT_PACKAGES += \
    VirgoNetworkStackOverlay

# The legacy Widevine engine needs protobuf v29, isolated from framework protobuf.
PRODUCT_PACKAGES += libprotobuf-cpp-v29-virgo

# Start and stop the in-kernel WCNSS FM SMD transport with the JNI lifecycle.
PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/rootdir/etc/init.virgo.fm.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/init.virgo.fm.rc

# Expose KCAL saturation presets through the LiveDisplay color-profile UI.
PRODUCT_PACKAGES += vendor.lineage.livedisplay@2.0-service.virgo

# Report this kernel's mixed thermal units and stable per-sensor identities.
PRODUCT_PACKAGES += thermal.msm8974
