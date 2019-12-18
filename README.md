# reGenerator

* Parse c++ source by libclang.cindex
* Generate source

## WIP: lua interface

* complex argument(include, define, extern C etc...)
* output function filtering
* type mapping
* symbol escape
* source template
* library specific hard coding(macro)

## dependencies

* libclang
* lua

## ToDo

* [ ] function pointer type
* [x] multi source entry point
* [ ] union
* [x] anonymous union
* [ ] anonymous struct
* [x] D3D11CreateDevice
* [x] interface method
* [x] interface reduce asterisk
* [x] use `core.sys.windows.windows` 
* [x] com interface uuid
* [x] com interface inheritance
* [x] macro definition value
* [ ] function default parameter
* [ ] lua interface
* [ ] `const char *` to `const char *`. not `byte *`

## Usage

* `--outdir` Output Directory: remove if exists, then write exported files
* `-I` Include Directory: clang argument
* `-D` Define
* `-H` Process Header: file that contains functions and macro definitions
* `-E` omit enum prefix

### libclang

``` 
$ dclangen.exe -I "C:/Program Files/LLVM/include" --outdir source/libclang -H "C:/Program Files/LLVM/include/clang-c/Index.h" -H "C:/Program Files/LLVM/include/clang-c/CXString.h"
```

### d3d11.h

``` 
$ dclangen.exe --outdir source/d3d11 -H "C:/Program Files (x86)/Windows Kits/10/Include/10.0.17763.0/um/d3d11.h -H "C:/Program Files (x86)/Windows Kits/10/Include/10.0.17763.0/shared/dxgi.h"
```
### imgui.h

### lua.h

## clang command line

* https://bastian.rieck.ru/blog/posts/2015/baby_steps_libclang_ast/
* `-x c++` 
