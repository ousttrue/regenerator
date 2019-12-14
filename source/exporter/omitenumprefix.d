module exporter.omitenumprefix;
import std.string;
import clangdecl : Enum;

immutable string[string] replace_map;

shared static this()
{
    replace_map = [
        "_D3D_PARAMETER_FLAGS": "D3D_PF_", //
        "_D3D_SHADER_VARIABLE_TYPE": "D3D_SVT_", //
        "_D3D_SHADER_VARIABLE_CLASS": "D3D_SVC_", ///
        "_D3D_RESOURCE_RETURN_TYPE": "D3D_RETURN_TYPE_", //
        "_D3D_CBUFFER_TYPE": "D3D_CT_", //
        "_D3D_SHADER_INPUT_TYPE": "D3D_SIT_", //
        "_D3D_SHADER_VARIABLE_FLAGS": "D3D_SVF_", //
        "_D3D_SHADER_INPUT_FLAGS": "D3D_SIF_", //
        "_D3D_SHADER_CBUFFER_FLAGS": "D3D_CBF_", //
        "_D3D_INCLUDE_TYPE": "D3D_INCLUDE_", //
        "D3D_RESOURCE_RETURN_TYPE": "D3D_RETURN_TYPE_", //
        "D3D_REGISTER_COMPONENT_TYPE": "D3D_REGISTER_COMPONENT_", //
        "D3D_TESSELLATOR_OUTPUT_PRIMITIVE": "D3D_TESSELLATOR_OUTPUT_", //
    ];
}

string getOmitEnumNameForWindows(string name)
{
    if (name in replace_map)
    {
        return replace_map[name];
    }

    return name ~ '_';
}

immutable clangEnumSuffix = [
    "Kind", "Flags", "Severity", "DisplayOptions", "Property"
];

string getOmitEnumName(string name)
{
    debug if (name == "CXSaveError")
    {
        auto a = 0;
    }

    if (name.indexOf('_') != -1)
    {
        return getOmitEnumNameForWindows(name);
    }
    else
    {
        // for clang
        foreach (suffix; clangEnumSuffix)
        {
            if (name.endsWith(suffix))
            {
                return name[0 .. $ - suffix.length] ~ '_';
            }
        }

        return name ~ '_';
    }
}

void omit(Enum decl)
{
    auto prefix = decl.getValuePrefix();
    if (prefix.length > 1 && prefix[$ - 1] == '_')
    {
        for (int i = 0; i < decl.m_values.length; ++i)
        {
            auto name = decl.m_values[i].name;
            decl.m_values[i].name = name[prefix.length - 1 .. $];
        }
    }
    else
    {
        auto omitName = getOmitEnumName(decl.m_name);
        for (int i = 0; i < decl.m_values.length; ++i)
        {
            auto name = decl.m_values[i].name;
            if (name.startsWith(omitName))
            {
                // "D3D_SRV_DIMENSION_UNKNOWN" => "_UNKNOWN"
                decl.m_values[i].name = name[omitName.length - 1 .. $];
            }
        }
    }
}
