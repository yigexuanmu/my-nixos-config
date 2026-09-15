{
  lib,
  pkgs,
  ...
}: {
  wsl.enable = true;
  wsl.defaultUser = "mioha";

  # GPU-PV：使用 Windows 驱动（/usr/lib/wsl/lib + /dev/dxg），提供 OpenGL/Vulkan/CUDA 加速
  wsl.useWindowsDriver = true;
  hardware.graphics.enable = true;

  # Mesa 的 d3d12(OpenGL)/dzn(Vulkan) 驱动需要找到 Windows 直通库（libdxcore 等），
  # 且 GLX 默认选 d3d12 而非 llvmpipe 软渲染
  environment.sessionVariables = {
    LD_LIBRARY_PATH = "/usr/lib/wsl/lib:/run/opengl-driver/lib";
    GALLIUM_DRIVER = "d3d12";
    # nix-ld 运行通用 Linux 二进制（如 /usr/lib/wsl/lib/nvidia-smi）所需的库路径，
    # 与 nix-ld 模块自身的默认值合并
    NIX_LD_LIBRARY_PATH = lib.mkForce "/usr/lib/wsl/lib:/run/current-system/sw/share/nix-ld/lib";
  };

  # nix-ld：提供 /lib64/ld-linux 解释器 shim，让 Windows 直通的 nvidia-smi 等通用二进制可运行
  programs.nix-ld.enable = true;

  # 容器 GPU（CDI）：podman/docker --device nvidia.com/gpu=all
  # 手写静态规格：不用 nvidia-container-toolkit 生成的规格（其 hooks 依赖容器内
  # 不存在的 nvidia-cdi-hook，普通镜像会启动失败）；绑定整个 WSL 驱动目录，
  # Windows 更新 NVIDIA 驱动后依然有效
  environment.etc."cdi/nvidia.yaml".text = ''
    cdiVersion: 0.3.0
    kind: nvidia.com/gpu
    containerEdits:
      env:
        - NVIDIA_VISIBLE_DEVICES=all
    devices:
      - name: all
        containerEdits:
          deviceNodes:
            - path: /dev/dxg
              major: 10
              minor: 258
          mounts:
            - hostPath: /usr/lib/wsl/lib
              containerPath: /usr/lib/wsl/lib
              options:
                - ro
                - nosuid
                - nodev
                - rbind
            - hostPath: /usr/lib/wsl/drivers
              containerPath: /usr/lib/wsl/drivers
              options:
                - ro
                - nosuid
                - nodev
                - rbind
          env:
            - LD_LIBRARY_PATH=/usr/lib/wsl/lib
  '';

  # GPU 加速验证工具：glxinfo（OpenGL）、vulkaninfo（Vulkan）
  environment.systemPackages = with pkgs; [
    mesa-demos
    vulkan-tools
  ];

  # WSL 自身生成的 wsl-mnt-guard.service 会调用 /bin/true，
  # 当前 NixOS-WSL 的 /bin shim 未包含它（203/EXEC），补一个符号链接
  systemd.tmpfiles.rules = [
    "L+ /bin/true - - - - ${pkgs.coreutils}/bin/true"
  ];
}
