
set -ex

cd $(dirname $0)

# clone depot_tools if not exists
[ -d "depot_tools" ] || git clone --single-branch --depth=1 https://chromium.googlesource.com/chromium/tools/depot_tools.git
export PATH="$(pwd)/depot_tools:$PATH"

# clone and patch angle if not exists
if [ ! -d "angle" ]; then
    git clone --single-branch --depth=1 https://chromium.googlesource.com/angle/angle.git; 
    python3 dep_filter.py;
fi
[ -f "angle/.gclient" ] || cp .gclient_to_copy angle/.gclient


[ -d "artifacts" ] || mkdir artifacts
rm -rf artifacts/*

cd angle
gclient sync --no-history --shallow

for ENVIRONMENT in simulator device
do
    case "$ENVIRONMENT" in
        simulator)
            TARGET_CPUS="x64 arm64"
            ;;
        device)
            TARGET_CPUS="arm64"
            ;;
        *)
            echo "error: unknown ENVIRONMENT: $ENVIRONMENT"
            exit 1
            ;;
    esac
    for TARGET_CPU in $TARGET_CPUS
    do
        #todo not debug
        gn gen out/iOS/$ENVIRONMENT/$TARGET_CPU "--args=\
            is_debug=false \
            is_component_build=false \
            target_environment=\"$ENVIRONMENT\" \
            target_os=\"ios\" \
            target_cpu=\"$TARGET_CPU\" \
            angle_build_all=false \
            angle_enable_null=false \
            angle_has_frame_capture=false \
            angle_enable_gl=false \
            angle_enable_vulkan=false \
            angle_enable_d3d9=false \
            angle_enable_d3d11=false \
            angle_enable_gl=false \
            angle_enable_null=false \
            angle_enable_metal=true \
            angle_enable_essl=false \
            angle_enable_wgpu=false \
            angle_enable_glsl=true \
            dcheck_always_on=true \
            symbol_level=1 \
            ios_code_signing_identity=\"-\" \
            ios_code_signing_identity_description=\"\" \
        "
        autoninja -C out/iOS/$ENVIRONMENT/$TARGET_CPU libGLESv2 libEGL

        # mkdir ../artifacts/libEGL.xcframework/ios-$TARGET_CPU-$ENVIRONMENT/
        # cp -r out/iOS/$ENVIRONMENT/$TARGET_CPU/libEGL.framework ../artifacts/libEGL.xcframework/ios-$TARGET_CPU-$ENVIRONMENT/

        # mkdir ../artifacts/libGLESv2.xcframework/ios-$TARGET_CPU-$ENVIRONMENT/
        # cp -r out/iOS/$ENVIRONMENT/$TARGET_CPU/libGLESv2.framework ../artifacts/libGLESv2.xcframework/ios-$TARGET_CPU-$ENVIRONMENT/
    done
done


for LIB in libEGL libGLESv2
do
    cd ../artifacts
    mkdir $LIB.xcframework
    cp ../ios/$LIB.plist $LIB.xcframework/Info.plist
    mkdir $LIB.xcframework/ios-arm64-device
    cp -r ../angle/out/iOS/device/arm64/$LIB.framework $LIB.xcframework/ios-arm64-device
    mkdir $LIB.xcframework/ios-x64-arm64-simulator
    cp -r ../angle/out/iOS/simulator/arm64/$LIB.framework $LIB.xcframework/ios-x64-arm64-simulator
    rm $LIB.xcframework/ios-x64-arm64-simulator/$LIB.framework/$LIB
    lipo -create ../angle/out/iOS/simulator/arm64/$LIB.framework/$LIB ../angle/out/iOS/simulator/x64/$LIB.framework/$LIB -output $LIB.xcframework/ios-x64-arm64-simulator/$LIB.framework/$LIB
done

mkdir ios_headers
cp -r ../angle/include/EGL ../angle/include/KHR ../angle/include/GLES ../angle/include/GLES2 ../angle/include/GLES3 ios_headers
rm ios_headers/*/.clang-format
rm ios_headers/*/README.md

for DIR in libEGL.xcframework libGLESv2.xcframework ios_headers
do
    zip -vr $DIR.zip $DIR -x "*.DS_Store"
done
