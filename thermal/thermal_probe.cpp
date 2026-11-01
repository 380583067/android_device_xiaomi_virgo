/* Copyright (C) 2026 The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */
#include <hardware/thermal.h>
#include <dlfcn.h>
#include <cmath>
#include <cstdio>
#include <set>
#include <string>
#include <vector>

int main(int argc, char** argv) {
    if (argc != 2) return 2;
    void* handle = dlopen(argv[1], RTLD_NOW);
    if (!handle) { puts(dlerror()); return 2; }
    auto* module = static_cast<thermal_module_t*>(dlsym(handle, HAL_MODULE_INFO_SYM_AS_STR));
    if (!module || !module->getTemperatures || !module->getCpuUsages) return 2;
    const ssize_t count = module->getTemperatures(module, nullptr, 0);
    if (count <= 0 || count > 64) return 2;
    std::vector<temperature_t> temps(count);
    const ssize_t got = module->getTemperatures(module, temps.data(), temps.size());
    if (got <= 0 || got > count) return 2;
    std::set<std::string> names;
    int errors = 0, cpus = 0, gpus = 0, batteries = 0, pmics = 0;
    for (ssize_t i = 0; i < got; ++i) {
        const auto& t = temps[i];
        printf("TEMP name=%s type=%d celsius=%.3f\n", t.name, t.type, t.current_value);
        if (!names.insert(t.name).second || !std::isfinite(t.current_value) ||
            t.current_value < -50 || t.current_value > 150) ++errors;
        cpus += t.type == DEVICE_TEMPERATURE_CPU;
        gpus += t.type == DEVICE_TEMPERATURE_GPU;
        batteries += t.type == DEVICE_TEMPERATURE_BATTERY;
        pmics += std::string(t.name) == "pm8841_tz" || std::string(t.name) == "pm8941_tz";
    }
    if (cpus != 4 || gpus != 1 || batteries != 1 || pmics != 2) ++errors;
    // A smaller caller buffer must neither be overwritten nor report a larger
    // filled length. This matters when availability changes between HAL queries.
    temperature_t small[2] = {};
    small[1].name = "guard";
    const ssize_t shortCount = module->getTemperatures(module, small, 1);
    if (shortCount != 1 || std::string(small[1].name) != "guard") ++errors;
    const ssize_t cpuCount = module->getCpuUsages(module, nullptr);
    if (cpuCount != 4) ++errors;
    if (cpuCount == 4) {
        std::vector<cpu_usage_t> usage(cpuCount);
        if (module->getCpuUsages(module, usage.data()) != cpuCount) ++errors;
        names.clear();
        for (const auto& cpu : usage) {
            printf("CPU name=%s active=%llu total=%llu online=%d\n", cpu.name,
                   static_cast<unsigned long long>(cpu.active),
                   static_cast<unsigned long long>(cpu.total), cpu.is_online);
            if (!names.insert(cpu.name).second || cpu.active > cpu.total) ++errors;
        }
    }
    printf("RESULT errors=%d cpuTemps=%d gpuTemps=%d batteryTemps=%d pmics=%d\n",
           errors, cpus, gpus, batteries, pmics);
    dlclose(handle);
    return errors ? 1 : 0;
}
