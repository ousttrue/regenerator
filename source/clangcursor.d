module clangcursor;
import std.outbuffer;
import libclang;

struct Context
{
    int level;
    bool isExternC;
    string[] namespace;

    string getIndent()
    {
        auto buf = new OutBuffer();
        for (int i = 0; i < level; ++i)
        {
            buf.write("  ");
        }
        return buf.toString();
    }

    Context getChild()
    {
        return Context(level + 1, isExternC, namespace);
    }

    Context enterNamespace(string ns)
    {
        return Context(level, isExternC, namespace ~ ns);
    }
}

struct CursorList
{
    CXCursor[] cursors;
}

extern (C) CXChildVisitResult visitor(CXCursor cursor, CXCursor /* parent */ , void* list)
{
    (cast(CursorList*) list).cursors ~= cursor;
    return CXChildVisitResult._Continue;
}

CXCursor[] getChildren(CXCursor cursor)
{
    CursorList list;
    clang_visitChildren(cursor, &visitor, &list);
    return list.cursors;
}
