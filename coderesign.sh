#echo $env   all verable.
#EXECUTABLE_NAME 可执行变量名

#${SRCROOT} 工程目录
TEMP_PATH="${SRCROOT}/Temp"
#工程目录-存放ipa包
ASSETS_PATH="${SRCROOT}/DumpAppFiles"
#工程目录-存放dsym
DSYM_PATH="${SRCROOT}/DumpAppSymbol"
#uuid cache directory
DSYM_UUID_ROOT_PATH="~/Library/SymbolCache/dsyms/uuids"
#目标ipa包路径
TARGET_IPA_PATH="${ASSETS_PATH}/*.ipa"
#目标dSYM路径
TARGET_DSYM_PATH="${DSYM_PATH}/*.dsym"
#自定义 FridaGadget.dylib 注入库
FRIDA_PATH="/Users/kuperxu/Documents/reverse_engine/Frida/FridaGadget.dylib"

#----------------------------------------
# 1. 解压IPA到Temp下
#清空Temp文件夹
rm -rf "${SRCROOT}/Temp"
mkdir -p "${SRCROOT}/Temp"
unzip -oqq "$TARGET_IPA_PATH" -d "$TEMP_PATH"
# 拿到解压的临时的APP的路径
TEMP_APP_PATH=$(set -- "$TEMP_PATH/Payload/"*.app;echo "$1")
 echo "路径是:$TEMP_APP_PATH"

#----------------------------------------
# 2. 将解压出来的.app拷贝进入工程下
# BUILT_PRODUCTS_DIR 工程生成的APP包的路径
# TARGET_NAME target名称
# BUILT_PRODUCTS_DIR="${SRCROOT}/target"
TARGET_APP_PATH="$BUILT_PRODUCTS_DIR/$TARGET_NAME.app"
echo "app路径:$TARGET_APP_PATH"

rm -rf "$TARGET_APP_PATH"
mkdir -p "$TARGET_APP_PATH"
cp -rf "$TEMP_APP_PATH/" "$TARGET_APP_PATH"

#----------------------------------------
# 3. 个人证书没法签名Extention,删除extension和WatchAPP.
rm -rf "$TARGET_APP_PATH/PlugIns"
rm -rf "$TARGET_APP_PATH/Watch"

#----------------------------------------
# 4. 更新info.plist文件 CFBundleIdentifier
#  设置:"Set : KEY Value" "目标文件路径"
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $PRODUCT_BUNDLE_IDENTIFIER" "$TARGET_APP_PATH/Info.plist"

#----------------------------------------
# 5. 给MachO文件上执行权限
# 获取被注入可执行文件的macho名字
APP_BINARY=`plutil -convert xml1 -o - $TARGET_APP_PATH/Info.plist|grep -A1 Exec|tail -n1|cut -f2 -d\>|cut -f1 -d\<`
#上可执行权限
chmod +x "$TARGET_APP_PATH/$APP_BINARY"

##----------------------------------------
## 6. 使用optool 注入Frida
## Frida打包入APP，FRIDA_PATH修改为本地Frida路径 - Frida 需要自定义
## 这里要注意这里的签名不能和工程里面的 Embedded 相冲突。
## 如果把FridaGadget设置成了embed&sign那么这里copy&sign就不需要做了。但是还是要有注入这一步。
#mkdir -p "$TARGET_APP_PATH/Frameworks"
#TARGET_FRIDA_PATH="$TARGET_APP_PATH/Frameworks/FridaGadget.dylib"
#cp "$FRIDA_PATH" "$TARGET_FRIDA_PATH"
#optool install -c load -p "@executable_path/Frameworks/FridaGadget.dylib" -t "$TARGET_APP_PATH/$APP_BINARY"
#echo $executable_path

#----------------------------------------
# 7. 重签名第三方 FrameWorks
TARGET_APP_FRAMEWORKS_PATH="$TARGET_APP_PATH/Frameworks"
if [ -d "$TARGET_APP_FRAMEWORKS_PATH" ];
then
for FRAMEWORK in "$TARGET_APP_FRAMEWORKS_PATH/"*
do
echo $FRAMEWORK
/usr/bin/codesign --force --sign "$EXPANDED_CODE_SIGN_IDENTITY" "$FRAMEWORK"

done
fi

#----------------------------------------
#todo list
#- traverse dsym read uuid, build soft link to dsym cache. 4 bytes each
#    FB53A898-119B-3272-A783-96626DAA26AD >>> FB53/A898/119B/3272/A78396626DAA26AD
#- find value for key:DBGArchitecture,DBGBuildSourcePath,DBGSourcePath,DBGDSYMPath,DBGSourcePathRemapping,
#- mkdir uuid.plist save DBGSourcePathRemapping DBGSourcePath .. & DBGVersion:3
#----------------------------------------
# 8. 索引dsym--索引到uuid分为五组的 dsym caches 中
linksoft() {
    mkdir targetDsymSoftPath
    ln -s "originfile" "targetFile"
}

#清除数据
clearCaches() {
    rm -rf "${SRCROOT}/Temp"
}

clearCaches
