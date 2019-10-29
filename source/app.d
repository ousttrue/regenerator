import std.stdio;
import std.conv;
import std.outbuffer;
import std.string;
import libclang;

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

	this()
	{
	}

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

class Typedef : Type
{
	string m_name;
	TypeRef m_typeref;

	this(string name, Type type, bool isConst = false)
	{
		m_name = name;
		m_typeref = TypeRef(type, isConst);
	}

	override string toString() const
	{
		return format("typedef %s =  %s", m_name, m_typeref);
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
			// parseTypedef(cursor);
			pushTypedef(cursor);
			break;

		default:
			return;
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

	Type[] stack;
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

	Type getUnderlyingType(CXCursor cursor)
	{
		auto type = clang_getTypedefDeclUnderlyingType(cursor);
		auto kind = getCursorTypeKindName(type.kind);
		switch (type.kind)
		{
		case CXTypeKind.CXType_Bool:
			return new Bool();
		case CXTypeKind.CXType_Int:
		case CXTypeKind.CXType_Long:
			return new Int32();
		case CXTypeKind.CXType_LongLong:
			return new Int64();
		case CXTypeKind.CXType_UShort:
			return new UInt16();
		case CXTypeKind.CXType_ULongLong:
			return new UInt64();

		case CXTypeKind.CXType_Pointer:
			// return new Pointer();
			return null;

		case CXTypeKind.CXType_Typedef:
			return null;

		case CXTypeKind.CXType_Elaborated:
			// struct typedef decl
			// throw new Exception("not implemented");
			return null;

		default:
			throw new Exception("not implemented");
		}
	}

	void pushTypedef(CXCursor cursor)
	{
		auto type = getUnderlyingType(cursor);
		if (!type)
		{
			return;
		}
		auto name = getCursorSpelling(cursor);
		auto decl = new Typedef(name, type);
		auto hash = clang_hashCursor(cursor);
		typeMap[hash] = decl;
		stack ~= decl;
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

	foreach (key, value; parser.typeMap)
	{
		writefln("%s", value);
	}

	return 0;
}
