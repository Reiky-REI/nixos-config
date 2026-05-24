# 标准 Home-Manager 程序/应用模块模板

# 注意: 本文件为未经验证的模板。
# Home 层只放 home-manager options: home.packages, home.file, programs.*
# daemon 不放这里 → 放 modules/services/

{ config, pkgs, lib, ... }: {
  # ============================================================
  # GUI 应用: 放 home/Reiky-REI/apps/
  # CLI 工具: 放 home/Reiky-REI/tools/
  # 编辑器:   放 home/Reiky-REI/editors/
  # 开发工具: 放 home/Reiky-REI/dev/
  # ============================================================

  # 安装包
  home.packages = with pkgs; [
    myApplication
  ];

  # 声明式配置文件 (如需要)
  home.file.".config/myApp/config.toml" = {
    text = ''
      [settings]
      theme = "catppuccin"
    '';
  };

  # 声明式 systemd user service (如需要)
  systemd.user.services.myAppHelper = {
    Unit.Description = "My App Helper Service";
    Install.WantedBy = [ "default.target" ];
    Service.ExecStart = "${pkgs.myHelper}/bin/myHelper";
  };

  # 环境变量 (仅在 home 层)
  home.sessionVariables = {
    MY_APP_CONFIG = "${config.home.homeDirectory}/.config/myApp";
  };
}
