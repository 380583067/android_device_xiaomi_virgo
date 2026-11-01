// SPDX-License-Identifier: Apache-2.0
// Copyright (C) 2026 The LineageOS Project
#include <android-base/file.h>
#include <android-base/logging.h>
#include <android-base/parseint.h>
#include <android-base/strings.h>
#include <hidl/HidlTransportSupport.h>
#include <vendor/lineage/livedisplay/2.0/IDisplayModes.h>

using android::hardware::Return;
using android::hardware::Void;
using vendor::lineage::livedisplay::V2_0::DisplayMode;
using vendor::lineage::livedisplay::V2_0::IDisplayModes;

namespace {
constexpr const char* kSaturation = "/sys/devices/platform/kcal_ctrl.0/kcal_sat";
constexpr const char* kDefault = "/data/vendor/virgo-display/default-mode";
// KCAL presets, not factory-calibrated sRGB/DCI-P3 profiles. RGB calibration
// remains under LiveDisplay's existing color-temperature controller.
constexpr int kValues[] = {255, 280, 128};
const char* const kNames[] = {"Natural", "Vivid", "Monochrome"};
bool valid(int id) { return id >= 0 && id < 3; }
DisplayMode mode(int id) { return {id, kNames[id]}; }
int defaultId() {
    std::string text;
    int id = 0;
    if (!android::base::ReadFileToString(kDefault, &text) ||
            !android::base::ParseInt(android::base::Trim(text), &id) || !valid(id)) return 0;
    return id;
}
class DisplayModes final : public IDisplayModes {
 public:
    bool restore() {
        return android::base::WriteStringToFile(std::to_string(kValues[defaultId()]), kSaturation);
    }
    Return<void> getDisplayModes(getDisplayModes_cb cb) override {
        cb({mode(0), mode(1), mode(2)});
        return Void();
    }
    Return<void> getCurrentDisplayMode(getCurrentDisplayMode_cb cb) override {
        std::string text;
        int value = 0;
        if (android::base::ReadFileToString(kSaturation, &text) &&
                android::base::ParseInt(android::base::Trim(text), &value)) {
            for (int id = 0; id < 3; ++id) {
                if (value == kValues[id]) { cb(mode(id)); return Void(); }
            }
        }
        cb(DisplayMode{-1, ""});
        return Void();
    }
    Return<void> getDefaultDisplayMode(getDefaultDisplayMode_cb cb) override {
        cb(mode(defaultId()));
        return Void();
    }
    Return<bool> setDisplayMode(int32_t id, bool makeDefault) override {
        if (!valid(id)) return false;
        std::string previous;
        if (!android::base::ReadFileToString(kSaturation, &previous) ||
                !android::base::WriteStringToFile(std::to_string(kValues[id]), kSaturation)) return false;
        if (makeDefault && !android::base::WriteStringToFile(std::to_string(id), kDefault)) {
            android::base::WriteStringToFile(previous, kSaturation);
            return false;
        }
        return true;
    }
};
}  // namespace
int main() {
    android::hardware::configureRpcThreadpool(1, true);
    android::sp<DisplayModes> service = new DisplayModes();
    if (!service->restore() || service->registerAsService() != android::OK) {
        LOG(ERROR) << "Unable to initialize Virgo KCAL display modes";
        return 1;
    }
    android::hardware::joinRpcThreadpool();
    return 1;
}
