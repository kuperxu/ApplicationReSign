#${SRCROOT} 工程目录
TEMP_PATH="${SRCROOT}/Temp"
#资源文件夹，我们提前在工程目录下新建一个APP文件夹，里面放ipa包
ASSETS_PATH="${SRCROOT}/BreakJailAPP"
#目标ipa包路径
TARGET_IPA_PATH="${ASSETS_PATH}/*.ipa"

FRIDA_PATH="/Users/kuperxu/Documents/reverse_engine/Frida/FridaGadget.dylib"

#清空Temp文件夹
rm -rf "${SRCROOT}/Temp"
mkdir -p "${SRCROOT}/Temp"

#----------------------------------------
# 1. 解压IPA到Temp下
unzip -oqq "$TARGET_IPA_PATH" -d "$TEMP_PATH"
# 拿到解压的临时的APP的路径
TEMP_APP_PATH=$(set -- "$TEMP_PATH/Payload/"*.app;echo "$1")
 echo "路径是:$TEMP_APP_PATH"
 
# 获取被注入可执行文件的macho名字
last_component=$(basename "$TEMP_APP_PATH")
MACHO_NAME=${last_component%.*}
echo $MACHO_NAME

#----------------------------------------
# 2.Frida打包入APP，FRIDA_PATH修改为本地Frida路径 - Frida 需要自定义
mkdir -p "$TEMP_APP_PATH/Frameworks"
TARGET_FRIDA_PATH="$TEMP_APP_PATH/Frameworks/FridaGadget.dylib"
cp "$FRIDA_PATH" "$TARGET_FRIDA_PATH"

echo $TARGET_FRIDA_PATH

#----------------------------------------
# 3. 将解压出来的.app拷贝进入工程下
# BUILT_PRODUCTS_DIR 工程生成的APP包的路径
# TARGET_NAME target名称
# BUILT_PRODUCTS_DIR="${SRCROOT}/target"
TARGET_APP_PATH="$BUILT_PRODUCTS_DIR/$TARGET_NAME.app"
echo "app路径:$TARGET_APP_PATH"

rm -rf "$TARGET_APP_PATH"
mkdir -p "$TARGET_APP_PATH"
cp -rf "$TEMP_APP_PATH/" "$TARGET_APP_PATH"

#----------------------------------------
# 4. 删除extension和WatchAPP.个人证书没法签名Extention
rm -rf "$TARGET_APP_PATH/PlugIns"
rm -rf "$TARGET_APP_PATH/Watch"

#----------------------------------------
# 5. 更新info.plist文件 CFBundleIdentifier
#  设置:"Set : KEY Value" "目标文件路径"
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $PRODUCT_BUNDLE_IDENTIFIER" "$TARGET_APP_PATH/Info.plist"

#----------------------------------------
# 6. 给MachO文件上执行权限
# 拿到MachO文件的路径
APP_BINARY=`plutil -convert xml1 -o - $TARGET_APP_PATH/Info.plist|grep -A1 Exec|tail -n1|cut -f2 -d\>|cut -f1 -d\<`
#上可执行权限
chmod +x "$TARGET_APP_PATH/$APP_BINARY"

#----------------------------------------
# 7. 使用optool 注入Frida
optool install -c load -p "$TARGET_FRIDA_PATH" -t "$TEMP_APP_PATH/$MACHO_NAME"

#----------------------------------------
# 6. 重签名第三方 FrameWorks
TARGET_APP_FRAMEWORKS_PATH="$TARGET_APP_PATH/Frameworks"
if [ -d "$TARGET_APP_FRAMEWORKS_PATH" ];
then
for FRAMEWORK in "$TARGET_APP_FRAMEWORKS_PATH/"*
do

# 7. s签名
/usr/bin/codesign --force --sign "$EXPANDED_CODE_SIGN_IDENTITY" "$FRAMEWORK"
/usr/bin/codesign --force --sign "$EXPANDED_CODE_SIGN_IDENTITY" "$TARGET_FRIDA_PATH"

#清除数据
#rm -rf "${SRCROOT}/Temp"
done
fi
