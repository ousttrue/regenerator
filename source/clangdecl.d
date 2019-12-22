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
    string path;
    int line;
    string name;

    protected this(string path, int line, string name)
    {
        this.path = path;
        this.line = line;
        this.name = name;
    }
}

struct Field
{
    string name;
    Decl type;
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

    void resovleForeardDeclaration()
    {
        if (!this.forwardDecl)
        {
            return;
        }
        if (!this.definition)
        {
            return;
        }

        this.forwardDecl = false;
        this.fields = this.definition.fields;
        this.methods = this.definition.methods;
        this.iid = this.definition.iid;
        this.definition = null;
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

class Typedef : UserDecl
{
    TypeRef typeref;

    this(string path, int line, string name, Decl type, bool isConst = false)
    {
        super(path, line, name);
        typeref = TypeRef(type, isConst);
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

        auto nest = cast(Typedef) typeref.type;
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
    Decl ret;
    bool externC;
    bool dllExport;
    Param[] params;

    this(string path, int line, string name, Decl ret, Param[] params, bool dllExport, bool externC)
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
