#!/usr/bin/env bash
# 在 macOS 上构建「未签名」SwiftHub IPA，供 TrollStore 安装（iOS 15.4.1）
# 用法：./build-unsigned-ipa.sh [输出目录]
set -euo pipefail

OUT_DIR="${1:-$PWD/build}"
APP_NAME="SwiftHub"
BUNDLE_ID="com.yourname.swifthub"     # 改成你自己的
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "==> 1/5 清理"
rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR/Payload"

echo "==> 2/5 pod install（首次或 Podfile 变更后需要）"
cd "$PROJECT_DIR"
[ -d Pods ] || pod install --repo-update

echo "==> 3/5 xcodebuild（关闭签名）"
xcodebuild \
  -workspace "${APP_NAME}.xcworkspace" \
  -scheme "${APP_NAME}" \
  -configuration Release \
  -sdk iphoneos \
  -derivedDataPath "$OUT_DIR/dd" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGN_ENTITLEMENTS="" \
  build

APP_PATH="$OUT_DIR/dd/Build/Products/Release-iphoneos/${APP_NAME}.app"
[ -d "$APP_PATH" ] || { echo "!! 没找到构建产物：$APP_PATH"; exit 1; }

echo "==> 4/5 打 entitlements（TrollStore 会保留）"
# 关键：没有 application-identifier / keychain-access-groups 时，
# SecItemAdd 会返回 -34018，Keychain 存 token 直接失败。
cat > "$OUT_DIR/ent.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>application-identifier</key>
    <string>${BUNDLE_ID}</string>
    <key>com.apple.developer.team-identifier</key>
    <string>${BUNDLE_ID}</string>
    <key>keychain-access-groups</key>
    <array>
        <string>${BUNDLE_ID}</string>
    </array>
</dict>
</plist>
PLIST

if command -v ldid >/dev/null 2>&1; then
  ldid -S"$OUT_DIR/ent.plist" "$APP_PATH/${APP_NAME}"
  echo "    已用 ldid 打上 entitlements"
else
  echo "    !! 没装 ldid（brew install ldid），跳过；TrollStore 侧仍可安装，但 Keychain 可能报 -34018"
fi

echo "==> 5/5 打包 IPA"
cp -R "$APP_PATH" "$OUT_DIR/Payload/"
cd "$OUT_DIR"
zip -qry "${APP_NAME}-unsigned.ipa" Payload

echo
echo "完成：$OUT_DIR/${APP_NAME}-unsigned.ipa"
echo
echo "传到设备后用 TrollStore 打开安装。注意："
echo "  · 不要给二进制加 get-task-allow / dynamic-codesigning，iOS 15 的 A12+ 会启动即崩"
echo "  · 未签名包无法使用 APNs 推送（需要真实证书），SwiftHub 本来也没有推送能力"
echo "  · Bundle ID 记得与 ent.plist 一致"
