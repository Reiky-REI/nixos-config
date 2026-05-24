# 常见问题 FAQ

> 按类别索引的已知问题和解决方案。  
> 每次遇到新问题并解决后，**必须追加到此文件**。

---

## 编译 / 构建问题

### `error: flake 'github:xxx' not found`
**原因**: flake input 不可达（网络问题或 repo 重命名）  
**解决**: 检查 clash 代理是否运行 → `curl -x http://127.0.0.1:7897 https://github.com`  
**相关**: `.agent/config/rebuild.sh` 自动注入代理

### `error: hash mismatch in file ...`
**原因**: 上游包更新了但 hash 没跟上  
**解决**: `nix flake update <input>` 获取最新锁文件。如果是自己写的 derivation，用报错中提示的新 hash 替换。

### `error: The option ... does not exist`
**原因**: 写了不存在的 NixOS/home-manager 选项  
**解决**: `nixos-option <option.path>` 验证。或查 [mcp-nixos](https://github.com/utensils/mcp-nixos)。

### `error: infinite recursion encountered`
**原因**: 模块间循环引用（import A → import B → import A）  
**解决**: 检查 default.nix 的 imports 链。不要让子模块 import 父模块。

---

## 运行时问题

### fcitx5 无法输入中文
**原因**: GTK_IM_MODULE 未设置  
**解决**: 确认 `modules/desktop/fcitx5/fcitx5.nix` 中存在 `environment.sessionVariables.GTK_IM_MODULE = "fcitx5"`。重启输入法 `fcitx5 -r`。切换快捷键 `Super+Space`。

### mpd 首次启动失败 "Address already in use"
**原因**: 首次 switch 后 mpd socket 残留  
**解决**: `sudo killall mpd && sudo systemctl restart mpd`

### nvidia 驱动加载失败
**原因**: hardware.nix 中 nvidia 配置拼写错误  
**解决**: 检查 `hardware.nvidia.package`、`hardware.nvidia.modesetting.enable` 等选项。
验证: `nvidia-smi` 应正常输出。

### 蓝牙无法连接（MediaTek MT7922）
**原因**: 内核 bug（`wmt func ctrl (-22)`）  
**解决**: 已打补丁 `patches/btmtk-wmt-fix.patch`。上游修复在 6.12.91+ / 7.1-rc1+。
待 nixpkgs 更新后移除补丁。

### clash 代理不工作
**原因**: clash-verge 未启动或 TUN 模式异常  
**解决**: 检查 `systemctl status clash-verge`。确认 `programs.clash-verge.tunMode = true`。
代理地址: `http://127.0.0.1:7897`

---

## AI Agent 权限相关

### ai-agent 无法写文件
**原因**: 用户组权限未配置  
**解决**: 检查 BLUEPRINT.md 第 4 节的权限矩阵。对外目录加 ai-shared 组权限。
```bash
id ai-agent  # 确认组
ls -la /home/ai-agent  # 确认权限
```

### agenix 解密失败
**原因**: SSH 私钥权限不对或 identityPaths 配置错误  
**解决**: `~/.ssh/id_ed25519` 必须是 0600。
检查 `age.identityPaths` 在 flake.nix 中是否正确。

### opencode 找不到 skill
**原因**: SKILL.md 未生成到正确的目录  
**解决**: opencode 的 skill 路径: `~/.config/opencode/skills/` 或 `.agents/skills/`。
确认 Nix 生成的文件路径与此一致。

---

## Git 操作问题

### push 被拒绝
**原因**: 使用 HTTP 而非 SSH，需要 token  
**解决**: 检查 `.agent/config/token` 中的 GitHub token 是否有效。
`git remote set-url origin git@github.com:Reiky-REI/nixos-config.git`

### 分支混乱
**原因**: 多个 AI 同时在不同的分支工作  
**解决**: `git branch -a` 查看所有分支。AI 工作分支格式: `ai/step-N-xxx`。
切换前确保工作区干净。

---

## Nix 概念问题

### 我应该写 NixOS 选项还是 home-manager 选项？
- daemon / 内核 / 系统能力 → NixOS (`modules/services/`)
- 用户应用 / 编辑器 / shell → home-manager (`home/Reiky-REI/`)
- 桌面基础设施 → NixOS (`modules/desktop/`)
- WM 配置文件 → home-manager (`home/Reiky-REI/desktop/`)

### `nix eval` vs `nix build` vs `nixos-rebuild` 的区别？
- `nix eval`: 只评估表达式，零副作用 → 安全
- `nix build`: 构建单个 derivation → 产生 store path
- `nixos-rebuild build`: 构建整个系统 → 产生系统 closure
- `nixos-rebuild switch`: 构建 + 应用 → 影响运行中的系统

### `imports` vs `environment.systemPackages` 的区别？
- `imports`: 加载模块（向系统添加配置选项）
- `environment.systemPackages`: 安装包（向 PATH 添加可执行文件）
