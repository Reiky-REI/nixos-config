# ===== 机器注册中心 =====
# 添加新机器时，在这里注册主机名和标签。
#
# 字段说明：
#   profile  — 硬件性能档位: high / medium / low
#              (决定 blur/shadow/动画等特效, 见 modules/common/hardware-profile.nix)
#   kind     — 机器种类: laptop / desktop / wsl / vm
#              (决定 boot loader、systemd 睡眠等平台性配置)
#   features — 特性标签列表。
#              每个模块自己检查 (config.meow.enabled ? "<tag>") 决定是否生效,
#              宿主不再挑选模块 (见 lib/mkHost.nix 与 modules/common/options.nix)。
#              标签打错不会 eval 报错(只是对应模块不启用), 改标签请对照下方
#              "可用标签"清单 —— 即各模块 mkIf 里出现过的字符串。
#   note     — 人类可读备注, 不参与任何逻辑。
#
# 使用方式：
# 1. 新机器上用 nixos-generate-config 生成硬件配置
# 2. 在此注册 { hostname = { profile = "..."; kind = "..."; features = [...]; }; }
# 3. 创建 hosts/{hostname}/default.nix
# 4. 无需改 flake.nix —— nixosConfigurations 由本注册表自动生成 (lib/mkHost.nix)
# 5. 构建：nixos-rebuild build --flake /etc/nixos#{hostname}
#
# 注意：未在此注册的 hostname 会导致 build 直接报错（abort），
# 这是故意的——防止意外在未适配的机器上部署。
{
  "NixMEOW" = {
    profile = "high";
    kind = "laptop";
    features = [
      # --- hardware ---
      "bluetooth"
      "gpu-nvidia"
      # --- desktop ---
      "compositor-niri"
      "display-manager-ly"
      "fcitx5"
      "tablet"
      "backlight"
      # --- networking ---
      "networkmanager"
      "clash"
      "tailscale"
      # --- services ---
      "dsh-fence"
      "llama-cpp"
      "opencode-root"
      "mcp-agents-bridge"
      "netease-cdn-bypass"
      "media-mpd"
      "audio"
      "flatpak"
      "printing"
      "libinput"
      "power"
      "udisks2"
      "suspend-block"
      # --- virtualization ---
      "podman"
      "libvirt"
      # --- storage ---
      "nas-smb"
      # --- flake 级 ---
      "kernel-715"
      "agenix-secrets"
    ];
    note = "主力机 — RTX 4070 + AMD 核显";
  };

  "NixMEOW-WSL" = {
    profile = "medium";
    kind = "wsl";
    features = [
      # nested niri (无 ly/无 xserver/无背光; desktop 基础 xwayland 无条件启用)
      "compositor-niri"
    ];
    note = "Windows WSL2 试验台 — 无黑屏风险的 switch 场";
  };

  # 示例：低算力笔记本
  # "NixPentium" = {
  #   profile = "low";
  #   kind = "laptop";
  #   features = [ ];
  #   note = "老奔腾笔记本，无独显";
  # };
}
