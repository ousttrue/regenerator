// cpptypeinfo generated
module libclang.CXString;

import core.sys.windows.windef;
import core.sys.windows.com;


struct CXString{
    void* data;
    uint private_flags;
}

struct CXStringSet{
    CXString* Strings;
    uint Count;
}

extern(C) byte* clang_getCString(CXString string) nothrow;
extern(C) void clang_disposeString(CXString string) nothrow;
extern(C) void clang_disposeStringSet(CXStringSet* set) nothrow;
