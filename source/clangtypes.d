module clangtypes;
import std.string;
import libclang;

class Type
{
}

struct TypeRef
{
    Type type;
    bool isConst;
}

class Pointer : Type
{
    TypeRef m_typeref;

    this(Type type, bool isConst = false)
    {
        m_typeref = TypeRef(type, isConst);
    }
}

class Primitive : Type
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

class UserType : Type
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

class Struct : UserType
{
    this(string path, int line, string name)
    {
        super(path, line, name);
    }
}

class Enum : UserType
{
    this(string path, int line, string name)
    {
        super(path, line, name);
    }
}

class Typedef : UserType
{
    TypeRef m_typeref;

    this(string path, int line, string name, Type type, bool isConst = false)
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

class Function : UserType
{
    Type m_ret;
    bool m_externC;
    Param[] m_params;

    this(string path, int line, string name, Type ret, Param[] params)
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
