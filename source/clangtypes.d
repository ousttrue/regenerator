module clangtypes;
import std.string;
import libclang;

class Type
{
    override string toString() const
    {
        throw new Exception("type");
    }
}

struct TypeRef
{
    Type type;
    bool isConst;
    string toString() const
    {
        if (isConst)
        {
            return format("const %s", type);
        }
        else
        {
            return format("%s", type);
        }
    }
}

class Pointer : Type
{
    TypeRef m_typeref;

    this(Type type, bool isConst = false)
    {
        m_typeref = TypeRef(type, isConst);
    }

    override string toString() const
    {
        return format("%s*", m_typeref.type);
    }
}

class Primitive : Type
{
}

class Void : Primitive
{
    override string toString() const
    {
        return "void";
    }
}

class Bool : Primitive
{
    override string toString() const
    {
        return "bool";
    }
}

class Int8 : Primitive
{
    override string toString() const
    {
        return "int8";
    }
}

class Int16 : Primitive
{
    override string toString() const
    {
        return "int16";
    }
}

class Int32 : Primitive
{
    override string toString() const
    {
        return "int32";
    }
}

class Int64 : Primitive
{
    override string toString() const
    {
        return "int64";
    }
}

class UInt8 : Primitive
{
    override string toString() const
    {
        return "uint8";
    }
}

class UInt16 : Primitive
{
    override string toString() const
    {
        return "uint16";
    }
}

class UInt32 : Primitive
{
    override string toString() const
    {
        return "uint32";
    }
}

class UInt64 : Primitive
{
    override string toString() const
    {
        return "uint64";
    }
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

    override string toString() const
    {
        return format("struct %s", m_name);
    }
}

class Enum : UserType
{
    this(string path, int line, string name)
    {
        super(path, line, name);
    }

    override string toString() const
    {
        return format("enum %s", m_name);
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

    override string toString() const
    {
        return format("typedef %s = %s", m_name, m_typeref);
    }
}

class Function : UserType
{
    Type m_ret;
    bool m_externC;

    this(string path, int line, string name, Type ret)
    {
        super(path, line, name);
        m_ret = ret;
    }

    override string toString() const
    {
        return format("function");
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
    case CXTypeKind.CXType_Char_S:
        return new Int8();
    case CXTypeKind.CXType_Int:
    case CXTypeKind.CXType_Long:
        return new Int32();
    case CXTypeKind.CXType_LongLong:
        return new Int64();
    case CXTypeKind.CXType_Char_U:
        return new UInt8();
    case CXTypeKind.CXType_UShort:
        return new UInt16();
    case CXTypeKind.CXType_ULongLong:
        return new UInt64();

    default:
        return null;
    }
}
