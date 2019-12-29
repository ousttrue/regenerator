module exporter.source;
import clangdecl;
import clangparser;
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

    MacroDefinition[] m_macros;

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

    bool addDecl(UserDecl type, bool isD)
    {
        if (m_types.find(type).any())
        {
            return false;
        }

        if (isD)
        {
            if (includeModule!(core.sys.windows.windef)(type.name))
            {
                return false;
            }
            if (includeModule!(core.sys.windows.basetyps)(type.name))
            {
                return false;
            }
            if (includeModule!(core.sys.windows.winnt)(type.name))
            {
                return false;
            }
            if (includeModule!(core.sys.windows.unknwn)(type.name))
            {
                return false;
            }
        }

        m_types ~= type;
        return true;
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
