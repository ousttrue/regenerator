module exporter.processor;
import exporter.source;
import clangdecl;
import clangparser;
import clanghelper;
import sliceview;
import std.stdio;
import std.string;
import std.path;
import std.uuid;
import std.experimental.logger;

///
/// パースした型情報を変換するためにSourceに集める
///
class Processor
{
    Source[string] m_sourceMap;

    Parser m_parser;
    bool m_isD;

    this(Parser parser, bool isD)
    {
        m_parser = parser;
        m_isD = isD;
    }

    Source getSource(string path)
    {
        return m_sourceMap[path];
    }

    Source getOrCreateSource(string path)
    {
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
            Reference reference = cast(Reference) decl;
            Array array = cast(Array) decl;
            if (pointer)
            {
                decl = pointer.typeref.type;
            }
            else if (reference)
            {
                decl = reference.typeref.type;
            }
            else if (array)
            {
                decl = array.typeref.type;
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

        auto definition = structdecl;
        while (structdecl.forwardDecl)
        {
            definition = structdecl.definition;
            structdecl = cast(Struct) definition;
            if (!structdecl)
            {
                break;
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
                debug
                {
                    auto a = 0;
                }
                return;
            }
        }

        auto decl = cast(UserDecl) stripPointer(_decl[$ - 1]);
        if (!decl)
        {
            return;
        }
        // get forward decl body
        auto forwardDecl = getDefinition(decl);
        if (forwardDecl)
        {
            decl = forwardDecl;
        }

        auto dsource = getOrCreateSource(decl.path);

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
        TypeDef typedefDecl = cast(TypeDef) decl;
        Struct structDecl = cast(Struct) decl;
        if (!dsource.addDecl(decl, m_isD))
        {
            if (!typedefDecl) // fix IWICColorContext. same typedef for different locations ?
            {
                return;
            }
        }

        // next
        if (functionDecl)
        {
            addDecl(_decl ~ functionDecl.ret.type, from);
            foreach (param; functionDecl.params)
            {
                addDecl(_decl ~ param.typeref.type, from);
            }
        }
        else if (typedefDecl)
        {
            addDecl(_decl ~ typedefDecl.typeref.type, from);
        }
        else if (structDecl)
        {
            if (structDecl.iid.empty)
            {
                if (structDecl.name in m_parser.m_uuidMap)
                {
                    structDecl.iid = m_parser.m_uuidMap[structDecl.name];
                }
            }

            if (structDecl.base)
            {
                addDecl(_decl ~ structDecl.base, from);
            }
            foreach (field; structDecl.fields)
            {
                addDecl(_decl ~ field.typeref.type, from);
            }
            foreach (method; structDecl.methods)
            {
                addDecl(_decl ~ method.ret.type, from);
                foreach (param; method.params)
                {
                    addDecl(_decl ~ param.typeref.type, from);
                }
            }
        }
    }

    ///
    /// 型情報を整理する(m_sourceMapを構築する)
    ///
    void process(string[] headers)
    {
        // prepare
        m_parser.resolveTypedef();

        // gather export items
        // debug auto parsedHeaders = makeView(parser.m_headers);
        foreach (header; headers)
        {
            header = escapePath(header);
            Header exportHeader = m_parser.getHeader(header);
            if (exportHeader && !exportHeader.types.empty)
            {
                foreach (decl; exportHeader.types)
                {
                    addDecl([decl]);
                }

                // debug auto sourceView = makeView(m_sourceMap);
                auto target = getSource(header);
                target.m_macros = exportHeader.m_macros;
            }
            else
            {
                logf("%s: not found", header);
            }
        }
    }
}

Source[string] process(Parser parser, string[] headers, bool isD)
{
    auto processor = new Processor(parser, isD);
    processor.process(headers);
    return processor.m_sourceMap;
}
