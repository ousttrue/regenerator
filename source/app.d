import std.stdio;
import libclang;

void main(string[] args)
{
	if (args.length < 2)
		return;

	auto index = clang_createIndex(0, 1);
	// string[] params = ["-x", "c++",];
	// auto cparams = [params[0].ptr, params[1].ptr];
	auto tu = clang_createTranslationUnitFromSourceFile(index,
			cast(byte*) args[1].ptr, 0, null, 0, null);

	if (!tu)
		return;

	auto rootCursor = clang_getTranslationUnitCursor(tu);

	uint treeLevel = 0;

	clang_visitChildren(rootCursor, &visitor, &treeLevel);

	clang_disposeTranslationUnit(tu);
	clang_disposeIndex(index);

	return;
}

byte* getCursorKindName(CXCursorKind cursorKind)
{
	auto kindName = clang_getCursorKindSpelling(cursorKind);
	auto result = clang_getCString(kindName);

	clang_disposeString(kindName);
	return result;
}

byte* getCursorSpelling(CXCursor cursor)
{
	CXString cursorSpelling = clang_getCursorSpelling(cursor);
	auto result = clang_getCString(cursorSpelling);

	clang_disposeString(cursorSpelling);
	return result;
}

extern (C) CXChildVisitResult visitor(CXCursor cursor, CXCursor /* parent */ , void* clientData) nothrow
{
	auto location = clang_getCursorLocation(cursor);
	if (clang_Location_isFromMainFile(location) == 0)
		return CXChildVisitResult.CXChildVisit_Continue;

	auto cursorKind = clang_getCursorKind(cursor);

	uint curLevel = *(cast(uint*) clientData);
	uint nextLevel = curLevel + 1;

	// std::cout << std::string(curLevel, '-') << " " << getCursorKindName(cursorKind) << " (" << getCursorSpelling(cursor) << ")\n";

	clang_visitChildren(cursor, &visitor, &nextLevel);

	return CXChildVisitResult.CXChildVisit_Continue;
}
