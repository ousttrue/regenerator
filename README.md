# Dlang CLANg GENerator

Parse c++ source by libclang.cindex, and generate Dlang Source.

## ToDo

* [ ] function pointer type
* [x] multi source entry point
* [ ] union
* [ ] anonymous union
* [ ] anonymous struct
* [x] D3D11CreateDevice
* [x] interface method
* [x] interface reduce asterisk
* [x] use `core.sys.windows.windows`
* [x] com interface uuid
* [x] com interface inheritance
* [x] macro definition value

## Usage

```
$ dclangen.exe -I "C:/Program Files/LLVM/include" --outdir source/libclang -H "C:/Program Files/LLVM/include/clang-c/Index.h" -H "C:/Program Files/LLVM/include/clang-c/CXString.h"
```

* `-I` IncludeDirectory: clang argument
* `-H` Process Header: file that contains functions and macro definitions

generate d sources to [source/libclang](./source/libclang)

### generate d3d

```
$ dclangen.exe --outdir source/d3d11 -H "C:/Program Files (x86)/Windows Kits/10/Include/10.0.17763.0/um/d3d11.h -H "C:/Program Files (x86)/Windows Kits/10/Include/10.0.17763.0/shared/dxgi.h"
```

## clang command line

* https://bastian.rieck.ru/blog/posts/2015/baby_steps_libclang_ast/
* `-x c++`
