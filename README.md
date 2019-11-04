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
* [ ] use `core.sys.windows.windows`

## Usage

```
$ dclangen.exe -I "C:/Program Files/LLVM/include" --outdir source/libclang -H "C:/Program Files/LLVM/include/clang-c/Index.h" -H "C:/Program Files/LLVM/include/clang-c/CXString.h"
```

* `-I` IncludeDirectory
* `-H` Process Header

generate d sources to `source/libclang`

## clang command line

* https://bastian.rieck.ru/blog/posts/2015/baby_steps_libclang_ast/
* `-x c++`
