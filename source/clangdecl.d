module clangdecl;
import std.range;
import std.string;
import std.typecons;
import std.uuid;
import std.algorithm;
import libclang;

class Decl
{
    void replace(UserDecl from, Decl to, Decl[] = [])
    {
    }
}

struct TypeRef
{
    Decl type;
    bool isConst;

    void replace(UserDecl from, Decl to, Decl[] path)
    {
        if (type == from)
        {
            type = to;
        }
        else
        {
            if (path.any!(a => a == type))
            {
                // cyclic
                debug auto a = 0;
                return;
            }
            type.replace(from, to, path);
        }
    }

    bool hasConstRecursive()
    {
        if (this.isConst)
        {
            return true;
        }

        auto pointer = cast(Pointer) this.type;
        if (pointer)
        {
            if (pointer.typeref.hasConstRecursive)
            {
                return true;
            }
        }

        auto reference = cast(Reference) this.type;
        if (reference)
        {
            if (reference.typeref.hasConstRecursive)
            {
                return true;
            }
        }

        return false;
    }
}

class Pointer : Decl
{
    TypeRef typeref;

    this(Decl type, bool isConst = false)
    {
        this.typeref = TypeRef(type, isConst);
    }

    override void replace(UserDecl from, Decl to, Decl[] path)
    {
        typeref.replace(from, to, path ~ this);
    }
}

class Reference : Decl
{
    TypeRef typeref;

    this(Decl type, bool isConst = false)
    {
        this.typeref = TypeRef(type, isConst);
    }

    override void replace(UserDecl from, Decl to, Decl[] path)
    {
        typeref.replace(from, to, path ~ this);
    }
}

class Array : Decl
{
    TypeRef typeref;
    long size;

    this(Decl type, long arraySize, bool isConst = false)
    {
        this.typeref = TypeRef(type, isConst);
        this.size = arraySize;
    }

    override void replace(UserDecl from, Decl to, Decl[] path)
    {
        typeref.replace(from, to, path ~ this);
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
    ulong hash;
    string path;
    int line;
    string name;
    const(string)[] namespace;
    int useCount;

    protected this(string path, int line, string name)
    {
        this.path = path;
        this.line = line;
        this.name = name;
    }
}

struct Field
{
    long offset;
    string name;
    TypeRef typeref;
}

class Struct : UserDecl
{
    bool isUnion;

    UserDecl base;
    Field[] fields;
    Function[] methods;

    bool forwardDecl;

    // forwardDecl definition
    Struct definition;

    // Windows COM IID
    UUID iid;
    bool isInterface()
    {
        if (!iid.empty)
        {
            return true;
        }

        if (name.length == 0)
        {
            return false;
        }

        // 例外
        // ID3DInclude
        if (name[0] == 'I' && this.fields.length == 0 && this.methods.length > 0)
        {
            return true;
        }

        return false;
    }

    this(string path, int line, string name)
    {
        super(path, line, name);
    }

    override void replace(UserDecl from, Decl to, Decl[] path)
    {
        foreach (ref f; fields)
        {
            f.typeref.replace(from, to, path ~ this);
        }
        foreach (ref m; methods)
        {
            m.replace(from, to, path ~ this);
        }
    }
}

struct EnumValue
{
    string name;
    ulong value;
}

class Enum : UserDecl
{
    EnumValue[] values;

    this(string path, int line, string name, EnumValue[] values)
    {
        super(path, line, name);
        this.values = values;
    }

    ulong maxValue()
    {
        auto indexValue = this.values.enumerate.maxElement!"a.value.value"();
        return indexValue[1].value;
    }

    string getValuePrefix()
    {
        if (this.values.empty)
        {
            return "";
        }

        string prefix = this.values[0].name;
        foreach (value; this.values[1 .. $])
        {
            int i = 0;
            for (; i < prefix.length; ++i)
            {
                if (prefix[i] != value.name[i])
                {
                    break;
                }
            }
            prefix = prefix[0 .. i];
            if (prefix.empty)
            {
                break;
            }
        }
        return prefix;
    }
}

class TypeDef : UserDecl
{
    TypeRef typeref;

    this(string path, int line, string name, Decl type, bool isConst = false)
    {
        super(path, line, name);
        typeref = TypeRef(type, isConst);
    }

    override void replace(UserDecl from, Decl to, Decl[] path)
    {
        typeref.replace(from, to, path ~ this);
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

        auto nest = cast(TypeDef) typeref.type;
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
    TypeRef typeref;
    string[] values;
}

class Function : UserDecl
{
    TypeRef ret;
    bool externC;
    bool dllExport;
    Param[] params;

    this(string path, int line, string name, TypeRef ret, Param[] params, bool dllExport, bool externC)
    {
        super(path, line, name);
        this.ret = ret;
        this.params = params;
        this.dllExport = dllExport;
        this.externC = externC;
    }

    override string toString() const
    {
        return "%s %s(%s)".format(ret, name, params);
    }

    override void replace(UserDecl from, Decl to, Decl[] path)
    {
        ret.replace(from, to, path);

        foreach (ref p; params)
        {
            p.typeref.replace(from, to, path ~ this);
        }
    }
}

// http://clang-developers.42468.n3.nabble.com/llibclang-CXTypeKind-char-types-td3754411.html
Primitive KindToPrimitive(CXTypeKind kind)
{
    switch (kind)
    {
    case CXTypeKind._Void:
        return new Void();
    case CXTypeKind._Bool:
        return new Bool();
        // Int
    case CXTypeKind._Char_S:
    case CXTypeKind._SChar:
        return new Int8();
    case CXTypeKind._Short:
        return new Int16();
    case CXTypeKind._Int:
    case CXTypeKind._Long:
        return new Int32();
    case CXTypeKind._LongLong:
        return new Int64();
        // UInt
    case CXTypeKind._Char_U:
    case CXTypeKind._UChar:
        return new UInt8();
    case CXTypeKind._UShort:
    case CXTypeKind._WChar:
        return new UInt16();
    case CXTypeKind._UInt:
    case CXTypeKind._ULong:
        return new UInt32();
    case CXTypeKind._ULongLong:
        return new UInt64();
        // Float
    case CXTypeKind._Float:
        return new Float();
    case CXTypeKind._Double:
        return new Double();
    case CXTypeKind._LongDouble:
        return new LongDouble();

    default:
        return null;
    }
}
