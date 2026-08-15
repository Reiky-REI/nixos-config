{pkgs, ...}: {
  # 桌面微信/QQ 已移除(2026-08):改用 AstrBot 扫码接入(weixin_oc),无需 wine 模拟。
  home.packages = with pkgs; [];
}
