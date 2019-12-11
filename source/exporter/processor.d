module exporter.processor;
import exporter.source;
import clangdecl;
import clangparser;
import clanghelper;
import sliceview;
import std.stdio;
import std.string;
import std.path;

// import std.traits;
// import std.string;
// import std.stdio;
// import std.path;
// import std.file;
// import std.algorithm;
// import clangdecl;
// import clangparser;
// import sliceview;

///
/// パースした型情報を変換するためにSourceに集める
///
class Processor
{
    Source[string] m_sourceMap;

    Source getSource(string path)
    {
        return m_sourceMap[escapePath(path)];
    }

    Source getOrCreateSource(string path)
    {
        path = escapePath(path);

        auto source = m_sourceMap.get(path, null);
        if (!source)
        {
            source = new Source(path);
            m_sourceMap[path] = source;
        }
        return source;
    }

    Decl stripPointer(Decl decl)
    {
        while (true)
        {
            Pointer pointer = cast(Pointer) decl;
            Array array = cast(Array) decl;
            if (pointer)
            {
                decl = pointer.m_typeref.type;
            }
            else if (array)
            {
                decl = array.m_typeref.type;
            }
            else
            {
                return decl;
            }
        }

        // throw new Exception("not reach here");
    }

    UserDecl getDefinition(UserDecl decl)
    {
        Struct structdecl = cast(Struct) decl;
        if (!structdecl)
        {
            return decl;
        }
        if (!structdecl.m_forwardDecl)
        {
            return decl;
        }

        auto definition = structdecl.m_definition;
        debug
        {
            if (!definition)
            {
                auto a = 0;
            }
            if (decl.m_name == "IDXGIAdapter")
            {
                auto a = 0;
            }
        }
        return definition;
    }

    void addDecl(Decl[] _decl, Source[] from = [])
    {
        foreach (d; _decl[0 .. $ - 1])
        {
            if (d == _decl[$ - 1])
            {
                // stop resursion
                return;
            }
        }

        auto decl = cast(UserDecl) stripPointer(_decl[$ - 1]);
        if (!decl)
        {
            return;
        }
        // get forward decl body
        decl = getDefinition(decl);

        auto dsource = getOrCreateSource(decl.m_path);
        dsource.addDecl(decl);

        bool found = false;
        foreach (f; from)
        {
            f.addImport(dsource);
            if (f == dsource)
            {
                found = true;
            }
        }
        if (!found)
        {
            from ~= dsource;
        }

        Function functionDecl = cast(Function) decl;
        Typedef typedefDecl = cast(Typedef) decl;
        Struct structDecl = cast(Struct) decl;
        if (functionDecl)
        {
            addDecl(_decl ~ functionDecl.m_ret, from);
            foreach (param; functionDecl.m_params)
            {
                addDecl(_decl ~ param.typeRef.type, from);
            }
        }
        else if (typedefDecl)
        {
            addDecl(_decl ~ typedefDecl.m_typeref.type, from);
        }
        else if (structDecl)
        {
            if (structDecl.m_base)
            {
                addDecl(_decl ~ structDecl.m_base, from);
            }
            foreach (field; structDecl.m_fields)
            {
                addDecl(_decl ~ field.type, from);
            }
            foreach (method; structDecl.m_methods)
            {
                addDecl(_decl ~ method.m_ret, from);
                foreach (param; method.m_params)
                {
                    addDecl(_decl ~ param.typeRef.type, from);
                }
            }
        }
    }

    ///
    /// 型情報を整理する(m_sourceMapを構築する)
    ///
    void process(Parser parser, string[] headers)
    {
        // prepare
        parser.resolveTypedef();

        // gather export items
        debug auto parsedHeaders = makeView(parser.m_headers);
        foreach (header; headers)
        {
            Header exportHeader = parser.getHeader(header);
            if (exportHeader)
            {
                foreach (decl; exportHeader.types)
                {
                    addDecl([decl]);
                }

                debug auto sourceView = makeView(m_sourceMap);
                auto target = getSource(header);
                target.m_macros = exportHeader.m_macros;
            }
            else
            {
                writefln("%s: not found", header);
            }
        }
    }
}

Source[string] process(Parser parser, string[] headers)
{
    auto processor = new Processor();
    processor.process(parser, headers);
    return processor.m_sourceMap;
}
