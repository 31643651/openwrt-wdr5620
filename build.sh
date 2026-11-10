#!/bin/bash
set -euo pipefail

SRC=openwrt
rm -rf "$SRC"

git clone --depth 1 --branch v24.10.1 https://github.com/openwrt/openwrt.git "$SRC"
cd "$SRC"

# strip CRLF that GitHub web-upload may introduce
sed -i 's/\r$//' \
	../target/linux/ramips/dts/mt7620a_tplink_wdr5620-v9.dts \
	../target/linux/ramips/image/mt7620.mk.append.txt \
	../openwrt.config

cp ../target/linux/ramips/dts/mt7620a_tplink_wdr5620-v9.dts target/linux/ramips/dts/
cat ../target/linux/ramips/image/mt7620.mk.append.txt >> target/linux/ramips/image/mt7620.mk

./scripts/feeds update -a
./scripts/feeds install -a

cp ../openwrt.config .config
make defconfig

make -j"$(nproc)" || make -j1 V=s
ls -lh bin/targets/ramips/mt7620/
