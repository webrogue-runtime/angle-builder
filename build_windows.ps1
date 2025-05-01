if (-Not (Test-Path -Path depot_tools)) {
    git clone --single-branch --depth=1 https://chromium.googlesource.com/chromium/tools/depot_tools.git
}
$env:DEPOT_TOOLS_WIN_TOOLCHAIN = '0'
$env:Path = "$(Get-Location)\depot_tools;" + $env:Path

if (-Not (Test-Path -Path angle)) {
    git clone --single-branch --depth=1 https://chromium.googlesource.com/angle/angle.git; 
    python3 dep_filter.py keep-vulkan;
}
if (-Not (Test-Path -Path angle\.gclient)) {
    Copy-Item .gclient_to_copy -Destination angle\.gclient
}

Set-Location -Path angle
gclient sync --no-history --shallow
if (-Not (Test-Path -Path chrome\VERSION)) {
    New-Item -ItemType Directory -Force -Path chrome
    "MAJOR=1" >  chrome\VERSION
    "MINOR=0" >> chrome\VERSION
    "BUILD=0" >> chrome\VERSION
    "PATCH=0" >> chrome\VERSION
}
gn gen out/Windows/x64 '--args=angle_build_all=false is_debug=false is_clang=true angle_has_frame_capture=false angle_enable_gl=false angle_enable_vulkan=true angle_enable_d3d9=false angle_enable_null=false angle_enable_wgpu=false is_official_build=true strip_debug_info=true dcheck_always_on=false chrome_pgo_phase=0 clang_use_chrome_plugins=false build_with_chromium=false angle_enable_swiftshader=false'
autoninja -C out/Windows/x64 libGLESv2 libEGL

Set-Location -Path ..
if (Test-Path -Path artifacts) {
    Remove-Item -Recurse -Force artifacts
}
mkdir artifacts
mkdir artifacts\x64
Copy-Item angle\out\Windows\x64\libGLESv2.dll -Destination artifacts\x64\libGLESv2.dll
Copy-Item angle\out\Windows\x64\libEGL.dll -Destination artifacts\x64\libEGL.dll
Compress-Archive -Path .\artifacts\x64\ -DestinationPath .\artifacts\x64.zip
