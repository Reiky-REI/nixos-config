{
  pkgs,
  ...
}: {
  fonts.fontDir.enable = true;

  # WPS Office 不走 fontconfig，直接扫描 /usr/share/fonts/
  # 创建标准字体路径 + 软链接到 store 中的字体文件
  system.activationScripts.fonts = {
    text = ''
      mkdir -p /usr/share/fonts/truetype
      ln -sfn ${pkgs.wqy_zenhei}/share/fonts/truetype/wqy-zenhei.ttc \
        /usr/share/fonts/truetype/WenQuanYi-Zen-Hei.ttc
      ln -sfn ${pkgs.wqy_microhei}/share/fonts/truetype/wqy-microhei.ttc \
        /usr/share/fonts/truetype/WenQuanYi-Micro-Hei.ttc
      ln -sfn ${pkgs.arphic-uming}/share/fonts/truetype/arphic-uming.ttc \
        /usr/share/fonts/truetype/AR-PL-UMing-CN.ttc
      ln -sfn ${pkgs.arphic-ukai}/share/fonts/truetype/arphic-ukai.ttc \
        /usr/share/fonts/truetype/AR-PL-UKai-CN.ttc
      ln -sfn ${pkgs.liberation_ttf}/share/fonts/truetype/LiberationSerif-Regular.ttf \
        /usr/share/fonts/truetype/LiberationSerif-Regular.ttf
      ln -sfn ${pkgs.liberation_ttf}/share/fonts/truetype/LiberationSans-Regular.ttf \
        /usr/share/fonts/truetype/LiberationSans-Regular.ttf
      ln -sfn ${pkgs.liberation_ttf}/share/fonts/truetype/LiberationMono-Regular.ttf \
        /usr/share/fonts/truetype/LiberationMono-Regular.ttf
      ln -sfn ${pkgs.noto-fonts-cjk-serif}/share/fonts/opentype/NotoSerifCJK-VF.otf.ttc \
        /usr/share/fonts/truetype/NotoSerifCJKSC.otf
      ln -sfn ${pkgs.noto-fonts-cjk-sans}/share/fonts/opentype/NotoSansCJK-VF.otf.ttc \
        /usr/share/fonts/truetype/NotoSansCJKSC.otf
    '';
    deps = [];
  };
}
