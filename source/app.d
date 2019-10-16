import std.stdio;
import std.conv;
import libclang;

string getCursorKindName(CXCursorKind cursorKind)
{
	auto kindName = clang_getCursorKindSpelling(cursorKind);
	auto result = clang_getCString(kindName);

	clang_disposeString(kindName);
	return to!string(cast(immutable char*) result);
}

string getCursorSpelling(CXCursor cursor)
{
	CXString cursorSpelling = clang_getCursorSpelling(cursor);
	auto result = clang_getCString(cursorSpelling);

	clang_disposeString(cursorSpelling);
	return to!string(cast(immutable char*) result);
}

extern (C) CXChildVisitResult visitor(CXCursor cursor, CXCursor /* parent */ ,
		immutable char* indent)
{
	if (clang_Location_isFromMainFile(clang_getCursorLocation(cursor)))
	{
		auto cursorKind = clang_getCursorKind(cursor);

		writefln("%s%s (%s)", to!string(indent),
				getCursorKindName(cursorKind), getCursorSpelling(cursor));

		clang_visitChildren(cursor, &visitor, cast(void*)(to!string(indent) ~ "  ").ptr);
	}
	return CXChildVisitResult.CXChildVisit_Continue;
}

int main(string[] args)
{
	if (args.length < 2)
	{
		return 1;
	}

	auto index = clang_createIndex(0, 1);

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

	auto rootCursor = clang_getTranslationUnitCursor(tu);

	clang_visitChildren(rootCursor, &visitor, cast(void*) "".ptr);

	clang_disposeTranslationUnit(tu);
	clang_disposeIndex(index);

	return 0;
}
