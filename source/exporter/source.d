module exporter.source;
import clangdecl;
import std.path;
import std.file;
import std.range;
import std.algorithm;
import std.traits;
import std.string;
import std.stdio;
import core.sys.windows.windef;
import core.sys.windows.basetyps;
import core.sys.windows.unknwn;

///
/// エクスポート前に型を蓄える
///
class Source
{
    string[] m_modules;

    string m_path;
    string getName()
    {
        return m_path.baseName.stripExtension;
    }

    Source[] m_imports;
    UserDecl[] m_types;

    bool empty()
    {
        return m_types.empty;
    }

    this(string path)
    {
        m_path = path;
    }

    bool includeModule(alias targetModule)(string name)
    {
        static string[] symbols = [__traits(allMembers, targetModule)];

        auto moduleName = moduleName!targetModule;

        // debug static auto symbolsView = makeView(symbols);
        if (!symbols.find(name).empty)
        {
            if (m_modules.find(moduleName).empty)
            {
                m_modules ~= moduleName;
            }
            return true;
        }
        return false;
    }

    void addDecl(UserDecl type)
    {
        if (m_types.find(type).any())
        {
            return;
        }

        if (includeModule!(core.sys.windows.windef)(type.m_name))
        {
            return;
        }
        if (includeModule!(core.sys.windows.basetyps)(type.m_name))
        {
            return;
        }
        if (includeModule!(core.sys.windows.winnt)(type.m_name))
        {
            return;
        }
        if (includeModule!(core.sys.windows.unknwn)(type.m_name))
        {
            return;
        }

        m_types ~= type;
        return;
    }

    void addImport(Source source)
    {
        if (m_path == source.m_path)
        {
            return;
        }
        if (m_imports.find(source).any())
        {
            return;
        }
        m_imports ~= source;
    }

}
