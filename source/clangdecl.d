module clangdecl;
import std.range;
import std.string;
import std.typecons;
import std.uuid;
import std.algorithm;
import libclang;

class Decl
{
}

struct TypeRef
{
    Decl type;
    bool isConst;
}

class Pointer : Decl
{
    TypeRef m_typeref;

    this(Decl type, bool isConst = false)
    {
        m_typeref = TypeRef(type, isConst);
    }
}

class Array : Decl
{
    TypeRef m_typeref;
    long m_size;

    this(Decl type, long size, bool isConst = false)
    {
        m_typeref = TypeRef(type, isConst);
        m_size = size;
    }
}

class Primitive : Decl
{
}

class Void : Primitive
{
}

class Bool : Primitive
{
}

class Int8 : Primitive
{
}

class Int16 : Primitive
{
}

class Int32 : Primitive
{
}

class Int64 : Primitive
{
}

class UInt8 : Primitive
{
}

class UInt16 : Primitive
{
}

class UInt32 : Primitive
{
}

class UInt64 : Primitive
{
}

class Float : Primitive
{
}

class Double : Primitive
{
}

class LongDouble : Primitive
{
}

class UserDecl : Decl
{
    string m_path;
    int m_line;
    string m_name;

    protected this(string path, int line, string name)
    {
        m_path = path;
        m_line = line;
        m_name = name;
    }
}

struct Field
{
    string name;
    Decl type;
}

class Struct : UserDecl
{
    bool m_isUnion;

    UserDecl m_base;
    Field[] m_fields;
    Function[] m_methods;

    bool m_forwardDecl;

    // forwardDecl definition
    Struct m_definition;

    // Windows COM IID
    UUID m_iid;
    bool isInterface()
    {
        if (!m_iid.empty)
        {
            return true;
        }

        // 例外
        // ID3DInclude
        if (m_name[0] == 'I' && m_fields.length == 0 && m_methods.length > 0)
        {
            return true;
        }

        return false;
    }

    this(string path, int line, string name)
    {
        super(path, line, name);
    }

    void resovleForeardDeclaration()
    {
        if (!m_forwardDecl)
        {
            return;
        }
        if (!m_definition)
        {
            return;
        }

        m_forwardDecl = false;
        m_fields = m_definition.m_fields;
        m_methods = m_definition.m_methods;
        m_iid = m_definition.m_iid;
        m_definition = null;
    }
}

struct EnumValue
{
    string name;
    ulong value;
}

class Enum : UserDecl
{
    EnumValue[] m_values;

    this(string path, int line, string name, EnumValue[] values)
    {
        super(path, line, name);
        m_values = values;
    }

    ulong maxValue()
    {
        auto indexValue = m_values.enumerate.maxElement!"a.value.value"();
        return indexValue[1].value;
    }
}

class Typedef : UserDecl
{
    TypeRef m_typeref;

    this(string path, int line, string name, Decl type, bool isConst = false)
    {
        super(path, line, name);
        m_typeref = TypeRef(type, isConst);
    }

    Decl getConcreteDecl(Decl[] path = [])
    {
        foreach (x; path)
        {
            if (x == this)
            {
                return null;
            }
        }

        auto nest = cast(Typedef) m_typeref.type;
        if (!nest)
        {
            return nest;
        }

        return nest.getConcreteDecl(path ~ this);
    }
}

struct Param
{
    string name;
    TypeRef typeRef;
}

class Function : UserDecl
{
    Decl m_ret;
    bool m_externC;
    bool m_dllExport;
    Param[] m_params;

    this(string path, int line, string name, Decl ret, Param[] params, bool dllExport, bool externC)
    {
        super(path, line, name);
        m_ret = ret;
        m_params = params;
        m_dllExport = dllExport;
        m_externC = externC;
    }
}

// http://clang-developers.42468.n3.nabble.com/llibclang-CXTypeKind-char-types-td3754411.html
Primitive KindToPrimitive(CXTypeKind kind)
{
    switch (kind)
    {
    case CXTypeKind.CXType_Void:
        return new Void();
    case CXTypeKind.CXType_Bool:
        return new Bool();
        // Int
    case CXTypeKind.CXType_Char_S:
    case CXTypeKind.CXType_SChar:
        return new Int8();
    case CXTypeKind.CXType_Short:
        return new Int16();
    case CXTypeKind.CXType_Int:
    case CXTypeKind.CXType_Long:
        return new Int32();
    case CXTypeKind.CXType_LongLong:
        return new Int64();
        // UInt
    case CXTypeKind.CXType_Char_U:
    case CXTypeKind.CXType_UChar:
        return new UInt8();
    case CXTypeKind.CXType_UShort:
    case CXTypeKind.CXType_WChar:
        return new UInt16();
    case CXTypeKind.CXType_UInt:
    case CXTypeKind.CXType_ULong:
        return new UInt32();
    case CXTypeKind.CXType_ULongLong:
        return new UInt64();
        // Float
    case CXTypeKind.CXType_Float:
        return new Float();
    case CXTypeKind.CXType_Double:
        return new Double();
    case CXTypeKind.CXType_LongDouble:
        return new LongDouble();

    default:
        return null;
    }
}
