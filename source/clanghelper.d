module clanghelper;
import std.string;
import std.conv;
import libclang;

CXTranslationUnitImpl* getTU(void* index, string header, string[] params)
{
    byte*[] c_params;
    foreach (param; params)
    {
        c_params ~= cast(byte*) param.toStringz();
    }
    return clang_createTranslationUnitFromSourceFile(index,
            cast(byte*) header.toStringz(), cast(int) params.length, c_params.ptr, 0, null);
}

string CXStringToString(CXString cxs)
{
    auto p = clang_getCString(cxs);
    return to!string(cast(immutable char*) p);
}

string function(T) cxToString(T)(CXString function(T) func)
{
    return (T _) => {
        auto name = func(T);
        scope (exit)
            clang_disposeString(name);

        return CXStringToString(name);
    };
}

string getCursorKindName(CXCursorKind cursorKind)
{
    auto kindName = clang_getCursorKindSpelling(cursorKind);
    scope (exit)
        clang_disposeString(kindName);

    return CXStringToString(kindName);
}

string getCursorSpelling(CXCursor cursor)
{
    auto cursorSpelling = clang_getCursorSpelling(cursor);
    scope (exit)
        clang_disposeString(cursorSpelling);

    return CXStringToString(cursorSpelling);
}

string getCursorTypeKindName(CXTypeKind typeKind)
{
    auto kindName = clang_getTypeKindSpelling(typeKind);
    scope (exit)
        clang_disposeString(kindName);

    return CXStringToString(kindName);
}

struct Location
{
	string path;
	int line;
}

Location getCursorLocation(CXCursor cursor)
{
	auto location = clang_getCursorLocation(cursor);
	void* file;
	uint line;
	uint column;
	uint offset;
	clang_getInstantiationLocation(location, &file, &line, &column, &offset);
	auto path = CXStringToString(clang_getFileName(file));
	return Location(path, line);
}
