_: {
  programs.emacs = {
    enable = true;
  };
  programs.emacs.extraConfig = ''
    (require 'package)
    ;; 1. 设置清华镜像源
    (setq package-archives
          '(("gnu"    . "https://mirrors.tuna.tsinghua.edu.cn/elpa/gnu/")
            ("nongnu" . "https://mirrors.tuna.tsinghua.edu.cn/elpa/nongnu/")
            ("melpa"  . "https://mirrors.tuna.tsinghua.edu.cn/elpa/melpa/")))
    ;; 2. 初始化包管理器
    (unless (bound-and-true-p package--initialized)
      (package-initialize))
    ;; 3. 刷新软件源缓存 (如果本地没有缓存则自动下载)
    (unless package-archive-contents
      (package-refresh-contents))

        (require 'use-package)
        (setq use-package-always-ensure t)

        (use-package treesit-auto
          :custom
          (treesit-auto-install 'prompt)
          :config
          (treesit-auto-add-to-auto-mode-alist 'all)
          (global-treesit-auto-mode))

        (setq eglot-autostart t)
        (setq eglot-send-changes-idle-time 0.1)
        (setq flymake-show-diagnostics-at-end-of-line
               'short)
        (use-package eglot
          :ensure t
          :defer t
          ;; 自动为 Python 和 Rust 开启 LSP
          :hook (((python-mode python-ts-mode) . eglot-ensure)
                 ((rust-mode   rust-ts-mode)   . eglot-ensure))
          :config
          ;; --- 路径处理 (针对 NixOS/Arch 用户) ---
          ;; 确保 Emacs 能找到 uv 安装的 basedpyright 和 rustup 的二进制文件
          (add-to-list 'exec-path "~/.local/bin")
          (add-to-list 'exec-path "~/.cargo/bin")

          ;; --- 核心后端映射 ---
          (setq eglot-server-programs
                (append eglot-server-programs
                        '(((python-mode python-ts-mode) . ("basedpyright-langserver" "--stdio"))
                          ((rust-mode   rust-ts-mode)   . ("rust-analyzer" "--stdio")))))

          ;; --- 详细设置 (性能与功能优化) ---
          (setq-default eglot-workspace-configuration
                        '(;; Python 配置
                          :basedpyright (:analysis (:typeCheckingMode "standard"
                                                    :autoImportCompletions t))
                          ;; Rust 配置
                          :rust-analyzer (:checkOnSave (:command "clippy") ; 保存时用 clippy 检查
                                          :procMacro (:enable t)           ; 启用过程宏
                                          :inlayHints (:enable t)))))       ; 启用行内类型提示
        (add-hook 'eglot-managed-mode-hook
                  (lambda ()
                    (flymake-mode 1)))
  '';

  # 启用 Emacs 后台服务 (Daemon)
  services.emacs = {
    enable = true;
  };
}
