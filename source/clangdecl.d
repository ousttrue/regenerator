module clangdecl;
import std.string;
import std.typecons;
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
    Field[] m_fields;

    this(string path, int line, string name, Field[] fields)
    {
        super(path, line, name);
        m_fields = fields;
    }
}

struct EnumValue
{
    string name;
    long value;
}

class Enum : UserDecl
{
    EnumValue[] m_values;

    this(string path, int line, string name, EnumValue[] values)
    {
        super(path, line, name);
        m_values = values;
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
    Param[] m_params;

    this(string path, int line, string name, Decl ret, Param[] params)
    {
        super(path, line, name);
        m_ret = ret;
        m_params = params;
    }
}

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

    default:
        return null;
    }
}
