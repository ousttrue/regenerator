# Dlang CLANg GENerator

Parse c++ source by libclang.cindex, and generate Dlang Source.

## ToDo

* [ ] function pointer type
* [x] multi source entry point
* [ ] union
* [x] D3D11CreateDevice
* [x] interface method
* [x] interface reduce asterisk
* [ ] anonymous union
* [x] use `core.sys.windows.windows`
* [ ] com interface uuid
* [ ] com interface inheritance

## Usage

```
$ dclangen.exe -I "C:/Program Files/LLVM/include" --outdir source/libclang -H "C:/Program Files/LLVM/include/clang-c/Index.h" -H "C:/Program Files/LLVM/include/clang-c/CXString.h"
```

* `-I` IncludeDirectory
* `-H` Process Header

generate d sources to [source/libclang](./source/libclang)

### generate d3d

```
$ dclangen.exe --outdir source/d3d11 -H "C:/Program Files (x86)/Windows Kits/10/Include/10.0.17763.0/um/d3d11.h"
```

## clang command line

* https://bastian.rieck.ru/blog/posts/2015/baby_steps_libclang_ast/
* `-x c++`
