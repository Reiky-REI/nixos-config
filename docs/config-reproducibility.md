# 配置复现与归档规则

## 单一来源

- 系统配置喵,user 注册喵,host 注册喵,服务配置与 secrets 声明都由 `/etc/nixos` 管理喵~
- `users.nix` 定义身份喵,`machines.nix` 绑定 host 和 users 喵,可复用 Home Manager profile 放在 `home/<profile>` 喵~
- `lib/mk-host.nix` 只导入仓库内模块喵,不从 `~/.config/home-manager/services` 动态读取文件喵~
- Host 能力经 Home Manager 参数传到 user profile 喵,例如 Noctalia 显示器映射喵,背光设备名喵,KB 语料项目列表喵~
- Host × User 组合由注册表显式选择 profile 喵,共享偏好由 Nix 模块组合喵~

## 文件类型边界

| 类型 | 管理位置 | 处理规则 |
|---|---|---|
| 系统与服务配置 | `modules/` 和 `hosts/` | NixOS 生成 systemd units 与 `/etc/static` 文件喵~ |
| User 与桌面偏好 | `home/<profile>/` | Home Manager 声明 user 偏好喵,Host 特有值由 `machines.nix` 参数化喵~ |
| Flake 输入与锁 | `flake.nix` 和 `flake.lock` | 活动输入入仓并锁定喵,退役输入放 `docs/archive/` 喵~ |
| 密钥与凭据 | `secrets/*.age` 或应用私有运行时文件 | 明文不进入 Git 或 `/nix/store` 喵~ |
| 应用运行状态 | 应用 data/cache/session 目录 | 不当作声明式配置喵,按需独立加密归档喵~ |

## 可变应用设置

| 应用 | 管理方式 |
|---|---|
| Noctalia | 静态设置与插件来源存于 `home/Reiky-REI/desktop/` 喵,运行时通过深度合并保留 API key、生成的颜色与插件状态喵~ |
| Zed | `userSettings` 由 Nix 管理喵,GitHub MCP `context_servers` 保留在本地运行文件以隔离 PAT 喵~ |
| OpenCode | `opencode.jsonc` 与 `cli.json` 由 Home Manager 生成喵,模型、默认 agent 与 plan prompt 来自 `agents.nix` 喵,`service.json` 认证状态保留本地喵~ |
| SPlayer 与 YouTube Music | 静态偏好深度合并喵,窗口几何、缓存路径与迁移状态由应用维护喵~ |
| Cava 与 Fcitx5 | 用户设置、shader/theme 资产和 Fcitx profile 由 Home Manager 管理喵,`cached_layouts` 保留为生成状态喵~ |
| btop、Zellij、Superfile、GitHub CLI 与 Pigma | 配置由 Home Manager option 或仓库内原始文件生成喵~ |
| DSH profile | package manifest、lockfile 与 `cordis.patch.yml` 存在 `home/Reiky-REI/tools/dsh-profile/` 喵,插件 node_modules 仍是运行时安装状态喵~ |

## 凭据排除项

- `~/.config/nix/nix.conf` 喵,`~/.config/gh/hosts.yml` 喵,`~/.config/minlai/config.toml` 含认证数据喵,不复制到仓库喵~
- Zed 的 GitHub PAT 喵,Noctalia 的可选 Wallhaven API key 喵,只保留在可写运行文件中喵~
- AstrBot 和 Netease 的旧配置曾把初始密码或 Cookie 放入明文源喵,当前 Nix 源码已移除这些字面量喵,旧凭据需要轮换喵~
- Netease 的 `.env` 仍是应用侧凭据输入喵,已限制为用户可读喵~
- 浏览器 profile 喵,IDE 数据库喵,聊天记录喵,历史记录喵,窗口坐标喵,Fcitx5 缓存都属于应用状态喵~

## 当前边界

- NixMEOW、NixMEOW-WSL 与 NixMEOW-CTR 由 `machines.nix` 组合喵,同一 `reiky` 用户通过 `homeProfile` 复用配置喵~
- AstrBot、NapCat、DSH-AstrBot bridge、mcp-agents-bridge 与专用 opencode-root 通道已退役喵,历史源码与运行数据见 `docs/archive/retired-integrations/` 喵~
- DSH 通用服务 `dsh-fence` 保留喵,AstrBot bridge 插件已从受管 DSH profile 中移除喵~
- 退役应用的数据库、登录态和源码只用于归档恢复喵,不属于新 host 的初始化依赖喵~
- `systemd.user.paths` 与服务声明在 `home/Reiky-REI/tools/` 中统一定义喵,Agent KB 路径来自 host 的 `kbCorpusProjects` 显式列表喵~
- AstrBot/NapCat user units 已停止并禁用喵,mcp-agents-bridge 与 opencode-root 也已停止喵~
- 归档已验证喵,bot 相关本机源目录、登录态、旧 user units 与 DSH bridge 备份已清理喵,KB watcher 活动 unit 保留喵~ 其他已归档但保留的用户文件见 `docs/archive/retired-integrations/README.md` 喵~
- 初次切换曾因 HM 发现未管理的同名配置而中止用户配置激活喵~ 配置 `home-manager.backupFileExtension = "hm-backup"` 后重试成功喵,原配置已备份且 Home Manager 新链接已落地喵~
- NixMEOW 当前 generation 已切换喵,退役的 system services 已从 systemd unit graph 移除喵~
