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

// "D3D_SRV_DIMENSION_UNKNOWN" => "_UNKNOWN"
void omit(Enum decl)
{
    // すべての値の共通のprefixを得る
    auto prefix = decl.getValuePrefix();
    if (!prefix.empty)
    {
        if (prefix[$ - 1] != '_')
        {
            // '_' で終わるように調整
            auto us = prefix.lastIndexOf('_');
            if (us != -1)
            {
                prefix = prefix[0 .. us + 1];
            }
        }
    }

    if (decl.m_values.length > 1 && prefix.length > 1 && prefix[$ - 1] == '_')
    {
        // perfixを省略
        for (int i = 0; i < decl.m_values.length; ++i)
        {
            auto name = decl.m_values[i].name;
            decl.m_values[i].name = name[prefix.length - 1 .. $];
        }
    }
    else
    {
        auto omitName = (decl.m_name in replace_map) //
         ? replace_map[decl.m_name] // 不定形
         : decl.m_name ~ '_' // 型名
        ;

        for (int i = 0; i < decl.m_values.length; ++i)
        {
            auto name = decl.m_values[i].name;
            if (name.startsWith(omitName))
            {
                // 省略名で始まるものだけ
                // '_' で始まるようにする(0-9で始まる場合在り)
                decl.m_values[i].name = name[omitName.length - 1 .. $];
            }
        }
    }
}
