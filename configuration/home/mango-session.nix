{
  lib,
  ...
}: {
  # ---------------------------------------------------------------------------
  # mango 会话 → systemd 用户实例
  # ---------------------------------------------------------------------------
  # ly 直接 fork 出 mango，不会经过 systemd，所以 graphical-session.target
  # 永远是 inactive；而 xdg-desktop-portal.service 带
  # Requisite=graphical-session.target，于是任何 D-Bus 激活都会失败，
  # OBS 报：
  #   Could not activate remote peer 'org.freedesktop.portal.Desktop': startup job failed
  #   [pipewire] No capture sources available
  # 屏幕共享 / Screenshot / polkit 认证代理都因此不可用。
  #
  # 解决办法：提供一个可手动启动的会话 target，它通过依赖关系把
  # graphical-session.target 拉起来（后者本身 RefuseManualStart，
  # 只能由依赖作业启动）。
  # mango 的 exec_once 里导入环境后执行 `systemctl --user start mango-session.target`。
  systemd.user.targets.mango-session = {
    Unit = {
      Description = "mango compositor session";
      Documentation = ["man:systemd.special(7)"];
      BindsTo = ["graphical-session.target"];
      Wants = ["graphical-session.target"];
      After = ["graphical-session.target"];
    };
  };

  # 会话内的 XDG_CURRENT_DESKTOP 会随 mango 走，"mango:wlroots" 这种带冒号的
  # 值在 systemd 激活的 portal 进程里不一定还在，统一按单值 mango 处理。
  systemd.user.sessionVariables = {
    XDG_CURRENT_DESKTOP = lib.mkDefault "mango";
    XDG_SESSION_DESKTOP = lib.mkDefault "mango";
  };
}
