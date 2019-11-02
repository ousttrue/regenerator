module libclang.CXString;
struct CXString
{
   void* data;
   uint private_flags;
}
struct CXStringSet
{
   CXString* Strings;
   uint Count;
}
extern(C) byte* clang_getCString(CXString string);
extern(C) void clang_disposeString(CXString string);
extern(C) void clang_disposeStringSet(CXStringSet* set);
