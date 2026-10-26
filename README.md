# gdut_net_auto

广东工业大学校园网 / PPPoE 宽带 —— 开机（登录）后自动拨号的小工具。

再也不用打开「设置 → 网络和 Internet → 拨号 → 连接」手动点一次。

## 目录

| 目录 | 平台 | 说明 |
|---|---|---|
| [`windows-auto-dial`](windows-auto-dial/) | Windows | 登录后由启动文件夹自动执行 `rasdial`，无窗口、失败自动重试 |

## 快速开始（Windows）

```powershell
git clone https://github.com/520gj/gdut_net_auto.git
```

进入 `gdut_net_auto\windows-auto-dial`，**双击 `安装.cmd`**（窗口会停住，能看到每一步结果）。

详细说明（参数、日志、错误码、卸载）见 [windows-auto-dial/README.md](windows-auto-dial/README.md)。

## 原理

Windows 拨号连接（PPPoE）在系统里就是一条 RAS 记录，可以用命令行直接拨：

```powershell
rasdial                # 列出已连接的连接
rasdial "你的连接名"    # 拨号（使用 Windows 保存的账号密码）
```

所以只要把这一条命令挂到登录后执行，就能免去手动操作。账号密码由 Windows 的凭据管理器用 DPAPI 加密保存，脚本里不出现明文。

## License

MIT
