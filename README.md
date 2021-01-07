### Binaries compilation with lipo

1. Build the _FastPdfKit-iphoneos_ target for _Any iOS Device_. Grab the generated _libFastPdfKit-iphoneos.a_ binary or save its path.
2. Build the _FastPdfKit-iphonesimulator_ target for any simulator in the list. Grab the generated _libFastPdfKit-iphonesimulator.a_ binary or save its path.
3. Open the terminal and use the following command:
```
lipo -create IPHONEOS_PATH SIMULATOR_PATH -output FAT_DEST_PATH
```
where `IPHONEOS_PATH` is the binary path obtained at step 1, `SIMULATOR_PATH` is the path obtained at step 2 and `FAT_DEST_PATH` is the
destination path for the fat library.
