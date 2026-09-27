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
#              feature ID 由 modules/common/options.nix 对照 lib/features.nix 校验,
#              标签拼错会直接 eval 失败。
#   users    — 此 host 上部署哪些 users.nix 身份 ID。
#   primaryUser — legacy system modules 使用的默认用户, 必须包含在 users 中。
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
    system = "x86_64-linux";
    profile = "high";
    kind = "laptop";
    roles = ["workstation"];
    desktopEffects = "full";
    users = ["reiky"];
    primaryUser = "reiky";
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
    system = "x86_64-linux";
    profile = "medium";
    kind = "wsl";
    roles = ["devbox"];
    desktopEffects = "minimal";
    users = ["reiky"];
    primaryUser = "reiky";
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
