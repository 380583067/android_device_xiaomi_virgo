PRODUCT_PROPERTY_OVERRIDES += \
    ro.telephony.ril.config=simactivation \
    media.aac_51_output_enabled=true \
    persist.vendor.audio.fluence.speaker=true \
    persist.vendor.audio.speaker.prot.enable=true \
    qcom.hw.aac.encoder=false \
    vendor.audio.tunnel.encode=false \
    persist.audio.init_volume_index=1 \
    vendor.audio.offload.buffer.size.kb=32 \
    audio.offload.video=true \
    vendor.audio.offload.gapless.enabled=false \
    audio.offload.disable=1 \
    audio.offload.pcm.enable=true \
    audio.offload.pcm.24bit.enable=true \
    audio.offload.pcm.16bit.enable=true

# default network
PRODUCT_PROPERTY_OVERRIDES += \
    ro.telephony.default_network=20 \
    persist.radio.multisim.config=dsds

# WCNSS does not implement Android's LE vendor scan-filter commands.
PRODUCT_PROPERTY_OVERRIDES += \
    bluetooth.core.le.vendor_capabilities.enabled=false \
    persist.camera.hal1.nv12_venus=true

# Android 14 Bluetooth profile services default to disabled unless selected.
PRODUCT_SYSTEM_PROPERTIES += \
    bluetooth.profile.a2dp.source.enabled=true \
    bluetooth.profile.avrcp.target.enabled=true \
    bluetooth.profile.hfp.ag.enabled=true \
    bluetooth.profile.hid.host.enabled=true \
    bluetooth.profile.opp.enabled=true \
    bluetooth.profile.pan.nap.enabled=true \
    bluetooth.profile.pan.panu.enabled=true \
    bluetooth.profile.pbap.server.enabled=true

# HAL1 has no independent Camera2 torch API. Use the Camera1 preview fallback.
PRODUCT_SYSTEM_PROPERTIES += ro.camera.legacy_torch=true

# Keep recording color conversion out of the legacy Adreno GLES context.
PRODUCT_SYSTEM_PROPERTIES += \
    ro.surface_flinger.force_hwc_copy_for_virtual_displays=true \
    persist.hwc.enable_vds=1
