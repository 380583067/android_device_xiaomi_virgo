/*
 * Copyright (C) 2026 The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

#include <hardware/thermal.h>

#include <cerrno>
#include <cstdio>
#include <cstring>
#include <dirent.h>
#include <inttypes.h>

namespace {

struct Sensor {
    const char* name;
    temperature_type type;
    float divisor;
};

// Kernel msm8974.dtsi maps CPU0..3 to TSENS5..8. The vendor thermal
// configuration maps the GPU to TSENS10. PMIC drivers report millidegrees,
// while this kernel's TSENS and ADC thermistors report degrees Celsius.
constexpr Sensor kSensors[] = {
        {"tsens_tz_sensor0", DEVICE_TEMPERATURE_UNKNOWN, 1},
        {"tsens_tz_sensor1", DEVICE_TEMPERATURE_UNKNOWN, 1},
        {"tsens_tz_sensor2", DEVICE_TEMPERATURE_UNKNOWN, 1},
        {"tsens_tz_sensor3", DEVICE_TEMPERATURE_UNKNOWN, 1},
        {"tsens_tz_sensor4", DEVICE_TEMPERATURE_UNKNOWN, 1},
        {"tsens_tz_sensor5", DEVICE_TEMPERATURE_CPU, 1},
        {"tsens_tz_sensor6", DEVICE_TEMPERATURE_CPU, 1},
        {"tsens_tz_sensor7", DEVICE_TEMPERATURE_CPU, 1},
        {"tsens_tz_sensor8", DEVICE_TEMPERATURE_CPU, 1},
        {"tsens_tz_sensor9", DEVICE_TEMPERATURE_UNKNOWN, 1},
        {"tsens_tz_sensor10", DEVICE_TEMPERATURE_GPU, 1},
        {"pm8841_tz", DEVICE_TEMPERATURE_UNKNOWN, 1000},
        {"pm8941_tz", DEVICE_TEMPERATURE_UNKNOWN, 1000},
        {"pa_therm0", DEVICE_TEMPERATURE_UNKNOWN, 1},
        {"pa_therm1", DEVICE_TEMPERATURE_UNKNOWN, 1},
        {"emmc_therm", DEVICE_TEMPERATURE_UNKNOWN, 1},
        {"msm_therm", DEVICE_TEMPERATURE_UNKNOWN, 1},
};

bool readFloat(const char* path, float* value) {
    FILE* file = fopen(path, "re");
    if (!file) return false;
    const bool ok = fscanf(file, "%f", value) == 1;
    fclose(file);
    return ok;
}

void appendTemperature(temperature_t* list, size_t size, size_t* count,
                       const char* name, temperature_type type, float value) {
    if (list && *count < size) {
        list[*count] = {type, name, value, UNKNOWN_TEMPERATURE,
                       UNKNOWN_TEMPERATURE, UNKNOWN_TEMPERATURE};
    }
    ++*count;
}

ssize_t getTemperatures(thermal_module_t*, temperature_t* list, size_t size) {
    DIR* dir = opendir("/sys/class/thermal");
    if (!dir) return -errno;
    size_t count = 0;
    while (dirent* entry = readdir(dir)) {
        if (strncmp(entry->d_name, "thermal_zone", 12)) continue;
        char path[512], type[80];
        snprintf(path, sizeof(path), "/sys/class/thermal/%s/type", entry->d_name);
        FILE* file = fopen(path, "re");
        if (!file) continue;
        const bool ok = fscanf(file, "%79s", type) == 1;
        fclose(file);
        if (!ok) continue;
        for (const auto& sensor : kSensors) {
            if (strcmp(type, sensor.name)) continue;
            float value;
            snprintf(path, sizeof(path), "/sys/class/thermal/%s/temp", entry->d_name);
            if (readFloat(path, &value)) {
                appendTemperature(list, size, &count, sensor.name, sensor.type,
                                  value / sensor.divisor);
            }
            break;
        }
    }
    closedir(dir);
    float battery;
    if (readFloat("/sys/class/power_supply/battery/temp", &battery)) {
        appendTemperature(list, size, &count, "battery", DEVICE_TEMPERATURE_BATTERY,
                          battery / 10.0f);
    }
    // The caller allocated the capacity from a previous query. Never report
    // more entries than actually written if sensor availability changed.
    return list && count > size ? size : count;
}

ssize_t getCpuUsages(thermal_module_t*, cpu_usage_t* list) {
    if (!list) return 4;
    constexpr const char* names[] = {"cpu0", "cpu1", "cpu2", "cpu3"};
    for (int cpu = 0; cpu < 4; ++cpu) {
        char path[128];
        float online = 0;
        snprintf(path, sizeof(path), "/sys/devices/system/cpu/cpu%d/online", cpu);
        if (!readFloat(path, &online)) online = cpu == 0;
        list[cpu] = {names[cpu], 0, 0, online != 0};
    }
    FILE* file = fopen("/proc/stat", "re");
    if (!file) return -errno;
    char line[512];
    while (fgets(line, sizeof(line), file)) {
        unsigned cpu;
        uint64_t user, nice, system, idle, iowait, irq, softirq, steal;
        if (sscanf(line, "cpu%u %" SCNu64 " %" SCNu64 " %" SCNu64 " %" SCNu64
                        " %" SCNu64 " %" SCNu64 " %" SCNu64 " %" SCNu64,
                   &cpu, &user, &nice, &system, &idle, &iowait, &irq, &softirq, &steal) != 9 ||
            cpu >= 4) continue;
        list[cpu].active = user + nice + system + irq + softirq + steal;
        list[cpu].total = list[cpu].active + idle + iowait;
    }
    fclose(file);
    return 4;
}

ssize_t getCoolingDevices(thermal_module_t*, cooling_device_t*, size_t) {
    return 0;
}

hw_module_methods_t kMethods = {};

}  // namespace

extern "C" {
thermal_module_t HAL_MODULE_INFO_SYM = {
        .common = {
                .tag = HARDWARE_MODULE_TAG,
                .module_api_version = THERMAL_HARDWARE_MODULE_API_VERSION_0_1,
                .hal_api_version = HARDWARE_HAL_API_VERSION,
                .id = THERMAL_HARDWARE_MODULE_ID,
                .name = "Virgo Thermal HAL",
                .author = "The LineageOS Project",
                .methods = &kMethods,
        },
        .getTemperatures = getTemperatures,
        .getCpuUsages = getCpuUsages,
        .getCoolingDevices = getCoolingDevices,
};
}
