import std.stdio;
import std.string;
import std.array;
import std.path;
import std.file;
import std.getopt;
import std.conv;
import std.algorithm;
import libclang;
import clanghelper;
import parser;
import cursoriterator;

class DSource
{
	string m_path;
	UserType[] m_types;

	this(string path)
	{
		m_path = path;
	}

	void addDecl(UserType type)
	{
		m_types ~= type;
	}

	void writeTo(string dir)
	{
		writeln(dir);
		writeln(m_path);

		mkdirRecurse(dir);

		// open
		auto name = m_path.baseName().stripExtension();
		auto stem = format("%s/%s.d", dir, name);
		// writeln(stem);

		auto f = File(stem, "w");
		foreach (decl; m_types)
		{
			castSwitch!((Typedef decl) => f.writefln("// typedef %s",
					decl.m_name), (Enum decl) => f.writefln("// enum %s", decl.m_name),
					(Struct decl) => f.writefln("// struct %s", decl.m_name),
					() => f.writefln("// %s", decl))(decl);
		}
	}
}

class Header
{
	UserType[] types;
}

class Parser
{
	void traverse(CXCursor cursor, Context context = Context())
	{
		// auto context = parentContext.getChild();
		auto tu = clang_Cursor_getTranslationUnit(cursor);
		auto cursorKind = cast(CXCursorKind) clang_getCursorKind(cursor);
		auto _ = getCursorKindName(cursorKind);
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
			// writeln(kind);
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
		auto header = getOrCreateHeader(cursor);
		header.types ~= decl;
	}

	void parseEnum(CXCursor cursor)
	{
		auto location = getCursorLocation(cursor);
		auto name = getCursorSpelling(cursor);
		auto decl = new Enum(location.path, location.line, name);
		auto hash = clang_hashCursor(cursor);
		typeMap[hash] = decl;
		auto header = getOrCreateHeader(cursor);
		header.types ~= decl;
	}

	void exportD(string header, string dir)
	{
		auto parsed_header = headers[header];
		if (!parsed_header)
		{
			return;
		}

		if (exists(dir))
		{
			// clear dir
			writefln("rmdir %s ...", dir);
			rmdirRecurse(dir);
		}

		auto dsource = new DSource(header);
		foreach (decl; parsed_header.types)
		{
			dsource.addDecl(decl);
		}
		dsource.writeTo(dir);
	}
}

int main(string[] args)
{
	string header;
	string dir;
	string[] includes;
	getopt(args, "include|I", &includes, "outdir", &dir,
			std.getopt.config.required, "header|H", &header);

	auto index = clang_createIndex(0, 1);
	scope (exit)
		clang_disposeIndex(index);

	string[] params = ["-x", "c++"];
	foreach (include; includes)
	{
		params ~= format("-I%s", include);
	}

	auto tu = getTU(index, header, params);
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

	if (dir)
	{
		auto x = toStringz(dir);
		auto y = x[0 .. dir.length + 1];
		parser.exportD(header, to!string(y.ptr));
	}

	return 0;
}
