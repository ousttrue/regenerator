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
* [x] function default parameter
* [x] lua interface
* [x] `const char *` to `const char *`. not `byte *`
* [ ] c++ namespace

## Usage

### libclang

```
$ regenerator.exe lua/d_libclang.lua {clang_include_dir} {d_generate_dir}
```

[generated](source/libclang)

### liblua

```
$ regenerator.exe lua/d_liblua.lua {lua_src_dir} {d_generate_dir}
```

[generated](source/liblua)

### d3d11

```
$ regenerator.exe lua/d_d3d11.lua {d_generate_dir}
```

generate d3d11.d from latest `C:/Program Files (x86)/Windows Kits/10/Include`
