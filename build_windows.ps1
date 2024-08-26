if (-Not (Test-Path -Path depot_tools)) {
    git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
}
$env:DEPOT_TOOLS_WIN_TOOLCHAIN = '0'
$env:Path = "$(Get-Location)\depot_tools;" + $env:Path

if (-Not (Test-Path -Path angle)) {
    mkdir angle
}
if (-Not (Test-Path -Path angle\.gclient)) {
    Copy-Item .gclient_to_copy -Destination angle\.gclient
}

Set-Location -Path angle
gclient sync

gn gen out/Windows/x64 '--args=angle_build_all=false is_debug=false angle_has_frame_capture=false angle_enable_gl=false angle_enable_vulkan=false angle_enable_d3d9=false angle_enable_null=false'
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
