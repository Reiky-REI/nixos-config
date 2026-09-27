# ===== agent 注册表解析与校验 =====
# 把 agents.nix 的定义与 users.nix / machines.nix 求交, 得到:
#   - 每个 (host, user) 上该启用哪些 agent
#   - 各客户端渲染所需的共享字段 (模型 / 系统提示 / provider)
#
# 校验失败一律 throw, 不做静默降级; 所有公开字段都从 validated 派生,
# 因此任何一次使用都会触发校验。
{
  lib,
  agents,
  users,
  machines,
}: let
  validClients = ["opencode" "claude" "codex"];
  hostNames = builtins.attrNames machines;

  scopeOf = agent: agent.hosts or {};
  allowOf = agent: (scopeOf agent).allow or [];
  denyOf = agent: (scopeOf agent).deny or [];
  # hosts 默认全开: 既没给 allow 也没给 deny 时视为 all
  isAllHosts = agent: let
    scope = scopeOf agent;
  in
    scope.all or (allowOf agent == [] && denyOf agent == []);

  errorsFor = name: agent: let
    scope = scopeOf agent;
    agentUsers = agent.users or [];
    client = agent.client or "";
    unknownClients =
      if builtins.elem client validClients
      then []
      else [client];
    unknownUsers = builtins.filter (id: !(builtins.hasAttr id users)) agentUsers;
    unknownAllowHosts = builtins.filter (host: !(builtins.elem host hostNames)) (allowOf agent);
    unknownDenyHosts = builtins.filter (host: !(builtins.elem host hostNames)) (denyOf agent);
    messages =
      lib.optional (unknownClients != []) "unknown client '${builtins.concatStringsSep "," unknownClients}'"
      ++ lib.optional (agentUsers == []) "must list at least one user"
      ++ lib.optional (unknownUsers != []) "unknown users: ${builtins.concatStringsSep ", " unknownUsers}"
      ++ lib.optional (unknownAllowHosts != []) "hosts.allow references unknown hosts: ${builtins.concatStringsSep ", " unknownAllowHosts}"
      ++ lib.optional (unknownDenyHosts != []) "hosts.deny references unknown hosts: ${builtins.concatStringsSep ", " unknownDenyHosts}"
      ++ lib.optional (scope.all or false && (allowOf agent != [] || denyOf agent != []))
      "cannot combine hosts.all with hosts.allow/hosts.deny"
      ++ lib.optional ((agent.privileged or false) && allowOf agent == [])
      "privileged agent needs a non-empty hosts.allow allowlist";
  in
    map (message: "agent '${name}': ${message}") messages;

  allErrors = builtins.concatLists (lib.mapAttrsToList errorsFor agents);

  # 校验通过后的注册表; 其余一切字段都基于它
  resolved =
    if allErrors == []
    then agents
    else throw "agent registry invalid:\n  - ${builtins.concatStringsSep "\n  - " allErrors}";

  enabledOnHost = agent: host:
    if builtins.elem host (denyOf agent)
    then false
    else if builtins.elem host (allowOf agent)
    then true
    else isAllHosts agent;

  # (agent, user, host) 交集: agent 归该 user, 且该 host 绑定了该 user
  hostsUsersInScope = agent: host: let
    machine = machines.${host};
    hostUsers = machine.users or [];
  in
    builtins.filter (id: builtins.elem id (agent.users or [])) hostUsers;

  forHost = host:
    lib.filterAttrs (_: agent: enabledOnHost agent host) resolved;

  # 供客户端适配层消费: 某个 host 上、某个 user 实际可用的 agent 列表
  forHostUser = host: userId:
    lib.mapAttrsToList (name: _: {inherit name;}) (
      lib.filterAttrs (_: agent: builtins.elem userId (hostsUsersInScope agent host)) (forHost host)
    );

  opencodeAgents = lib.filterAttrs (_: agent: agent.client or "" == "opencode") resolved;
  defaultOpencodeAgent = let
    defaults = lib.filterAttrs (_: agent: agent.default or false) opencodeAgents;
  in
    if defaults == {}
    then null
    else builtins.getAttr (builtins.head (builtins.attrNames defaults)) defaults;

  codexAgents = lib.filterAttrs (_: agent: agent.client or "" == "codex") resolved;

  # 取某个客户端的第一个 agent 的字段 (当前每类只有一个主 agent)
  firstAgent = set: field:
    if set == {}
    then null
    else (builtins.getAttr (builtins.head (builtins.attrNames set)) set).${field} or null;

  opencodeModels = lib.unique (
    builtins.filter (model: model != null) (
      map (agent: agent.model or null) (builtins.attrValues opencodeAgents)
    )
  );
in {
  inherit hostNames resolved;

  # 显式暴露校验结果, 便于外部 assert
  validated = resolved;

  opencode = {
    model =
      if defaultOpencodeAgent != null && defaultOpencodeAgent ? model
      then defaultOpencodeAgent.model
      else if opencodeModels == []
      then null
      else builtins.head opencodeModels;
    # 客户端 agent id (如 opencode 的 "plan"), 不是注册表键名
    defaultAgent =
      if defaultOpencodeAgent == null
      then null
      else defaultOpencodeAgent.id or null;
    agents = lib.mapAttrs (_: agent: {inherit (agent) system;}) (
      lib.filterAttrs (_: agent: agent ? system) opencodeAgents
    );
    # root 项目级配置的 plan agent 系统提示
    planSystem = firstAgent (lib.filterAttrs (_: agent: agent.id or "" == "plan") opencodeAgents) "system";
  };

  codex =
    if codexAgents == {}
    then null
    else {
      model = firstAgent codexAgents "model";
      providerName = firstAgent codexAgents "providerName";
      baseUrl = firstAgent codexAgents "baseUrl";
      envKey = firstAgent codexAgents "envKey";
    };

  claude = {
    # claude 侧目前只需知道该用户可用的 agent 名字, 具体样板在适配层
    agents = map (agent: agent.id or null) (builtins.filter (agent: agent.client or "" == "claude") (builtins.attrValues resolved));
  };

  # host -> user -> [agentName]
  bindings = builtins.listToAttrs (map (
      host: {
        name = host;
        value = builtins.listToAttrs (map (
            id: {
              name = id;
              value = map (entry: entry.name) (forHostUser host id);
            }
          )
          (machines.${host}.users or []));
      }
    )
    hostNames);
}
