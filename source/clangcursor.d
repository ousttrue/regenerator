module clangcursor;
import std.outbuffer;
import libclang;

struct Context
{
    int level;
    bool isExternC;
    bool inStruct;

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
        return Context(level + 1, isExternC, inStruct);
    }

    Context enterStruct()
    {
        return Context(level + 1, isExternC, true);
    }
}

alias applyCallback = int delegate(CXCursor);

extern (C) CXChildVisitResult visitor(CXCursor cursor, CXCursor /* parent */ , CXCursorIterator* it)
{
    return it.call(cursor);
}

struct CXCursorIterator
{
    CXCursor cursor;
    applyCallback callback;
    int end;

    this(CXCursor cursor)
    {
        this.cursor = cursor;
    }

    int opApply(applyCallback dg)
    {
        callback = dg;
        clang_visitChildren(cursor, &visitor, &this);
        return end;
    }

    CXChildVisitResult call(CXCursor cursor)
    {
        if (callback(cursor))
        {
            end = 1;
            return CXChildVisitResult.CXChildVisit_Break;
        }

        return CXChildVisitResult.CXChildVisit_Continue;
    }
}
