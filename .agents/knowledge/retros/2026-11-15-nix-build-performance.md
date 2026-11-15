---
date: 2026-11-15
agent: opencode
status: success
module: modules/common/default.nix, .agents/config/rebuild.sh
tags: [nix, 构建性能, eval, max-jobs, substituters, zram, 排障]
topic: 定位「每次构建都超级慢」——eval 才是瓶颈, 顺带重定标 max-jobs/cores + 清理死镜像 + 上 zram
---

# Retro: Nix 构建慢的定位与限流重定标

用户提问: 「每次构建都超级慢, 是什么限制了 nix-build? 转成 home-manager 会不会好?」

## 实测数据 (2026-11-15, 构建空载时测)

| 测量 | 结果 |
|---|---|
| 系统 toplevel `drvPath` 求值 (冷) | 6m08s |
| 同上 (温, 第二次) | **3m24s** (user 2m58s) |
| HM `home.packages` 113 个包 `drvPath` | **2m36s** (user 2m01s) |
| 模块系统 fixpoint (`config.system.stateVersion`) | 6.4s |
| `pkgs.hello` (含 overlays) | 6.8s |
| `nixvim` 单包 | 21s (18s CPU) |
| nixvim+chrome+vscode+zen 四件 | 28s |
| 构建中 CPU | us 5-11% / **id 67-76%** / iowait 16-18% |
| pypi 下载 (代理/直连) | 5.3 / 3.3 MB/s |
| cache.nixos.org 延迟 (代理/直连) | 0.69s / 0.35s |
| 电源档位 | `power-saver`, governor `powersave`, EPP `power` |
| 改为 `performance` 后同一 eval | 2m31s (**几乎无变化**) |

## 结论: 慢在 eval, 不在编译

- 一次 `nixos-rebuild` 的**固定成本是 3 分钟左右的单线程求值**, 编译本身往往只要几十秒喵~
- eval 成本 ≈ 安装包数量 × 每包闭包实例化开销 (113 包 → 156s ≈ 1.4s/包), 与写在哪一层无关喵~
- 构建期间 CPU 70% 空转 → 不是算力不够, 是 Nix 求值只能单线程 + FOD 下载串行喵~
- 「转 home-manager」省不了: **HM 那 113 个包本身就是 eval 的大头 (2m36/3m24)**;
  单独跑 `home-manager switch` 只能省掉 system 侧 ~30-50s 实例化 + 系统 activation 喵~
  真要减 eval 只能减少声明式安装的包 (GUI 大件挪去 flatpak/nix profile 之类)喵~

## 顺带查出的配置问题

1. `max-jobs = 16` + `cores = 16` 在 24 线程 / **14GB 内存** 上 = 最坏 256 个编译线程,
   单个 `npm ci` 峰值就 3GB RSS, 16 并发会把内存打成 swap (实测已用 3.5G 磁盘 swap)喵~
2. `substituters` 首位 TUNA 的 `nix-channels/store/nix-cache-info` 现在返回 **403**,
   等于每次 narinfo 查询先白跑一趟; `cache.nixos.org` 被列了两次喵~
3. 无 zram, 14GB 机器靠 NVMe swap 扛构建高峰喵~
4. `power-saver` 对 eval 几乎没影响 (实测 2m36→2m31), 但对**多核编译吞吐**仍有意义喵~

## 改动

```nix
nix.settings.max-jobs = 6;   # high 档 (原 16); medium 4 / low 2
nix.settings.cores = 4;      # 原 16 → 6×4=24 线程封顶, 与物理核数对齐
nix.settings.substituters = [ USTC, SJTU, cache.nixos.org ];   # 去掉 TUNA(403)
zramSwap = { enable = true; algorithm = "zstd"; memoryPercent = 25; };
```

同时更新 `.agents/config/rebuild.sh` 里写死的 `SUBSTITUTERS` (去掉 TUNA)喵~

## 验证

- `nix build .#nixosConfigurations.NixMEOW.config.system.build.toplevel` 通过 (4m25 总耗时, 其中 eval ~3.5min)喵~
- 产物 `/nix/store/7phhr7g3...-nixos-system-NixMEOW-...` 的 `etc/nix/nix.conf`:
  `cores = 4` / `max-jobs = 6` / substituters 无 TUNA ✓
- `etc/systemd/zram-generator.conf`: `zram-size=25/100*ram` + `swap-priority=5` ✓
- **未 switch**: 本机是 NVIDIA PRIME, `switch` 会重启 polkit → compositor 丢 DRM master → 黑屏
  (见 `.agents/config/rebuild.sh` 的警告), 按仓库约定交给用户 reboot 生效喵~
- zram 只能下次开机生效 (systemd generator 在 boot 时跑)喵~

## 后续可选

- `nix.settings.keep-outputs = true`: 回滚/再 switch 不用重编, 但当前磁盘 85% 占用, 先不开喵~
- 想真正把 eval 从 ~3min 压到 <1min: 把 chrome/vscode/zen/krita/zed/obsidian/nixvim 这类
  大件移出 `home.packages` (改 flatpak / nix profile) —— 属于取舍, 未做喵~
- 构建慢的另一个大头是 FOD 数量 (一次 hermes 构建 484 个 building, 其中 171 个 python wheel);
  FOD 永远无法从二进制缓存取, 只能少装依赖或改用固定输出的预取喵~
