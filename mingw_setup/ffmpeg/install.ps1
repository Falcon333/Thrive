param(
    [string]$MINGW_ENV
)

##########
# FFMPEG #
##########

Write-Output "--- Installing FFMPEG ---"

$DIR = Split-Path $MyInvocation.MyCommand.Path

#################
# Include utils #
#################

. (Join-Path "$DIR\.." "utils.ps1")

############################
# Create working directory #
############################

$WORKING_DIR = Join-Path $MINGW_ENV temp\ffmpeg

mkdir $WORKING_DIR -force | out-null

###################
# Check for 7-Zip #
###################

$7z = Join-Path $MINGW_ENV "temp\7zip\7za.exe"
if (-Not (Get-Command $7z -errorAction SilentlyContinue))
{
    return $false
}

####################
# Download archive #
####################


$REMOTE_DIR="https://github.com/Revolutionary-Games/ogre-ffmpeg-videoplayer/archive"

$LIB_NAME="master"

$ARCHIVE=$LIB_NAME + ".zip"

$DESTINATION = Join-Path $WORKING_DIR $ARCHIVE

if (-Not (Test-Path $DESTINATION)) {
    Write-Output "Downloading archive..."
    $CLIENT = New-Object System.Net.WebClient
    $CLIENT.DownloadFile("$REMOTE_DIR/$ARCHIVE", $DESTINATION)
}
else {
    Write-Output "Found archive file, skipping download."
}



#Download FFMPEG dependency libraries
$DESTINATION2 = Join-Path $WORKING_DIR "ffmpeg-20150828-git-628a73f-win32-dev.7z"
if (-Not (Test-Path $DESTINATION2)) {
    Write-Output "Downloading archive..."
    $CLIENT = New-Object System.Net.WebClient
    $CLIENT.DownloadFile("http://ffmpeg.zeranoe.com/builds/win32/dev/ffmpeg-20150828-git-628a73f-win32-dev.7z", $DESTINATION2)
}
else {
    Write-Output "Found archive file, skipping download."
}
#Download FFMPEG dependency binaries
$DESTINATION3 = Join-Path $WORKING_DIR "ffmpeg-20150828-git-628a73f-win32-shared.7z"
if (-Not (Test-Path $DESTINATION3)) {
    Write-Output "Downloading archive..."
    $CLIENT = New-Object System.Net.WebClient
    $CLIENT.DownloadFile("http://ffmpeg.zeranoe.com/builds/win32/shared/ffmpeg-20150828-git-628a73f-win32-shared.7z", $DESTINATION3)
}
else {
    Write-Output "Found archive file, skipping download."
}




##########
# Unpack #
##########

Write-Output "Unpacking archive..."

$ARGUMENTS = "x",
             "-y",
             "-o$WORKING_DIR",
             $DESTINATION
             
& $7z $ARGUMENTS | out-null

$ARGUMENTS = "x",
             "-y",
             "-o$WORKING_DIR",
             $DESTINATION2
             
& $7z $ARGUMENTS | out-null

$ARGUMENTS = "x",
             "-y",
             "-o$WORKING_DIR",
             $DESTINATION3
             
& $7z $ARGUMENTS | out-null

###########
# Compile #
###########

Write-Output "Compiling..."

$env:Path += (Join-Path $MINGW_ENV bin) + ";"

$TOOLCHAIN_FILE="$MINGW_ENV/cmake/toolchain.cmake"

$BUILD_TYPES = @("Debug", "Release")

foreach ($BUILD_TYPE in $BUILD_TYPES) {

    $BUILD_DIR = Join-Path $WORKING_DIR "build-$BUILD_TYPE"

    mkdir $BUILD_DIR -force

    pushd $BUILD_DIR

    $ARGUMENTS =
        "-DCMAKE_TOOLCHAIN_FILE=$TOOLCHAIN_FILE",
        "-DOGRE_HOME:path=$MINGW_ENV/OgreSDK",
        "-DFFMPEG_LIBRARIES=$MINGW_ENV/temp/ffmpeg/ffmpeg-20150828-git-628a73f-win32-dev/lib",
        "-DFFMPEG_INCLUDE_DIRS=$MINGW_ENV/temp/ffmpeg/ffmpeg-20150828-git-628a73f-win32-dev/include",
        "-DAVCODEC_LIBRARIES=$MINGW_ENV/temp/ffmpeg/ffmpeg-20150828-git-628a73f-win32-dev/lib",
        "-DAVCODEC_INCLUDE_DIRS=$MINGW_ENV/temp/ffmpeg/ffmpeg-20150828-git-628a73f-win32-dev/include",
        "-DAVFORMAT_LIBRARIES=$MINGW_ENV/temp/ffmpeg/ffmpeg-20150828-git-628a73f-win32-dev/lib",
        "-DAVFORMAT_INCLUDE_DIRS=$MINGW_ENV/temp/ffmpeg/ffmpeg-20150828-git-628a73f-win32-dev/include",
        "-DAVUTIL_LIBRARIES=$MINGW_ENV/temp/ffmpeg/ffmpeg-20150828-git-628a73f-win32-dev/lib",
        "-DAVUTIL_INCLUDE_DIRS=$MINGW_ENV/temp/ffmpeg/ffmpeg-20150828-git-628a73f-win32-dev/include",
        "-DSWSCALE_LIBRARIES=$MINGW_ENV/temp/ffmpeg/ffmpeg-20150828-git-628a73f-win32-dev/lib",
        "-DSWSCALE_INCLUDE_DIRS=$MINGW_ENV/temp/ffmpeg/ffmpeg-20150828-git-628a73f-win32-dev/include",
        "-DSWRESAMPLE_LIBRARIES=$MINGW_ENV/temp/ffmpeg/ffmpeg-20150828-git-628a73f-win32-dev/lib",
        "-DSWRESAMPLE_INCLUDE_DIRS=$MINGW_ENV/temp/ffmpeg/ffmpeg-20150828-git-628a73f-win32-dev/include",
        "-DCMAKE_CXX_FLAGS:string=-mstackrealign -msse2",
        "-DBUILD_VIDEOPLAYER_DEMO=OFF",
        "-DCMAKE_BUILD_TYPE=$BUILD_TYPE",
        "$WORKING_DIR/ogre-ffmpeg-videoplayer-master"

    & (Join-Path $MINGW_ENV cmake\bin\cmake) -G "CodeBlocks - MinGW Makefiles" $ARGUMENTS

    & $MINGW_ENV/bin/mingw32-make -j4 all | Tee-Object -FilePath compileroutput.txt

    Copy-Item "$BUILD_DIR/libogre-ffmpeg-videoplayer.a" -destination "$MINGW_ENV/install/lib/$BUILD_TYPE/libogre-ffmpeg-videoplayer.a" -Recurse -Force
    popd

}
Copy-Item "$MINGW_ENV/temp/ffmpeg/ffmpeg-20150828-git-628a73f-win32-dev/lib/libavcodec.dll.a" -destination "$MINGW_ENV/install/lib/libavcodec.dll.a" -Recurse -Force
Copy-Item "$MINGW_ENV/temp/ffmpeg/ffmpeg-20150828-git-628a73f-win32-dev/lib/libavformat.dll.a" -destination "$MINGW_ENV/install/lib/libavformat.dll.a" -Recurse -Force
Copy-Item "$MINGW_ENV/temp/ffmpeg/ffmpeg-20150828-git-628a73f-win32-dev/lib/libavutil.dll.a" -destination "$MINGW_ENV/install/lib/libavutil.dll.a" -Recurse -Force
Copy-Item "$MINGW_ENV/temp/ffmpeg/ffmpeg-20150828-git-628a73f-win32-dev/lib/libswscale.dll.a" -destination "$MINGW_ENV/install/lib/libswscale.dll.a" -Recurse -Force
Copy-Item "$MINGW_ENV/temp/ffmpeg/ffmpeg-20150828-git-628a73f-win32-dev/lib/libswresample.dll.a" -destination "$MINGW_ENV/install/lib/libswresample.dll.a" -Recurse -Force
Copy-Item "$MINGW_ENV/temp/ffmpeg/ffmpeg-20150828-git-628a73f-win32-shared/bin/avcodec-56.dll" -destination "$MINGW_ENV/install/bin/avcodec-56.dll" -Recurse -Force
Copy-Item "$MINGW_ENV/temp/ffmpeg/ffmpeg-20150828-git-628a73f-win32-shared/bin/avformat-56.dll" -destination "$MINGW_ENV/install/bin/avformat-56.dll" -Recurse -Force
Copy-Item "$MINGW_ENV/temp/ffmpeg/ffmpeg-20150828-git-628a73f-win32-shared/bin/avutil-54.dll" -destination "$MINGW_ENV/install/bin/avutil-54.dll" -Recurse -Force
Copy-Item "$MINGW_ENV/temp/ffmpeg/ffmpeg-20150828-git-628a73f-win32-shared/bin/swscale-3.dll" -destination "$MINGW_ENV/install/bin/swscale-3.dll" -Recurse -Force
Copy-Item "$MINGW_ENV/temp/ffmpeg/ffmpeg-20150828-git-628a73f-win32-shared/bin/swresample-1.dll" -destination "$MINGW_ENV/install/bin/swresample-1.dll" -Recurse -Force

if(!(Test-Path -Path "$MINGW_ENV/install/include/ogre-ffmpeg/" )){
    New-Item "$MINGW_ENV/install/include/ogre-ffmpeg/" -type directory
}

Copy-Item "$MINGW_ENV/temp/ffmpeg/ogre-ffmpeg-videoplayer-master/src/*.hpp" "$MINGW_ENV/install/include/ogre-ffmpeg/"  -Recurse -Force

Copy-Item "$MINGW_ENV/temp/ffmpeg/ffmpeg-20150828-git-628a73f-win32-dev/include/*" "$MINGW_ENV/install/include/" -Recurse -Force

