# Virgo AP2A / ENG ART boot fix

From the source-tree root:

```sh
bash device/xiaomi/virgo/patches/check.sh
bash device/xiaomi/virgo/patches/install.sh
bash device/xiaomi/virgo/patches/uninstall.sh
```

`install.sh` applies every patch in this directory. `uninstall.sh` reverses them
in reverse order and refuses to overwrite source that no longer matches.

- `0001-ap2a-lunch-choices.patch` registers Android 14 AP2A lunch targets.
- `0002-eng-release-art.patch` selects the release ART APEX before the base
  product includes ART, while retaining the ENG build variant and its ADB/root
  debugging behavior.
