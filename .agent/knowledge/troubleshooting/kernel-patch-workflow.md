# NixOS 内核补丁: 正确姿势

## 适用场景
内核有 bug/回归，上游修复未进入 nixpkgs stable，需要临时打补丁。

## 步骤

### 1. 确认问题
```bash
sudo dmesg | grep -i "关键词"
zcat /proc/config.gz | grep -i "相关配置"  # 确认非编译选项缺失
```

### 2. 找到修复 commit
从 upstream git log / mailing list 找到修复 commit hash。

### 3. 写补丁文件
```bash
mkdir -p patches/
# 创建 patches/<描述>.patch
```

补丁格式:
```diff
--- a/drivers/bluetooth/btmtk.c
+++ b/drivers/bluetooth/btmtk.c
@@ -679,8 +679,8 @@
 		if (!skb_pull_data(...)) {
-			err = -EINVAL;
-			goto err_free_skb;
+			status = BTMTK_WMT_ON_UNDONE;
+			break;
 		}
```

### 4. 在 NixOS 模块中引用

**不要在 flake.nix 里改** — 放在 host 级配置:

```nix
# hosts/MEOW/hardware.nix
{ config, lib, pkgs, ... }:

let
  patchedKernel = pkgs.linux_7_0.override {
    kernelPatches = [
      {
        name = "btmtk-wmt-fix";
        patch = ./../../patches/btmtk-wmt-fix.patch;  # 相对路径
      }
    ];
  };
in {
  boot.kernelPackages = pkgs.linuxPackagesFor patchedKernel;
}
```

### 5. 关键注意事项

| 要点 | 说明 |
|------|------|
| **git add 补丁文件** | Nix flake 只识别 git tracked 文件 |
| **相对路径** | `./` 路径字面量从所在文件出发 |
| **先 dry-activate** | 确认补丁能正确 apply（打不上会报错） |
| **加注释** | 在补丁文件和引用处都写清楚 bug 背景、上游 fix commit、何时可删除 |
| **记住删除条件** | nixpkgs 更新到含修复的内核后，删补丁和引用 |

### 6. 补丁注释模板

```nix
# 蓝牙修复: 内核 btmtk.c 对 MT7922 WMT FUNC_CTRL 短包 -EINVAL 回归
# 上游 fix: commit e3ac0d9f1a20, 在 6.12.91+ / 7.1-rc1+
# nixpkgs 25.11 尚无含修复的内核版本
# TODO: nixpkgs 更新后删此 patch 及 patchedKernel 引用
```

## 经验
- 内核补丁在 NixOS 里是标准操作，类型安全，可复现
- 不要改 flake.nix — 放在 host 级最清晰
- 补丁文件是 git 追踪的，任何人 clone 后都能重现相同内核
