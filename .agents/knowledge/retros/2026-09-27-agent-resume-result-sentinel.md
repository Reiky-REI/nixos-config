---
date: 2026-09-27
module: README.md, .agents/config/agent-resume-runner.sh, .agents/config/queue-task.sh, home/Reiky-REI/tools/agent-resume.nix
tags: [agent-resume, systemd, false-success, queue, container]
layer: home
severity: high
related:
  - ../known-issues.md (agent-resume 假 OK 与容器导入容量)
  - 2026-09-27-multidimensional-config.md (容器镜像构建)
experience:
  - "systemd-run --wait 被 stop 后可能返回 0; task 文件仍在 running/ 也不能证明 payload 完成, 必须要有 payload 自己写入的完成证据。"
  - "队列命令默认启用严格错误处理, 避免末尾 echo 把中途失败覆盖成 0; --wake 在父 shell 捕获子 shell 退出码后仍可执行唤醒。"
  - "3.3GB 压缩的容器 tarball 展开约 16.4GB, 导入前必须核对展开尺寸和容器存储容量, 不能只看压缩文件大小。"
  - "Home Manager activation 可中断 agent-resume.service 本身; 启动时必须回收 running/ 残留, 并区分仍 active 的 transient 与缺少完成 sentinel 的中断任务。"
---

# agent-resume 假成功判定修复与容器导入复核

## 现场与发现

- generation 233 已由 Home Manager 接管 `agent-resume.service/path/timer`; `ExecStart` 指向 `/nix/store/...-agent-resume-runner`, path/timer 均 active, linger 为 yes 喵~
- 容器任务 `ctr-docker-verify2-20260927` 的第二次尝试曾被手动 stop; journal 记录 `podman import` 后 transient unit 被 stop, 但 `systemd-run --wait` 返回 0, 旧 runner 因而发了成功板报喵~
- 任务 payload 也没有严格错误处理, 后续 `echo "verify done"` 可覆盖先前导入/启动失败码; rootful `podman images` 实际为空喵~
- 已把错误的 task 从 `done/` 更正至 `failed/ctr-docker-verify2-20260927.task.false-ok`, 保留原 task、日志与状态更正清单, 并向 watchdog 回报更正喵~

## 修复

- runner 为每次尝试传入独立 `RESULT_FILE`; payload EXIT trap 写出实际退出码, 缺失标记或非零码一律视为失败, 不再只信 systemd 客户端退出码或 task 文件位置喵~
- `queue-task.sh` 将任务命令包在 `set -Eeuo pipefail` 子 shell 中; `--wake` 在父 shell 获取子 shell 退出码后仍执行强制唤醒喵~
- `agent-resume.service` 外层 timeout 改为 infinity; 每个 payload 的 `RuntimeMaxSec` 仍由 transient unit 独立限制, 多个任务串行时不会被统一的两小时上限截断喵~
- 新增 runner 回归脚本, 覆盖正常完成、严格模式捕获失败、模拟 systemd-run 被 stop 却返回 0、以及 `--wake` payload 语法喵~
- generation 234 部署时, HM activation 确实终止了正在执行 switch task 的旧 runner, task 留在 `running/` 且没有旧版 sentinel;
  以 loader/current generation、服务健康和 live queue check 独立核验 switch 后, 留证并将任务状态更正为完成喵~
- runner 现为每次尝试保存 transient unit/result/log sidecar, 重启扫描 `running/`: 已成功的 sentinel 收尾, active unit 等待,
  不完整且 inactive 的任务按 retries 重新排队或失败喵~

## 容器导入容量

- `xz -lv` 实测镜像压缩约 3.33GB、展开约 16.44GB; 根分区当时仅约 18GB 可用, 导入还需要 Podman 存储空间喵~
- Podman 官方文档确认 `podman import` 原生支持 XZ tarball; 卡慢与本地导入资源/容量有关, 不是缺少代理或需要预解压喵~
- 因容量余量不足, 没有再次启动导入以免耗尽根分区; 容器内 systemd 冒烟验证仍未完成, 也确认 `podman import` 读取本地文件, 与代理无关喵~
- 后续验证前应准备更大的独立本地存储, 或重做更小的镜像方案; 不要在当前空间条件下直接重试喵~

## 验证

- `.agents/config/test-agent-resume-runner.sh` 覆盖正常完成、失败码、stop 假成功、--wake 语法、残留完成收尾、active transient 防重复和中断重试喵~
- `bash -n`、`git diff --check` 与 Alejandra 格式检查通过喵~
- NixMEOW、NixMEOW-WSL、NixMEOW-CTR 在 sentinel 与 running recovery 两版改动后均 build 通过喵~
- generation 235 已激活且 loader default 同步; live queue check 确认新 runner 带 sentinel/recovery、path/timer active,
  switch 与验证 task 均已归档至 done/ 喵~ README 与容器专项文档也补齐操作入口和容量限制喵~
