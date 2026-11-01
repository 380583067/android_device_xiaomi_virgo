#
# Copyright (C) 2018 The LineageOS Project
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

PRODUCT_MAKEFILES := \
    $(LOCAL_DIR)/lineage_virgo.mk

# Android 14 lunch targets include the AP2A release name. Keep the eng
# combination available for this legacy device so an explicit eng build
# retains the platform's root/ADB debugging defaults.
COMMON_LUNCH_CHOICES := \
    lineage_virgo-ap2a-user \
    lineage_virgo-ap2a-userdebug \
    lineage_virgo-ap2a-eng
