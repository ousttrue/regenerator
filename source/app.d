import std.stdio;
import std.conv;
import libclang;

int main(string[] args)
{
	if (args.length < 2)
	{
		return 1;
	}

	auto index = clang_createIndex(0, 1);

	auto params = [cast(byte*) "-x".ptr, cast(byte*) "c++".ptr];
	auto tu = clang_createTranslationUnitFromSourceFile(index,
			cast(byte*) args[1].ptr, cast(int) params.length, params.ptr, 0, null);

	if (!tu)
	{
		return 2;
	}

	auto rootCursor = clang_getTranslationUnitCursor(tu);

	uint treeLevel = 0;

	clang_visitChildren(rootCursor, &visitor, &treeLevel);

	clang_disposeTranslationUnit(tu);
	clang_disposeIndex(index);

	return 0;
}

string getCursorKindName(CXCursorKind cursorKind)
{
	auto kindName = clang_getCursorKindSpelling(cursorKind);
	auto result = clang_getCString(kindName);

	clang_disposeString(kindName);
	return to!string(cast(immutable char*) result);
}

byte* getCursorSpelling(CXCursor cursor)
{
	CXString cursorSpelling = clang_getCursorSpelling(cursor);
	auto result = clang_getCString(cursorSpelling);

	clang_disposeString(cursorSpelling);
	return result;
}

extern (C) CXChildVisitResult visitor(CXCursor cursor, CXCursor /* parent */ , void* clientData)
{
	auto location = clang_getCursorLocation(cursor);
	if (clang_Location_isFromMainFile(location) == 0)
		return CXChildVisitResult.CXChildVisit_Continue;

	auto cursorKind = clang_getCursorKind(cursor);

	uint curLevel = *(cast(uint*) clientData);
	uint nextLevel = curLevel + 1;

	writeln(getCursorKindName(cursorKind));
	// std::cout << std::string(curLevel, '-') << " " <<  << " (" << getCursorSpelling(cursor) << ")\n";

	clang_visitChildren(cursor, &visitor, &nextLevel);

	return CXChildVisitResult.CXChildVisit_Continue;
}
