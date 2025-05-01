
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

for TARGET_CPU in x64 arm64
do
    gn gen out/Mac/$TARGET_CPU "--args=\
        is_debug=false \
        dcheck_always_on=false \
        symbol_level=0 \
        is_component_build=false \
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
        is_official_build=true \
        strip_debug_info=true \
        chrome_pgo_phase=0 \
    "
    autoninja -C out/Mac/$TARGET_CPU libGLESv2 libEGL

    mkdir ../artifacts/$TARGET_CPU
    cp out/Mac/$TARGET_CPU/libEGL.dylib out/Mac/$TARGET_CPU/libGLESv2.dylib ../artifacts/$TARGET_CPU
done

cd ../artifacts

mkdir fat
for LIB in libEGL libGLESv2
do
    lipo -create x64/$LIB.dylib arm64/$LIB.dylib -output fat/$LIB.dylib
done

for DIR in x64 arm64 fat
do
    zip -vr $DIR.zip $DIR -x "*.DS_Store"
done
