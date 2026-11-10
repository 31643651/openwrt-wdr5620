# WDR5620 V9 OpenWrt 云编译工程包

为 **TP-Link TL-WDR5620 千兆易展版 V9.0**（MT7620A + MT7663E 5G + RTL8367S，闪存已自行更换为 16MB）定制的 OpenWrt 云编译工程。本地不编译，全部在 GitHub Actions 上完成。

## 目录结构

```
.github/workflows/build.yml      # GitHub Actions 编译流程
build.sh                         # 构建脚本（云端执行）
openwrt.config                   # 编译配置（设备/软件包选择）
target/linux/ramips/dts/
  mt7620a_tplink_wdr5620-v9.dts  # 设备树：分区布局 + 双频 EEPROM 绑定 + RTL8367S
target/linux/ramips/image/
  mt7620.mk.append.txt           # 设备定义（追加到 OpenWrt 的 mt7620.mk 末尾）
```

## 使用步骤

1. 在 GitHub 网页新建一个**公开仓库**（例如 `wdr5620-openwrt`）。
2. 把本文件夹（`openwrt-wdr5620`）里的**全部内容**解压/拖拽上传到仓库根目录（注意 `.github` 隐藏文件夹必须一并上传，网页拖拽整个文件夹即可带上）。
3. 上传后自动触发编译；也可在仓库 **Actions** 页面手动点 "Run workflow"。
4. 首次编译约 2–3 小时。结束后在 Run 页面下载 artifact `openwrt-wdr5620-v9-images`。
5. 解压得到三个镜像：
   - `*-initramfs-kernel.bin`：**内存试运行用**（uboot 菜单 1）
   - `*-sysupgrade.bin`：带元数据，OpenWrt 内部升级用
   - `*-factory.bin`：纯 kernel+rootfs 连体镜像，**uboot TFTP 写 flash 用**（菜单 2）

## 刷机流程（TTL + 原厂 uboot，不用编程器）

1. TTL 接好（115200），开机在 1 秒内按任意键进 uboot 菜单。
2. 电脑装 TFTP 服务端（如 tftpd64），把 `factory.bin`/`initramfs-kernel.bin` 放进服务目录，电脑接 LAN 口设固定 IP（uboot 会提示要的 IP，通常 192.168.0.x 段）。
3. **先选菜单 1**：`Load system code to SDRAM via TFTP`——写入 `initramfs-kernel.bin`，只在内存运行不写 flash。验证：网口通、双频 WiFi 有、LuCI 能开。这一步错了也是断电重来，不伤机。
4. 菜单 1 验证通过后，再选**菜单 2**：`Load system code then write to Flash via TFTP`——写入 `factory.bin` 到固件区。
5. **无论何时，0x0–0x20000（原厂 uboot + 产品信息 + 双频校准数据这 128KB）绝不能被覆盖。**

## 已知事项 / 风险

- 原厂 uboot 是 TPOS 体系，对裸 uImage 的启动兼容性是全计划中**唯一未实测的环节**，所以必须先用菜单 1（内存启动）验证，再落 flash。
- 首次启动若 LuCI/SSH 都不通，用 TTL 看内核日志定位（串口速率应为 115200）。
- reset/LED 按键 GPIO 未适配（板上 GPIO 定义未知，乱猜有风险），恢复手段只剩 TTL + TFTP 和编程器，请确保 TTL 线随时可接。
- 2.4G 外置 LNA/PA 的 GPIO 未配置，2.4G 发射功率可能偏低，后续可按需调。
- MAC 分配：以太网 = 原厂基址（:25），2.4G = +1，5G = +2（5G = :27 已有串口日志佐证）。
- 镜像分区：`firmware` 覆盖 0x20000–0x1000000（约 15.9MB），旧 4MB 镜像在 0x300000+ 的残留数据会被首次启动的 overlay 自动重建覆盖。
