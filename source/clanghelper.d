module clanghelper;
import std.string;
import std.conv;
import std.file;
import std.array;
import libclang;

CXTranslationUnitImpl* getTU(void* index, string[] headers, string[] params)
{
    byte*[] c_params;
    foreach (param; params)
    {
        c_params ~= cast(byte*) param.toStringz();
    }

    auto options = CXTranslationUnit_Flags.CXTranslationUnit_DetailedPreprocessingRecord
        | CXTranslationUnit_Flags.CXTranslationUnit_SkipFunctionBodies;
    if (headers.length == 1)
    {
        return clang_parseTranslationUnit(index, cast(byte*) headers[0].toStringz(),
                c_params.ptr, cast(int) params.length, null, 0, options);
    }
    else
    {
        auto sb = appender!string;
        foreach (header; headers)
        {
            sb.put(format("#include \"%s\"\n", header));
        }

        struct Source
        {
            string path;
            string content;
        }

        auto source = Source("__tmp__dclangen__.h", sb.data);

        // use unsaved files
        CXUnsavedFile[] files;
        files ~= CXUnsavedFile(cast(byte*) source.path.ptr,
                cast(byte*) source.content.ptr, cast(uint) source.content.length);

        return clang_parseTranslationUnit(index, cast(byte*) "__tmp__dclangen__.h".toStringz(),
                c_params.ptr, cast(int) params.length, files.ptr, cast(uint) files.length, options);
    }
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
    int begin;
    int end;
}

Location getCursorLocation(CXCursor cursor)
{
    auto location = clang_getCursorLocation(cursor);
    if (clang_equalLocations(location, clang_getNullLocation()))
    {
        return Location();
    }
    void* file;
    uint line;
    uint column;
    uint offset;
    clang_getInstantiationLocation(location, &file, &line, &column, &offset);
    if (!file)
    {
        return Location();
    }
    auto path = CXStringToString(clang_getFileName(file));
    if (!path.length)
    {
        return Location();
    }
    path = escapePath(path);

    auto extent = clang_getCursorExtent(cursor);
    // auto begin = clang_getRangeStart(extent);
    auto end = clang_getRangeEnd(extent);

    CXFile endFile;
    uint endLine;
    uint endColumn;
    uint endOffset;
    clang_getInstantiationLocation(end, &endFile, &endLine, &endColumn, &endOffset);

    return Location(path, line, offset, endOffset);
}

CXSourceRange getRange(CXCursor cursor)
{
    auto extent = clang_getCursorExtent(cursor);
    auto begin = clang_getRangeStart(extent);
    auto end = clang_getRangeEnd(extent);
    auto range = clang_getRange(begin, end);
    return range;
}

CXToken[] getTokens(CXCursor cursor)
{
    auto range = clang_getCursorExtent(cursor);

    CXToken* tokens;
    uint num;
    auto tu = clang_Cursor_getTranslationUnit(cursor);
    clang_tokenize(tu, range, &tokens, &num);

    return tokens[0 .. num];
}

string tokenToString(CXCursor cursor, CXToken token)
{
    auto tu = clang_Cursor_getTranslationUnit(cursor);
    auto tokenSpelling = clang_getTokenSpelling(tu, token);
    scope (exit)
        clang_disposeString(tokenSpelling);
    return CXStringToString(tokenSpelling);
}

string TerminatedString(string src)
{
    auto x = toStringz(src);
    auto y = x[0 .. src.length + 1];
    return to!string(y.ptr);
}

string escapePath(string src)
{
    auto escaped = src.replace("\\", "/");
    version (Windows)
    {
        escaped = escaped.toLower();
    }
    return escaped;
}
