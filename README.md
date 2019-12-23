# reGenerator

* Parse c++ source by libclang.cindex
* Generate source

## dependencies

* libclang in LLVM-9.0 
* https://github.com/lua/lua/tree/v5.3.5

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
* [x] lua interface
* [x] `const char *` to `const char *`. not `byte *`

## Usage

```
$ regenerator.exe scripts/liblua.lua {args...}
```
