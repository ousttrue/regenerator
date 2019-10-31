import std.stdio;
import std.conv;
import std.outbuffer;
import std.string;
import std.array;
import libclang;

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

string CXStringToString(CXString cxs)
{
	auto p = clang_getCString(cxs);
	return to!string(cast(immutable char*) p);
}

string function(T) cxToString(T)(CXString function(T) func)
{
	return (T t) => {
		auto name = func(T);
		scope (exit)
			clang_disposeString(kindName);

		return CXStringToString(kindName);
	};
}

string getCursorKindName(CXCursorKind cursorKind)
{
	auto kindName = clang_getCursorKindSpelling(cursorKind);
	scope (exit)
		clang_disposeString(kindName);

	return CXStringToString(kindName);
}

string getCursorSpelling(CXCursor cursor)
{
	auto cursorSpelling = clang_getCursorSpelling(cursor);
	scope (exit)
		clang_disposeString(cursorSpelling);

	return CXStringToString(cursorSpelling);
}

string getCursorTypeKindName(CXTypeKind typeKind)
{
	auto kindName = clang_getTypeKindSpelling(typeKind);
	scope (exit)
		clang_disposeString(kindName);

	return CXStringToString(kindName);
}

struct Location
{
	string path;
	int line;
}

Location getCursorLocation(CXCursor cursor)
{
	auto location = clang_getCursorLocation(cursor);
	void* file;
	uint line;
	uint column;
	uint offset;
	clang_getInstantiationLocation(location, &file, &line, &column, &offset);
	auto path = CXStringToString(clang_getFileName(file));
	return Location(path, line);
}

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

class Function : Type
{
	override string toString() const
	{
		return format("function");
	}
}

struct Context
{
	int level;
	bool isExternC;

	string getIndent()
	{
		auto buf = new OutBuffer();
		for (int i = 0; i < level; ++i)
		{
			buf.write("  ");
		}
		return buf.toString();
	}

	Context getChild()
	{
		return Context(level + 1, isExternC);
	}
}

alias applyCallback = int delegate(CXCursor);

extern (C) CXChildVisitResult visitor(CXCursor cursor, CXCursor /* parent */ , CXCursorIterator* it)
{
	return it.call(cursor);
}

struct CXCursorIterator
{
	CXCursor cursor;
	applyCallback callback;
	int end;

	this(CXCursor cursor)
	{
		this.cursor = cursor;
	}

	int opApply(applyCallback dg)
	{
		callback = dg;
		clang_visitChildren(cursor, &visitor, &this);
		return end;
	}

	CXChildVisitResult call(CXCursor cursor)
	{
		if (callback(cursor))
		{
			end = 1;
			return CXChildVisitResult.CXChildVisit_Break;
		}

		return CXChildVisitResult.CXChildVisit_Continue;
	}
}

class Header
{
	Type[] types;
}

class Parser
{
	void traverse(CXCursor cursor, Context context = Context())
	{
		// auto context = parentContext.getChild();
		auto tu = clang_Cursor_getTranslationUnit(cursor);
		auto cursorKind = cast(CXCursorKind) clang_getCursorKind(cursor);
		auto kind = getCursorKindName(cursorKind);
		// writefln("%s%s", context.getIndent(), kind);
		switch (cursorKind)
		{
		case CXCursorKind.CXCursor_InclusionDirective:
		case CXCursorKind.CXCursor_MacroDefinition:
		case CXCursorKind.CXCursor_MacroExpansion:
		case CXCursorKind.CXCursor_ClassTemplate:
		case CXCursorKind.CXCursor_ClassTemplatePartialSpecialization:
		case CXCursorKind.CXCursor_FunctionTemplate:
			// skip
			break;

		case CXCursorKind.CXCursor_UnexposedDecl:
			{
				auto tokens = getTokens(cursor);
				scope (exit)
					clang_disposeTokens(tu, tokens.ptr, cast(uint) tokens.length);

				if (tokens.length >= 2)
				{
					// extern C
					auto token0 = CXStringToString(clang_getTokenSpelling(tu, tokens[0]));
					auto token1 = CXStringToString(clang_getTokenSpelling(tu, tokens[1]));
					if (token0 == "extern" && token1 == "\"C\"")
					{
						context.isExternC = true;
					}
				}
				foreach (child; CXCursorIterator(cursor))
				{
					traverse(child, context.getChild());
				}
			}
			break;

		case CXCursorKind.CXCursor_TypedefDecl:
			parseTypedef(cursor);
			break;

		case CXCursorKind.CXCursor_FunctionDecl:
			break;

		case CXCursorKind.CXCursor_StructDecl:
			parseStruct(cursor);
			break;

		case CXCursorKind.CXCursor_EnumDecl:
			parseEnum(cursor);
			break;

		case CXCursorKind.CXCursor_VarDecl:
			break;

		default:
			throw new Exception("");
		}
	}

	CXToken[] getTokens(CXCursor cursor)
	{
		auto extent = clang_getCursorExtent(cursor);
		auto begin = clang_getRangeStart(extent);
		auto end = clang_getRangeEnd(extent);
		auto range = clang_getRange(begin, end);

		CXToken* tokens;
		uint num;
		auto tu = clang_Cursor_getTranslationUnit(cursor);
		clang_tokenize(tu, range, &tokens, &num);

		return tokens[0 .. num];
	}

	Type[uint] typeMap;
	CXCursor getRootCanonical(CXCursor cursor)
	{
		auto current = cursor;
		while (true)
		{
			auto canonical = clang_getCanonicalCursor(current);
			if (canonical == current)
			{
				return current;
			}
			current = canonical;
		}
	}

	Type kindToType(CXCursor cursor, CXType type)
	{
		auto primitive = KindToPrimitive(type.kind);
		if (primitive)
		{
			return primitive;
		}

		if (type.kind == CXTypeKind.CXType_Pointer)
		{
			// pointer
			auto isConst = clang_isConstQualifiedType(type);
			auto pointee = kindToType(cursor, clang_getPointeeType(type));
			return new Pointer(pointee, isConst != 0);
		}

		if (type.kind == CXTypeKind.CXType_Elaborated)
		{
			// struct
			auto children = CXCursorIterator(cursor).array();
			auto child = children[0];
			auto childKind = cast(CXCursorKind) clang_getCursorKind(child);
			auto kind = getCursorKindName(childKind);
			writeln(kind);
			if (childKind == CXCursorKind.CXCursor_StructDecl
					|| childKind == CXCursorKind.CXCursor_UnionDecl
					|| childKind == CXCursorKind.CXCursor_EnumDecl)
			{
				auto hash = clang_hashCursor(child);
				auto decl = typeMap[hash];
				return decl;
			}
			else if (childKind == CXCursorKind.CXCursor_TypeRef)
			{
				auto referenced = clang_getCursorReferenced(child);
				auto hash = clang_hashCursor(referenced);
				auto decl = typeMap[hash];
				return decl;
			}
			else
			{
				writeln("hoge");
				throw new Exception("not implemented");
			}
		}

		if (type.kind == CXTypeKind.CXType_Typedef)
		{
			auto children = CXCursorIterator(cursor).array();
			auto child = children[0];
			auto childKind = cast(CXCursorKind) clang_getCursorKind(child);
			if (childKind == CXCursorKind.CXCursor_TypeRef)
			{
				auto referenced = clang_getCursorReferenced(child);
				auto hash = clang_hashCursor(referenced);
				auto decl = typeMap[hash];
				return decl;
			}
			else
			{
				throw new Exception("not implemented");
			}
		}

		if (type.kind == CXTypeKind.CXType_FunctionProto)
		{
			return new Function();
		}

		int a = 0;
		throw new Exception("not implemented");
	}

	Header[string] headers;

	Header getOrCreateHeader(CXCursor cursor)
	{
		auto location = getCursorLocation(cursor);
		auto found = headers.get(location.path, null);
		if (found)
		{
			return found;
		}

		found = new Header();
		headers[location.path] = found;
		return found;
	}

	void pushTypedef(CXCursor cursor, Type type)
	{
		auto location = getCursorLocation(cursor);
		auto name = getCursorSpelling(cursor);
		auto decl = new Typedef(location.path, location.line, name, type);
		auto hash = clang_hashCursor(cursor);
		typeMap[hash] = decl;
		auto header = getOrCreateHeader(cursor);
		header.types ~= decl;
	}

	void parseTypedef(CXCursor cursor)
	{
		auto underlying = clang_getTypedefDeclUnderlyingType(cursor);
		auto type = kindToType(cursor, underlying);
		pushTypedef(cursor, type);
	}

	void parseStruct(CXCursor cursor)
	{
		auto location = getCursorLocation(cursor);
		auto name = getCursorSpelling(cursor);
		auto decl = new Struct(location.path, location.line, name);
		auto hash = clang_hashCursor(cursor);
		typeMap[hash] = decl;
	}

	void parseEnum(CXCursor cursor)
	{
		auto location = getCursorLocation(cursor);
		auto name = getCursorSpelling(cursor);
		auto decl = new Enum(location.path, location.line, name);
		auto hash = clang_hashCursor(cursor);
		typeMap[hash] = decl;
	}
}

int main(string[] args)
{
	if (args.length < 2)
	{
		return 1;
	}

	auto index = clang_createIndex(0, 1);
	scope (exit)
		clang_disposeIndex(index);

	auto params = [
		cast(byte*) "-x".ptr, cast(byte*) "c++".ptr,
		cast(byte*) "-IC:/Program Files/LLVM/include".ptr
	];
	auto tu = clang_createTranslationUnitFromSourceFile(index,
			cast(byte*) "C:/Program Files/LLVM/include/clang-c/Index.h".ptr,
			cast(int) params.length, params.ptr, 0, null);
	if (!tu)
	{
		return 2;
	}
	scope (exit)
		clang_disposeTranslationUnit(tu);

	auto rootCursor = clang_getTranslationUnitCursor(tu);

	auto parser = new Parser();
	foreach (cursor; CXCursorIterator(rootCursor))
	{
		parser.traverse(cursor);
	}

	foreach (path, header; parser.headers)
	{
		writefln("[%s]", path);
		foreach (decl; header.types)
		{
			writefln("%s", decl);
		}
	}

	return 0;
}
