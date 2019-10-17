// cpptypeinfo generated
module libclang.Index;

import core.sys.windows.windef;
import core.sys.windows.com;
import libclang.CXString;
import libclang.CXErrorCode;


enum CXAvailabilityKind {
CXAvailability_Available = 0x00000000,
    CXAvailability_Deprecated = 0x00000001,
    CXAvailability_NotAvailable = 0x00000002,
    CXAvailability_NotAccessible = 0x00000003,
}

enum CXCursor_ExceptionSpecificationKind {
    None = 0x00000000,
    DynamicNone = 0x00000001,
    Dynamic = 0x00000002,
    MSAny = 0x00000003,
    BasicNoexcept = 0x00000004,
    ComputedNoexcept = 0x00000005,
    Unevaluated = 0x00000006,
    Uninstantiated = 0x00000007,
    Unparsed = 0x00000008,
}

enum CXGlobalOptFlags {
    CXGlobalOpt_None = 0x00000000,
    CXGlobalOpt_ThreadBackgroundPriorityForIndexing = 0x00000001,
    CXGlobalOpt_ThreadBackgroundPriorityForEditing = 0x00000002,
    CXGlobalOpt_ThreadBackgroundPriorityForAll = 0x00000003,
}

enum CXDiagnosticSeverity {
    CXDiagnostic_Ignored = 0x00000000,
    CXDiagnostic_Note = 0x00000001,
    CXDiagnostic_Warning = 0x00000002,
    CXDiagnostic_Error = 0x00000003,
    CXDiagnostic_Fatal = 0x00000004,
}

enum CXLoadDiag_Error {
    CXLoadDiag_None = 0x00000000,
    CXLoadDiag_Unknown = 0x00000001,
    CXLoadDiag_CannotLoad = 0x00000002,
    CXLoadDiag_InvalidFile = 0x00000003,
}

enum CXDiagnosticDisplayOptions {
    CXDiagnostic_DisplaySourceLocation = 0x00000001,
    CXDiagnostic_DisplayColumn = 0x00000002,
    CXDiagnostic_DisplaySourceRanges = 0x00000004,
    CXDiagnostic_DisplayOption = 0x00000008,
    CXDiagnostic_DisplayCategoryId = 0x00000010,
    CXDiagnostic_DisplayCategoryName = 0x00000020,
}

enum CXTranslationUnit_Flags {
    CXTranslationUnit_None = 0x00000000,
    CXTranslationUnit_DetailedPreprocessingRecord = 0x00000001,
    CXTranslationUnit_Incomplete = 0x00000002,
    CXTranslationUnit_PrecompiledPreamble = 0x00000004,
    CXTranslationUnit_CacheCompletionResults = 0x00000008,
    CXTranslationUnit_ForSerialization = 0x00000010,
    CXTranslationUnit_CXXChainedPCH = 0x00000020,
    CXTranslationUnit_SkipFunctionBodies = 0x00000040,
    CXTranslationUnit_IncludeBriefCommentsInCodeCompletion = 0x00000080,
    CXTranslationUnit_CreatePreambleOnFirstParse = 0x00000100,
    CXTranslationUnit_KeepGoing = 0x00000200,
    CXTranslationUnit_SingleFileParse = 0x00000400,
    CXTranslationUnit_LimitSkipFunctionBodiesToPreamble = 0x00000800,
    CXTranslationUnit_IncludeAttributedTypes = 0x00001000,
    CXTranslationUnit_VisitImplicitAttributes = 0x00002000,
}

enum CXSaveTranslationUnit_Flags {
    CXSaveTranslationUnit_None = 0x00000000,
}

enum CXSaveError {
    None = 0x00000000,
    Unknown = 0x00000001,
    TranslationErrors = 0x00000002,
    InvalidTU = 0x00000003,
}

enum CXReparse_Flags {
    CXReparse_None = 0x00000000,
}

enum CXTUResourceUsageKind {
    CXTUResourceUsage_AST = 0x00000001,
    CXTUResourceUsage_Identifiers = 0x00000002,
    CXTUResourceUsage_Selectors = 0x00000003,
    CXTUResourceUsage_GlobalCompletionResults = 0x00000004,
    CXTUResourceUsage_SourceManagerContentCache = 0x00000005,
    CXTUResourceUsage_AST_SideTables = 0x00000006,
    CXTUResourceUsage_SourceManager_Membuffer_Malloc = 0x00000007,
    CXTUResourceUsage_SourceManager_Membuffer_MMap = 0x00000008,
    CXTUResourceUsage_ExternalASTSource_Membuffer_Malloc = 0x00000009,
    CXTUResourceUsage_ExternalASTSource_Membuffer_MMap = 0x0000000a,
    CXTUResourceUsage_Preprocessor = 0x0000000b,
    CXTUResourceUsage_PreprocessingRecord = 0x0000000c,
    CXTUResourceUsage_SourceManager_DataStructures = 0x0000000d,
    CXTUResourceUsage_Preprocessor_HeaderSearch = 0x0000000e,
    CXTUResourceUsage_MEMORY_IN_BYTES_BEGIN = 0x00000001,
    CXTUResourceUsage_MEMORY_IN_BYTES_END = 0x0000000e,
    CXTUResourceUsage_First = 0x00000001,
    CXTUResourceUsage_Last = 0x0000000e,
}

enum CXCursorKind {
    CXCursor_UnexposedDecl = 0x00000001,
    CXCursor_StructDecl = 0x00000002,
    CXCursor_UnionDecl = 0x00000003,
    CXCursor_ClassDecl = 0x00000004,
    CXCursor_EnumDecl = 0x00000005,
    CXCursor_FieldDecl = 0x00000006,
    CXCursor_EnumConstantDecl = 0x00000007,
    CXCursor_FunctionDecl = 0x00000008,
    CXCursor_VarDecl = 0x00000009,
    CXCursor_ParmDecl = 0x0000000a,
    CXCursor_ObjCInterfaceDecl = 0x0000000b,
    CXCursor_ObjCCategoryDecl = 0x0000000c,
    CXCursor_ObjCProtocolDecl = 0x0000000d,
    CXCursor_ObjCPropertyDecl = 0x0000000e,
    CXCursor_ObjCIvarDecl = 0x0000000f,
    CXCursor_ObjCInstanceMethodDecl = 0x00000010,
    CXCursor_ObjCClassMethodDecl = 0x00000011,
    CXCursor_ObjCImplementationDecl = 0x00000012,
    CXCursor_ObjCCategoryImplDecl = 0x00000013,
    CXCursor_TypedefDecl = 0x00000014,
    CXCursor_CXXMethod = 0x00000015,
    CXCursor_Namespace = 0x00000016,
    CXCursor_LinkageSpec = 0x00000017,
    CXCursor_Constructor = 0x00000018,
    CXCursor_Destructor = 0x00000019,
    CXCursor_ConversionFunction = 0x0000001a,
    CXCursor_TemplateTypeParameter = 0x0000001b,
    CXCursor_NonTypeTemplateParameter = 0x0000001c,
    CXCursor_TemplateTemplateParameter = 0x0000001d,
    CXCursor_FunctionTemplate = 0x0000001e,
    CXCursor_ClassTemplate = 0x0000001f,
    CXCursor_ClassTemplatePartialSpecialization = 0x00000020,
    CXCursor_NamespaceAlias = 0x00000021,
    CXCursor_UsingDirective = 0x00000022,
    CXCursor_UsingDeclaration = 0x00000023,
    CXCursor_TypeAliasDecl = 0x00000024,
    CXCursor_ObjCSynthesizeDecl = 0x00000025,
    CXCursor_ObjCDynamicDecl = 0x00000026,
    CXCursor_CXXAccessSpecifier = 0x00000027,
    CXCursor_FirstDecl = 0x00000001,
    CXCursor_LastDecl = 0x00000027,
    CXCursor_FirstRef = 0x00000028,
    CXCursor_ObjCSuperClassRef = 0x00000028,
    CXCursor_ObjCProtocolRef = 0x00000029,
    CXCursor_ObjCClassRef = 0x0000002a,
    CXCursor_TypeRef = 0x0000002b,
    CXCursor_CXXBaseSpecifier = 0x0000002c,
    CXCursor_TemplateRef = 0x0000002d,
    CXCursor_NamespaceRef = 0x0000002e,
    CXCursor_MemberRef = 0x0000002f,
    CXCursor_LabelRef = 0x00000030,
    CXCursor_OverloadedDeclRef = 0x00000031,
    CXCursor_VariableRef = 0x00000032,
    CXCursor_LastRef = 0x00000032,
    CXCursor_FirstInvalid = 0x00000046,
    CXCursor_InvalidFile = 0x00000046,
    CXCursor_NoDeclFound = 0x00000047,
    CXCursor_NotImplemented = 0x00000048,
    CXCursor_InvalidCode = 0x00000049,
    CXCursor_LastInvalid = 0x00000049,
    CXCursor_FirstExpr = 0x00000064,
    CXCursor_UnexposedExpr = 0x00000064,
    CXCursor_DeclRefExpr = 0x00000065,
    CXCursor_MemberRefExpr = 0x00000066,
    CXCursor_CallExpr = 0x00000067,
    CXCursor_ObjCMessageExpr = 0x00000068,
    CXCursor_BlockExpr = 0x00000069,
    CXCursor_IntegerLiteral = 0x0000006a,
    CXCursor_FloatingLiteral = 0x0000006b,
    CXCursor_ImaginaryLiteral = 0x0000006c,
    CXCursor_StringLiteral = 0x0000006d,
    CXCursor_CharacterLiteral = 0x0000006e,
    CXCursor_ParenExpr = 0x0000006f,
    CXCursor_UnaryOperator = 0x00000070,
    CXCursor_ArraySubscriptExpr = 0x00000071,
    CXCursor_BinaryOperator = 0x00000072,
    CXCursor_CompoundAssignOperator = 0x00000073,
    CXCursor_ConditionalOperator = 0x00000074,
    CXCursor_CStyleCastExpr = 0x00000075,
    CXCursor_CompoundLiteralExpr = 0x00000076,
    CXCursor_InitListExpr = 0x00000077,
    CXCursor_AddrLabelExpr = 0x00000078,
    CXCursor_StmtExpr = 0x00000079,
    CXCursor_GenericSelectionExpr = 0x0000007a,
    CXCursor_GNUNullExpr = 0x0000007b,
    CXCursor_CXXStaticCastExpr = 0x0000007c,
    CXCursor_CXXDynamicCastExpr = 0x0000007d,
    CXCursor_CXXReinterpretCastExpr = 0x0000007e,
    CXCursor_CXXConstCastExpr = 0x0000007f,
    CXCursor_CXXFunctionalCastExpr = 0x00000080,
    CXCursor_CXXTypeidExpr = 0x00000081,
    CXCursor_CXXBoolLiteralExpr = 0x00000082,
    CXCursor_CXXNullPtrLiteralExpr = 0x00000083,
    CXCursor_CXXThisExpr = 0x00000084,
    CXCursor_CXXThrowExpr = 0x00000085,
    CXCursor_CXXNewExpr = 0x00000086,
    CXCursor_CXXDeleteExpr = 0x00000087,
    CXCursor_UnaryExpr = 0x00000088,
    CXCursor_ObjCStringLiteral = 0x00000089,
    CXCursor_ObjCEncodeExpr = 0x0000008a,
    CXCursor_ObjCSelectorExpr = 0x0000008b,
    CXCursor_ObjCProtocolExpr = 0x0000008c,
    CXCursor_ObjCBridgedCastExpr = 0x0000008d,
    CXCursor_PackExpansionExpr = 0x0000008e,
    CXCursor_SizeOfPackExpr = 0x0000008f,
    CXCursor_LambdaExpr = 0x00000090,
    CXCursor_ObjCBoolLiteralExpr = 0x00000091,
    CXCursor_ObjCSelfExpr = 0x00000092,
    CXCursor_OMPArraySectionExpr = 0x00000093,
    CXCursor_ObjCAvailabilityCheckExpr = 0x00000094,
    CXCursor_FixedPointLiteral = 0x00000095,
    CXCursor_LastExpr = 0x00000095,
    CXCursor_FirstStmt = 0x000000c8,
    CXCursor_UnexposedStmt = 0x000000c8,
    CXCursor_LabelStmt = 0x000000c9,
    CXCursor_CompoundStmt = 0x000000ca,
    CXCursor_CaseStmt = 0x000000cb,
    CXCursor_DefaultStmt = 0x000000cc,
    CXCursor_IfStmt = 0x000000cd,
    CXCursor_SwitchStmt = 0x000000ce,
    CXCursor_WhileStmt = 0x000000cf,
    CXCursor_DoStmt = 0x000000d0,
    CXCursor_ForStmt = 0x000000d1,
    CXCursor_GotoStmt = 0x000000d2,
    CXCursor_IndirectGotoStmt = 0x000000d3,
    CXCursor_ContinueStmt = 0x000000d4,
    CXCursor_BreakStmt = 0x000000d5,
    CXCursor_ReturnStmt = 0x000000d6,
    CXCursor_GCCAsmStmt = 0x000000d7,
    CXCursor_AsmStmt = 0x000000d7,
    CXCursor_ObjCAtTryStmt = 0x000000d8,
    CXCursor_ObjCAtCatchStmt = 0x000000d9,
    CXCursor_ObjCAtFinallyStmt = 0x000000da,
    CXCursor_ObjCAtThrowStmt = 0x000000db,
    CXCursor_ObjCAtSynchronizedStmt = 0x000000dc,
    CXCursor_ObjCAutoreleasePoolStmt = 0x000000dd,
    CXCursor_ObjCForCollectionStmt = 0x000000de,
    CXCursor_CXXCatchStmt = 0x000000df,
    CXCursor_CXXTryStmt = 0x000000e0,
    CXCursor_CXXForRangeStmt = 0x000000e1,
    CXCursor_SEHTryStmt = 0x000000e2,
    CXCursor_SEHExceptStmt = 0x000000e3,
    CXCursor_SEHFinallyStmt = 0x000000e4,
    CXCursor_MSAsmStmt = 0x000000e5,
    CXCursor_NullStmt = 0x000000e6,
    CXCursor_DeclStmt = 0x000000e7,
    CXCursor_OMPParallelDirective = 0x000000e8,
    CXCursor_OMPSimdDirective = 0x000000e9,
    CXCursor_OMPForDirective = 0x000000ea,
    CXCursor_OMPSectionsDirective = 0x000000eb,
    CXCursor_OMPSectionDirective = 0x000000ec,
    CXCursor_OMPSingleDirective = 0x000000ed,
    CXCursor_OMPParallelForDirective = 0x000000ee,
    CXCursor_OMPParallelSectionsDirective = 0x000000ef,
    CXCursor_OMPTaskDirective = 0x000000f0,
    CXCursor_OMPMasterDirective = 0x000000f1,
    CXCursor_OMPCriticalDirective = 0x000000f2,
    CXCursor_OMPTaskyieldDirective = 0x000000f3,
    CXCursor_OMPBarrierDirective = 0x000000f4,
    CXCursor_OMPTaskwaitDirective = 0x000000f5,
    CXCursor_OMPFlushDirective = 0x000000f6,
    CXCursor_SEHLeaveStmt = 0x000000f7,
    CXCursor_OMPOrderedDirective = 0x000000f8,
    CXCursor_OMPAtomicDirective = 0x000000f9,
    CXCursor_OMPForSimdDirective = 0x000000fa,
    CXCursor_OMPParallelForSimdDirective = 0x000000fb,
    CXCursor_OMPTargetDirective = 0x000000fc,
    CXCursor_OMPTeamsDirective = 0x000000fd,
    CXCursor_OMPTaskgroupDirective = 0x000000fe,
    CXCursor_OMPCancellationPointDirective = 0x000000ff,
    CXCursor_OMPCancelDirective = 0x00000100,
    CXCursor_OMPTargetDataDirective = 0x00000101,
    CXCursor_OMPTaskLoopDirective = 0x00000102,
    CXCursor_OMPTaskLoopSimdDirective = 0x00000103,
    CXCursor_OMPDistributeDirective = 0x00000104,
    CXCursor_OMPTargetEnterDataDirective = 0x00000105,
    CXCursor_OMPTargetExitDataDirective = 0x00000106,
    CXCursor_OMPTargetParallelDirective = 0x00000107,
    CXCursor_OMPTargetParallelForDirective = 0x00000108,
    CXCursor_OMPTargetUpdateDirective = 0x00000109,
    CXCursor_OMPDistributeParallelForDirective = 0x0000010a,
    CXCursor_OMPDistributeParallelForSimdDirective = 0x0000010b,
    CXCursor_OMPDistributeSimdDirective = 0x0000010c,
    CXCursor_OMPTargetParallelForSimdDirective = 0x0000010d,
    CXCursor_OMPTargetSimdDirective = 0x0000010e,
    CXCursor_OMPTeamsDistributeDirective = 0x0000010f,
    CXCursor_OMPTeamsDistributeSimdDirective = 0x00000110,
    CXCursor_OMPTeamsDistributeParallelForSimdDirective = 0x00000111,
    CXCursor_OMPTeamsDistributeParallelForDirective = 0x00000112,
    CXCursor_OMPTargetTeamsDirective = 0x00000113,
    CXCursor_OMPTargetTeamsDistributeDirective = 0x00000114,
    CXCursor_OMPTargetTeamsDistributeParallelForDirective = 0x00000115,
    CXCursor_OMPTargetTeamsDistributeParallelForSimdDirective = 0x00000116,
    CXCursor_OMPTargetTeamsDistributeSimdDirective = 0x00000117,
    CXCursor_LastStmt = 0x00000117,
    CXCursor_TranslationUnit = 0x0000012c,
    CXCursor_FirstAttr = 0x00000190,
    CXCursor_UnexposedAttr = 0x00000190,
    CXCursor_IBActionAttr = 0x00000191,
    CXCursor_IBOutletAttr = 0x00000192,
    CXCursor_IBOutletCollectionAttr = 0x00000193,
    CXCursor_CXXFinalAttr = 0x00000194,
    CXCursor_CXXOverrideAttr = 0x00000195,
    CXCursor_AnnotateAttr = 0x00000196,
    CXCursor_AsmLabelAttr = 0x00000197,
    CXCursor_PackedAttr = 0x00000198,
    CXCursor_PureAttr = 0x00000199,
    CXCursor_ConstAttr = 0x0000019a,
    CXCursor_NoDuplicateAttr = 0x0000019b,
    CXCursor_CUDAConstantAttr = 0x0000019c,
    CXCursor_CUDADeviceAttr = 0x0000019d,
    CXCursor_CUDAGlobalAttr = 0x0000019e,
    CXCursor_CUDAHostAttr = 0x0000019f,
    CXCursor_CUDASharedAttr = 0x000001a0,
    CXCursor_VisibilityAttr = 0x000001a1,
    CXCursor_DLLExport = 0x000001a2,
    CXCursor_DLLImport = 0x000001a3,
    CXCursor_NSReturnsRetained = 0x000001a4,
    CXCursor_NSReturnsNotRetained = 0x000001a5,
    CXCursor_NSReturnsAutoreleased = 0x000001a6,
    CXCursor_NSConsumesSelf = 0x000001a7,
    CXCursor_NSConsumed = 0x000001a8,
    CXCursor_ObjCException = 0x000001a9,
    CXCursor_ObjCNSObject = 0x000001aa,
    CXCursor_ObjCIndependentClass = 0x000001ab,
    CXCursor_ObjCPreciseLifetime = 0x000001ac,
    CXCursor_ObjCReturnsInnerPointer = 0x000001ad,
    CXCursor_ObjCRequiresSuper = 0x000001ae,
    CXCursor_ObjCRootClass = 0x000001af,
    CXCursor_ObjCSubclassingRestricted = 0x000001b0,
    CXCursor_ObjCExplicitProtocolImpl = 0x000001b1,
    CXCursor_ObjCDesignatedInitializer = 0x000001b2,
    CXCursor_ObjCRuntimeVisible = 0x000001b3,
    CXCursor_ObjCBoxable = 0x000001b4,
    CXCursor_FlagEnum = 0x000001b5,
    CXCursor_LastAttr = 0x000001b5,
    CXCursor_PreprocessingDirective = 0x000001f4,
    CXCursor_MacroDefinition = 0x000001f5,
    CXCursor_MacroExpansion = 0x000001f6,
    CXCursor_MacroInstantiation = 0x000001f6,
    CXCursor_InclusionDirective = 0x000001f7,
    CXCursor_FirstPreprocessing = 0x000001f4,
    CXCursor_LastPreprocessing = 0x000001f7,
    CXCursor_ModuleImportDecl = 0x00000258,
    CXCursor_TypeAliasTemplateDecl = 0x00000259,
    CXCursor_StaticAssert = 0x0000025a,
    CXCursor_FriendDecl = 0x0000025b,
    CXCursor_FirstExtraDecl = 0x00000258,
    CXCursor_LastExtraDecl = 0x0000025b,
    CXCursor_OverloadCandidate = 0x000002bc,
}

enum CXLinkageKind {
    CXLinkage_Invalid = 0x00000000,
    CXLinkage_NoLinkage = 0x00000001,
    CXLinkage_Internal = 0x00000002,
    CXLinkage_UniqueExternal = 0x00000003,
    CXLinkage_External = 0x00000004,
}

enum CXVisibilityKind {
    CXVisibility_Invalid = 0x00000000,
    CXVisibility_Hidden = 0x00000001,
    CXVisibility_Protected = 0x00000002,
    CXVisibility_Default = 0x00000003,
}

enum CXLanguageKind {
    CXLanguage_Invalid = 0x00000000,
    CXLanguage_C = 0x00000001,
    CXLanguage_ObjC = 0x00000002,
    CXLanguage_CPlusPlus = 0x00000003,
}

enum CXTLSKind {
    CXTLS_None = 0x00000000,
    CXTLS_Dynamic = 0x00000001,
    CXTLS_Static = 0x00000002,
}

enum CXTypeKind {
    CXType_Invalid = 0x00000000,
    CXType_Unexposed = 0x00000001,
    CXType_Void = 0x00000002,
    CXType_Bool = 0x00000003,
    CXType_Char_U = 0x00000004,
    CXType_UChar = 0x00000005,
    CXType_Char16 = 0x00000006,
    CXType_Char32 = 0x00000007,
    CXType_UShort = 0x00000008,
    CXType_UInt = 0x00000009,
    CXType_ULong = 0x0000000a,
    CXType_ULongLong = 0x0000000b,
    CXType_UInt128 = 0x0000000c,
    CXType_Char_S = 0x0000000d,
    CXType_SChar = 0x0000000e,
    CXType_WChar = 0x0000000f,
    CXType_Short = 0x00000010,
    CXType_Int = 0x00000011,
    CXType_Long = 0x00000012,
    CXType_LongLong = 0x00000013,
    CXType_Int128 = 0x00000014,
    CXType_Float = 0x00000015,
    CXType_Double = 0x00000016,
    CXType_LongDouble = 0x00000017,
    CXType_NullPtr = 0x00000018,
    CXType_Overload = 0x00000019,
    CXType_Dependent = 0x0000001a,
    CXType_ObjCId = 0x0000001b,
    CXType_ObjCClass = 0x0000001c,
    CXType_ObjCSel = 0x0000001d,
    CXType_Float128 = 0x0000001e,
    CXType_Half = 0x0000001f,
    CXType_Float16 = 0x00000020,
    CXType_ShortAccum = 0x00000021,
    CXType_Accum = 0x00000022,
    CXType_LongAccum = 0x00000023,
    CXType_UShortAccum = 0x00000024,
    CXType_UAccum = 0x00000025,
    CXType_ULongAccum = 0x00000026,
    CXType_FirstBuiltin = 0x00000002,
    CXType_LastBuiltin = 0x00000026,
    CXType_Complex = 0x00000064,
    CXType_Pointer = 0x00000065,
    CXType_BlockPointer = 0x00000066,
    CXType_LValueReference = 0x00000067,
    CXType_RValueReference = 0x00000068,
    CXType_Record = 0x00000069,
    CXType_Enum = 0x0000006a,
    CXType_Typedef = 0x0000006b,
    CXType_ObjCInterface = 0x0000006c,
    CXType_ObjCObjectPointer = 0x0000006d,
    CXType_FunctionNoProto = 0x0000006e,
    CXType_FunctionProto = 0x0000006f,
    CXType_ConstantArray = 0x00000070,
    CXType_Vector = 0x00000071,
    CXType_IncompleteArray = 0x00000072,
    CXType_VariableArray = 0x00000073,
    CXType_DependentSizedArray = 0x00000074,
    CXType_MemberPointer = 0x00000075,
    CXType_Auto = 0x00000076,
    CXType_Elaborated = 0x00000077,
    CXType_Pipe = 0x00000078,
    CXType_OCLImage1dRO = 0x00000079,
    CXType_OCLImage1dArrayRO = 0x0000007a,
    CXType_OCLImage1dBufferRO = 0x0000007b,
    CXType_OCLImage2dRO = 0x0000007c,
    CXType_OCLImage2dArrayRO = 0x0000007d,
    CXType_OCLImage2dDepthRO = 0x0000007e,
    CXType_OCLImage2dArrayDepthRO = 0x0000007f,
    CXType_OCLImage2dMSAARO = 0x00000080,
    CXType_OCLImage2dArrayMSAARO = 0x00000081,
    CXType_OCLImage2dMSAADepthRO = 0x00000082,
    CXType_OCLImage2dArrayMSAADepthRO = 0x00000083,
    CXType_OCLImage3dRO = 0x00000084,
    CXType_OCLImage1dWO = 0x00000085,
    CXType_OCLImage1dArrayWO = 0x00000086,
    CXType_OCLImage1dBufferWO = 0x00000087,
    CXType_OCLImage2dWO = 0x00000088,
    CXType_OCLImage2dArrayWO = 0x00000089,
    CXType_OCLImage2dDepthWO = 0x0000008a,
    CXType_OCLImage2dArrayDepthWO = 0x0000008b,
    CXType_OCLImage2dMSAAWO = 0x0000008c,
    CXType_OCLImage2dArrayMSAAWO = 0x0000008d,
    CXType_OCLImage2dMSAADepthWO = 0x0000008e,
    CXType_OCLImage2dArrayMSAADepthWO = 0x0000008f,
    CXType_OCLImage3dWO = 0x00000090,
    CXType_OCLImage1dRW = 0x00000091,
    CXType_OCLImage1dArrayRW = 0x00000092,
    CXType_OCLImage1dBufferRW = 0x00000093,
    CXType_OCLImage2dRW = 0x00000094,
    CXType_OCLImage2dArrayRW = 0x00000095,
    CXType_OCLImage2dDepthRW = 0x00000096,
    CXType_OCLImage2dArrayDepthRW = 0x00000097,
    CXType_OCLImage2dMSAARW = 0x00000098,
    CXType_OCLImage2dArrayMSAARW = 0x00000099,
    CXType_OCLImage2dMSAADepthRW = 0x0000009a,
    CXType_OCLImage2dArrayMSAADepthRW = 0x0000009b,
    CXType_OCLImage3dRW = 0x0000009c,
    CXType_OCLSampler = 0x0000009d,
    CXType_OCLEvent = 0x0000009e,
    CXType_OCLQueue = 0x0000009f,
    CXType_OCLReserveID = 0x000000a0,
    CXType_ObjCObject = 0x000000a1,
    CXType_ObjCTypeParam = 0x000000a2,
    CXType_Attributed = 0x000000a3,
    CXType_OCLIntelSubgroupAVCMcePayload = 0x000000a4,
    CXType_OCLIntelSubgroupAVCImePayload = 0x000000a5,
    CXType_OCLIntelSubgroupAVCRefPayload = 0x000000a6,
    CXType_OCLIntelSubgroupAVCSicPayload = 0x000000a7,
    CXType_OCLIntelSubgroupAVCMceResult = 0x000000a8,
    CXType_OCLIntelSubgroupAVCImeResult = 0x000000a9,
    CXType_OCLIntelSubgroupAVCRefResult = 0x000000aa,
    CXType_OCLIntelSubgroupAVCSicResult = 0x000000ab,
    CXType_OCLIntelSubgroupAVCImeResultSingleRefStreamout = 0x000000ac,
    CXType_OCLIntelSubgroupAVCImeResultDualRefStreamout = 0x000000ad,
    CXType_OCLIntelSubgroupAVCImeSingleRefStreamin = 0x000000ae,
    CXType_OCLIntelSubgroupAVCImeDualRefStreamin = 0x000000af,
}

enum CXCallingConv {
    Default = 0x00000000,
    C = 0x00000001,
    X86StdCall = 0x00000002,
    X86FastCall = 0x00000003,
    X86ThisCall = 0x00000004,
    X86Pascal = 0x00000005,
    AAPCS = 0x00000006,
    AAPCS_VFP = 0x00000007,
    X86RegCall = 0x00000008,
    IntelOclBicc = 0x00000009,
    Win64 = 0x0000000a,
    X86_64Win64 = 0x0000000a,
    X86_64SysV = 0x0000000b,
    X86VectorCall = 0x0000000c,
    Swift = 0x0000000d,
    PreserveMost = 0x0000000e,
    PreserveAll = 0x0000000f,
    AArch64VectorCall = 0x00000010,
    Invalid = 0x00000064,
    Unexposed = 0x000000c8,
}

enum CXTemplateArgumentKind {
    Null = 0x00000000,
    Type = 0x00000001,
    Declaration = 0x00000002,
    NullPtr = 0x00000003,
    Integral = 0x00000004,
    Template = 0x00000005,
    TemplateExpansion = 0x00000006,
    Expression = 0x00000007,
    Pack = 0x00000008,
    Invalid = 0x00000009,
}

enum CXTypeNullabilityKind {
    CXTypeNullability_NonNull = 0x00000000,
    CXTypeNullability_Nullable = 0x00000001,
    CXTypeNullability_Unspecified = 0x00000002,
    CXTypeNullability_Invalid = 0x00000003,
}

enum CXTypeLayoutError {
    Invalid = -0x0000001,
    Incomplete = -0x0000002,
    Dependent = -0x0000003,
    NotConstantSize = -0x0000004,
    InvalidFieldName = -0x0000005,
}

enum CXRefQualifierKind {
    CXRefQualifier_None = 0x00000000,
    CXRefQualifier_LValue = 0x00000001,
    CXRefQualifier_RValue = 0x00000002,
}

enum CX_CXXAccessSpecifier {
    CX_CXXInvalidAccessSpecifier = 0x00000000,
    CX_CXXPublic = 0x00000001,
    CX_CXXProtected = 0x00000002,
    CX_CXXPrivate = 0x00000003,
}

enum CX_StorageClass {
    CX_SC_Invalid = 0x00000000,
    CX_SC_None = 0x00000001,
    CX_SC_Extern = 0x00000002,
    CX_SC_Static = 0x00000003,
    CX_SC_PrivateExtern = 0x00000004,
    CX_SC_OpenCLWorkGroupLocal = 0x00000005,
    CX_SC_Auto = 0x00000006,
    CX_SC_Register = 0x00000007,
}

enum CXChildVisitResult {
    CXChildVisit_Break = 0x00000000,
    CXChildVisit_Continue = 0x00000001,
    CXChildVisit_Recurse = 0x00000002,
}

enum CXPrintingPolicyProperty {
    CXPrintingPolicy_Indentation = 0x00000000,
    CXPrintingPolicy_SuppressSpecifiers = 0x00000001,
    CXPrintingPolicy_SuppressTagKeyword = 0x00000002,
    CXPrintingPolicy_IncludeTagDefinition = 0x00000003,
    CXPrintingPolicy_SuppressScope = 0x00000004,
    CXPrintingPolicy_SuppressUnwrittenScope = 0x00000005,
    CXPrintingPolicy_SuppressInitializers = 0x00000006,
    CXPrintingPolicy_ConstantArraySizeAsWritten = 0x00000007,
    CXPrintingPolicy_AnonymousTagLocations = 0x00000008,
    CXPrintingPolicy_SuppressStrongLifetime = 0x00000009,
    CXPrintingPolicy_SuppressLifetimeQualifiers = 0x0000000a,
    CXPrintingPolicy_SuppressTemplateArgsInCXXConstructors = 0x0000000b,
    CXPrintingPolicy_Bool = 0x0000000c,
    CXPrintingPolicy_Restrict = 0x0000000d,
    CXPrintingPolicy_Alignof = 0x0000000e,
    CXPrintingPolicy_UnderscoreAlignof = 0x0000000f,
    CXPrintingPolicy_UseVoidForZeroParams = 0x00000010,
    CXPrintingPolicy_TerseOutput = 0x00000011,
    CXPrintingPolicy_PolishForDeclaration = 0x00000012,
    CXPrintingPolicy_Half = 0x00000013,
    CXPrintingPolicy_MSWChar = 0x00000014,
    CXPrintingPolicy_IncludeNewlines = 0x00000015,
    CXPrintingPolicy_MSVCFormatting = 0x00000016,
    CXPrintingPolicy_ConstantsAsWritten = 0x00000017,
    CXPrintingPolicy_SuppressImplicitBase = 0x00000018,
    CXPrintingPolicy_FullyQualifiedName = 0x00000019,
    CXPrintingPolicy_LastProperty = 0x00000019,
}

enum CXObjCPropertyAttrKind {
    CXObjCPropertyAttr_noattr = 0x00000000,
    CXObjCPropertyAttr_readonly = 0x00000001,
    CXObjCPropertyAttr_getter = 0x00000002,
    CXObjCPropertyAttr_assign = 0x00000004,
    CXObjCPropertyAttr_readwrite = 0x00000008,
    CXObjCPropertyAttr_retain = 0x00000010,
    CXObjCPropertyAttr_copy = 0x00000020,
    CXObjCPropertyAttr_nonatomic = 0x00000040,
    CXObjCPropertyAttr_setter = 0x00000080,
    CXObjCPropertyAttr_atomic = 0x00000100,
    CXObjCPropertyAttr_weak = 0x00000200,
    CXObjCPropertyAttr_strong = 0x00000400,
    CXObjCPropertyAttr_unsafe_unretained = 0x00000800,
    CXObjCPropertyAttr_class = 0x00001000,
}

enum CXObjCDeclQualifierKind {
    CXObjCDeclQualifier_None = 0x00000000,
    CXObjCDeclQualifier_In = 0x00000001,
    CXObjCDeclQualifier_Inout = 0x00000002,
    CXObjCDeclQualifier_Out = 0x00000004,
    CXObjCDeclQualifier_Bycopy = 0x00000008,
    CXObjCDeclQualifier_Byref = 0x00000010,
    CXObjCDeclQualifier_Oneway = 0x00000020,
}

enum CXNameRefFlags {
    CXNameRange_WantQualifier = 0x00000001,
    CXNameRange_WantTemplateArgs = 0x00000002,
    CXNameRange_WantSinglePiece = 0x00000004,
}

enum CXTokenKind {
    CXToken_Punctuation = 0x00000000,
    CXToken_Keyword = 0x00000001,
    CXToken_Identifier = 0x00000002,
    CXToken_Literal = 0x00000003,
    CXToken_Comment = 0x00000004,
}

enum CXCompletionChunkKind {
    CXCompletionChunk_Optional = 0x00000000,
    CXCompletionChunk_TypedText = 0x00000001,
    CXCompletionChunk_Text = 0x00000002,
    CXCompletionChunk_Placeholder = 0x00000003,
    CXCompletionChunk_Informative = 0x00000004,
    CXCompletionChunk_CurrentParameter = 0x00000005,
    CXCompletionChunk_LeftParen = 0x00000006,
    CXCompletionChunk_RightParen = 0x00000007,
    CXCompletionChunk_LeftBracket = 0x00000008,
    CXCompletionChunk_RightBracket = 0x00000009,
    CXCompletionChunk_LeftBrace = 0x0000000a,
    CXCompletionChunk_RightBrace = 0x0000000b,
    CXCompletionChunk_LeftAngle = 0x0000000c,
    CXCompletionChunk_RightAngle = 0x0000000d,
    CXCompletionChunk_Comma = 0x0000000e,
    CXCompletionChunk_ResultType = 0x0000000f,
    CXCompletionChunk_Colon = 0x00000010,
    CXCompletionChunk_SemiColon = 0x00000011,
    CXCompletionChunk_Equal = 0x00000012,
    CXCompletionChunk_HorizontalSpace = 0x00000013,
    CXCompletionChunk_VerticalSpace = 0x00000014,
}

enum CXCodeComplete_Flags {
    CXCodeComplete_IncludeMacros = 0x00000001,
    CXCodeComplete_IncludeCodePatterns = 0x00000002,
    CXCodeComplete_IncludeBriefComments = 0x00000004,
    CXCodeComplete_SkipPreamble = 0x00000008,
    CXCodeComplete_IncludeCompletionsWithFixIts = 0x00000010,
}

enum CXCompletionContext {
    Unexposed = 0x00000000,
    AnyType = 0x00000001,
    AnyValue = 0x00000002,
    ObjCObjectValue = 0x00000004,
    ObjCSelectorValue = 0x00000008,
    CXXClassTypeValue = 0x00000010,
    DotMemberAccess = 0x00000020,
    ArrowMemberAccess = 0x00000040,
    ObjCPropertyAccess = 0x00000080,
    EnumTag = 0x00000100,
    UnionTag = 0x00000200,
    StructTag = 0x00000400,
    ClassTag = 0x00000800,
    Namespace = 0x00001000,
    NestedNameSpecifier = 0x00002000,
    ObjCInterface = 0x00004000,
    ObjCProtocol = 0x00008000,
    ObjCCategory = 0x00010000,
    ObjCInstanceMessage = 0x00020000,
    ObjCClassMessage = 0x00040000,
    ObjCSelectorName = 0x00080000,
    MacroName = 0x00100000,
    NaturalLanguage = 0x00200000,
    IncludedFile = 0x00400000,
    Unknown = 0x007fffff,
}

enum CXEvalResultKind {
    CXEval_Int = 0x00000001,
    CXEval_Float = 0x00000002,
    CXEval_ObjCStrLiteral = 0x00000003,
    CXEval_StrLiteral = 0x00000004,
    CXEval_CFStr = 0x00000005,
    CXEval_Other = 0x00000006,
    CXEval_UnExposed = 0x00000000,
}

enum CXVisitorResult {
    CXVisit_Break = 0x00000000,
    CXVisit_Continue = 0x00000001,
}

enum CXResult {
    Success = 0x00000000,
    Invalid = 0x00000001,
    VisitBreak = 0x00000002,
}

enum CXIdxEntityKind {
    CXIdxEntity_Unexposed = 0x00000000,
    CXIdxEntity_Typedef = 0x00000001,
    CXIdxEntity_Function = 0x00000002,
    CXIdxEntity_Variable = 0x00000003,
    CXIdxEntity_Field = 0x00000004,
    CXIdxEntity_EnumConstant = 0x00000005,
    CXIdxEntity_ObjCClass = 0x00000006,
    CXIdxEntity_ObjCProtocol = 0x00000007,
    CXIdxEntity_ObjCCategory = 0x00000008,
    CXIdxEntity_ObjCInstanceMethod = 0x00000009,
    CXIdxEntity_ObjCClassMethod = 0x0000000a,
    CXIdxEntity_ObjCProperty = 0x0000000b,
    CXIdxEntity_ObjCIvar = 0x0000000c,
    CXIdxEntity_Enum = 0x0000000d,
    CXIdxEntity_Struct = 0x0000000e,
    CXIdxEntity_Union = 0x0000000f,
    CXIdxEntity_CXXClass = 0x00000010,
    CXIdxEntity_CXXNamespace = 0x00000011,
    CXIdxEntity_CXXNamespaceAlias = 0x00000012,
    CXIdxEntity_CXXStaticVariable = 0x00000013,
    CXIdxEntity_CXXStaticMethod = 0x00000014,
    CXIdxEntity_CXXInstanceMethod = 0x00000015,
    CXIdxEntity_CXXConstructor = 0x00000016,
    CXIdxEntity_CXXDestructor = 0x00000017,
    CXIdxEntity_CXXConversionFunction = 0x00000018,
    CXIdxEntity_CXXTypeAlias = 0x00000019,
    CXIdxEntity_CXXInterface = 0x0000001a,
}

enum CXIdxEntityLanguage {
    CXIdxEntityLang_None = 0x00000000,
    CXIdxEntityLang_C = 0x00000001,
    CXIdxEntityLang_ObjC = 0x00000002,
    CXIdxEntityLang_CXX = 0x00000003,
    CXIdxEntityLang_Swift = 0x00000004,
}

enum CXIdxEntityCXXTemplateKind {
    CXIdxEntity_NonTemplate = 0x00000000,
    CXIdxEntity_Template = 0x00000001,
    CXIdxEntity_TemplatePartialSpecialization = 0x00000002,
    CXIdxEntity_TemplateSpecialization = 0x00000003,
}

enum CXIdxAttrKind {
    CXIdxAttr_Unexposed = 0x00000000,
    CXIdxAttr_IBAction = 0x00000001,
    CXIdxAttr_IBOutlet = 0x00000002,
    CXIdxAttr_IBOutletCollection = 0x00000003,
}

enum CXIdxDeclInfoFlags {
    CXIdxDeclFlag_Skipped = 0x00000001,
}

enum CXIdxObjCContainerKind {
    CXIdxObjCContainer_ForwardRef = 0x00000000,
    CXIdxObjCContainer_Interface = 0x00000001,
    CXIdxObjCContainer_Implementation = 0x00000002,
}

enum CXIdxEntityRefKind {
    CXIdxEntityRef_Direct = 0x00000001,
    CXIdxEntityRef_Implicit = 0x00000002,
}

enum CXSymbolRole {
    None = 0x00000000,
    Declaration = 0x00000001,
    Definition = 0x00000002,
    Reference = 0x00000004,
    Read = 0x00000008,
    Write = 0x00000010,
    Call = 0x00000020,
    Dynamic = 0x00000040,
    AddressOf = 0x00000080,
    Implicit = 0x00000100,
}

enum CXIndexOptFlags {
    CXIndexOpt_None = 0x00000000,
    CXIndexOpt_SuppressRedundantRefs = 0x00000001,
    CXIndexOpt_IndexFunctionLocalSymbols = 0x00000002,
    CXIndexOpt_IndexImplicitTemplateInstantiations = 0x00000004,
    CXIndexOpt_SuppressWarnings = 0x00000008,
    CXIndexOpt_SkipParsedBodiesInSession = 0x00000010,
}

struct CXTargetInfoImpl{
}

struct CXTranslationUnitImpl{
}

struct CXUnsavedFile{
    byte* Filename;
    byte* Contents;
    uint Length;
}

struct CXVersion{
    int Major;
    int Minor;
    int Subminor;
}

struct CXFileUniqueID{
    ulong[3] data;
}

struct CXSourceLocation{
    void*[2] ptr_data;
    uint int_data;
}

struct CXSourceRange{
    void*[2] ptr_data;
    uint begin_int_data;
    uint end_int_data;
}

struct CXSourceRangeList{
    uint count;
    CXSourceRange* ranges;
}

struct CXTUResourceUsageEntry{
    CXTUResourceUsageKind kind;
    uint amount;
}

struct CXTUResourceUsage{
    void* data;
    uint numEntries;
    CXTUResourceUsageEntry* entries;
}

struct CXCursor{
    CXCursorKind kind;
    int xdata;
    void*[3] data;
}

struct CXPlatformAvailability{
    CXString Platform;
    CXVersion Introduced;
    CXVersion Deprecated;
    CXVersion Obsoleted;
    int Unavailable;
    CXString Message;
}

struct CXCursorSetImpl{
}

struct CXType{
    CXTypeKind kind;
    void*[2] data;
}

struct CXToken{
    uint[4] int_data;
    void* ptr_data;
}

struct CXCompletionResult{
    CXCursorKind CursorKind;
    void* CompletionString;
}

struct CXCodeCompleteResults{
    CXCompletionResult* Results;
    uint NumResults;
}

struct CXCursorAndRangeVisitor{
    void* context;
    void* visit;
}

struct CXIdxLoc{
    void*[2] ptr_data;
    uint int_data;
}

struct CXIdxIncludedFileInfo{
    CXIdxLoc hashLoc;
    byte* filename;
    void* file;
    int isImport;
    int isAngled;
    int isModuleImport;
}

struct CXIdxImportedASTFileInfo{
    void* file;
    void* _module;
    CXIdxLoc loc;
    int isImplicit;
}

struct CXIdxAttrInfo{
    CXIdxAttrKind kind;
    CXCursor cursor;
    CXIdxLoc loc;
}

struct CXIdxEntityInfo{
    CXIdxEntityKind kind;
    CXIdxEntityCXXTemplateKind templateKind;
    CXIdxEntityLanguage lang;
    byte* name;
    byte* USR;
    CXCursor cursor;
    CXIdxAttrInfo** attributes;
    uint numAttributes;
}

struct CXIdxContainerInfo{
    CXCursor cursor;
}

struct CXIdxIBOutletCollectionAttrInfo{
    CXIdxAttrInfo* attrInfo;
    CXIdxEntityInfo* objcClass;
    CXCursor classCursor;
    CXIdxLoc classLoc;
}

struct CXIdxDeclInfo{
    CXIdxEntityInfo* entityInfo;
    CXCursor cursor;
    CXIdxLoc loc;
    CXIdxContainerInfo* semanticContainer;
    CXIdxContainerInfo* lexicalContainer;
    int isRedeclaration;
    int isDefinition;
    int isContainer;
    CXIdxContainerInfo* declAsContainer;
    int isImplicit;
    CXIdxAttrInfo** attributes;
    uint numAttributes;
    uint flags;
}

struct CXIdxObjCContainerDeclInfo{
    CXIdxDeclInfo* declInfo;
    CXIdxObjCContainerKind kind;
}

struct CXIdxBaseClassInfo{
    CXIdxEntityInfo* base;
    CXCursor cursor;
    CXIdxLoc loc;
}

struct CXIdxObjCProtocolRefInfo{
    CXIdxEntityInfo* protocol;
    CXCursor cursor;
    CXIdxLoc loc;
}

struct CXIdxObjCProtocolRefListInfo{
    CXIdxObjCProtocolRefInfo** protocols;
    uint numProtocols;
}

struct CXIdxObjCInterfaceDeclInfo{
    CXIdxObjCContainerDeclInfo* containerInfo;
    CXIdxBaseClassInfo* superInfo;
    CXIdxObjCProtocolRefListInfo* protocols;
}

struct CXIdxObjCCategoryDeclInfo{
    CXIdxObjCContainerDeclInfo* containerInfo;
    CXIdxEntityInfo* objcClass;
    CXCursor classCursor;
    CXIdxLoc classLoc;
    CXIdxObjCProtocolRefListInfo* protocols;
}

struct CXIdxObjCPropertyDeclInfo{
    CXIdxDeclInfo* declInfo;
    CXIdxEntityInfo* getter;
    CXIdxEntityInfo* setter;
}

struct CXIdxCXXClassDeclInfo{
    CXIdxDeclInfo* declInfo;
    CXIdxBaseClassInfo** bases;
    uint numBases;
}

struct CXIdxEntityRefInfo{
    CXIdxEntityRefKind kind;
    CXCursor cursor;
    CXIdxLoc loc;
    CXIdxEntityInfo* referencedEntity;
    CXIdxEntityInfo* parentEntity;
    CXIdxContainerInfo* container;
    CXSymbolRole role;
}

struct IndexerCallbacks{
    void* abortQuery;
    void* diagnostic;
    void* enteredMainFile;
    void* ppIncludedFile;
    void* importedASTFile;
    void* startedTranslationUnit;
    void* indexDeclaration;
    void* indexEntityReference;
}

extern(C) void* clang_createIndex(int excludeDeclarationsFromPCH, int displayDiagnostics);
extern(C) void clang_disposeIndex(void* index);
extern(C) void clang_CXIndex_setGlobalOptions(void* , uint options);
extern(C) uint clang_CXIndex_getGlobalOptions(void* );
extern(C) void clang_CXIndex_setInvocationEmissionPathOption(void* , byte* Path);
extern(C) CXString clang_getFileName(void* SFile);
extern(C) long clang_getFileTime(void* SFile);
extern(C) int clang_getFileUniqueID(void* file, CXFileUniqueID* outID);
extern(C) uint clang_isFileMultipleIncludeGuarded(CXTranslationUnitImpl* tu, void* file);
extern(C) void* clang_getFile(CXTranslationUnitImpl* tu, byte* file_name);
extern(C) byte* clang_getFileContents(CXTranslationUnitImpl* tu, void* file, ulong* size);
extern(C) int clang_File_isEqual(void* file1, void* file2);
extern(C) CXString clang_File_tryGetRealPathName(void* file);
extern(C) CXSourceLocation clang_getNullLocation();
extern(C) uint clang_equalLocations(CXSourceLocation loc1, CXSourceLocation loc2);
extern(C) CXSourceLocation clang_getLocation(CXTranslationUnitImpl* tu, void* file, uint line, uint column);
extern(C) CXSourceLocation clang_getLocationForOffset(CXTranslationUnitImpl* tu, void* file, uint offset);
extern(C) int clang_Location_isInSystemHeader(CXSourceLocation location);
extern(C) int clang_Location_isFromMainFile(CXSourceLocation location);
extern(C) CXSourceRange clang_getNullRange();
extern(C) CXSourceRange clang_getRange(CXSourceLocation begin, CXSourceLocation end);
extern(C) uint clang_equalRanges(CXSourceRange range1, CXSourceRange range2);
extern(C) int clang_Range_isNull(CXSourceRange range);
extern(C) void clang_getExpansionLocation(CXSourceLocation location, void** file, uint* line, uint* column, uint* offset);
extern(C) void clang_getPresumedLocation(CXSourceLocation location, CXString* filename, uint* line, uint* column);
extern(C) void clang_getInstantiationLocation(CXSourceLocation location, void** file, uint* line, uint* column, uint* offset);
extern(C) void clang_getSpellingLocation(CXSourceLocation location, void** file, uint* line, uint* column, uint* offset);
extern(C) void clang_getFileLocation(CXSourceLocation location, void** file, uint* line, uint* column, uint* offset);
extern(C) CXSourceLocation clang_getRangeStart(CXSourceRange range);
extern(C) CXSourceLocation clang_getRangeEnd(CXSourceRange range);
extern(C) CXSourceRangeList* clang_getSkippedRanges(CXTranslationUnitImpl* tu, void* file);
extern(C) CXSourceRangeList* clang_getAllSkippedRanges(CXTranslationUnitImpl* tu);
extern(C) void clang_disposeSourceRangeList(CXSourceRangeList* ranges);
extern(C) uint clang_getNumDiagnosticsInSet(void* Diags);
extern(C) void* clang_getDiagnosticInSet(void* Diags, uint Index);
extern(C) void* clang_loadDiagnostics(byte* file, CXLoadDiag_Error* error, CXString* errorString);
extern(C) void clang_disposeDiagnosticSet(void* Diags);
extern(C) void* clang_getChildDiagnostics(void* D);
extern(C) uint clang_getNumDiagnostics(CXTranslationUnitImpl* Unit);
extern(C) void* clang_getDiagnostic(CXTranslationUnitImpl* Unit, uint Index);
extern(C) void* clang_getDiagnosticSetFromTU(CXTranslationUnitImpl* Unit);
extern(C) void clang_disposeDiagnostic(void* Diagnostic);
extern(C) CXString clang_formatDiagnostic(void* Diagnostic, uint Options);
extern(C) uint clang_defaultDiagnosticDisplayOptions();
extern(C) CXDiagnosticSeverity clang_getDiagnosticSeverity(void* );
extern(C) CXSourceLocation clang_getDiagnosticLocation(void* );
extern(C) CXString clang_getDiagnosticSpelling(void* );
extern(C) CXString clang_getDiagnosticOption(void* Diag, CXString* Disable);
extern(C) uint clang_getDiagnosticCategory(void* );
extern(C) CXString clang_getDiagnosticCategoryName(uint Category);
extern(C) CXString clang_getDiagnosticCategoryText(void* );
extern(C) uint clang_getDiagnosticNumRanges(void* );
extern(C) CXSourceRange clang_getDiagnosticRange(void* Diagnostic, uint Range);
extern(C) uint clang_getDiagnosticNumFixIts(void* Diagnostic);
extern(C) CXString clang_getDiagnosticFixIt(void* Diagnostic, uint FixIt, CXSourceRange* ReplacementRange);
extern(C) CXString clang_getTranslationUnitSpelling(CXTranslationUnitImpl* CTUnit);
extern(C) CXTranslationUnitImpl* clang_createTranslationUnitFromSourceFile(void* CIdx, byte* source_filename, int num_clang_command_line_args, byte** clang_command_line_args, uint num_unsaved_files, CXUnsavedFile* unsaved_files);
extern(C) CXTranslationUnitImpl* clang_createTranslationUnit(void* CIdx, byte* ast_filename);
extern(C) CXErrorCode clang_createTranslationUnit2(void* CIdx, byte* ast_filename, CXTranslationUnitImpl** out_TU);
extern(C) uint clang_defaultEditingTranslationUnitOptions();
extern(C) CXTranslationUnitImpl* clang_parseTranslationUnit(void* CIdx, byte* source_filename, byte** command_line_args, int num_command_line_args, CXUnsavedFile* unsaved_files, uint num_unsaved_files, uint options);
extern(C) CXErrorCode clang_parseTranslationUnit2(void* CIdx, byte* source_filename, byte** command_line_args, int num_command_line_args, CXUnsavedFile* unsaved_files, uint num_unsaved_files, uint options, CXTranslationUnitImpl** out_TU);
extern(C) CXErrorCode clang_parseTranslationUnit2FullArgv(void* CIdx, byte* source_filename, byte** command_line_args, int num_command_line_args, CXUnsavedFile* unsaved_files, uint num_unsaved_files, uint options, CXTranslationUnitImpl** out_TU);
extern(C) uint clang_defaultSaveOptions(CXTranslationUnitImpl* TU);
extern(C) int clang_saveTranslationUnit(CXTranslationUnitImpl* TU, byte* FileName, uint options);
extern(C) uint clang_suspendTranslationUnit(CXTranslationUnitImpl* );
extern(C) void clang_disposeTranslationUnit(CXTranslationUnitImpl* );
extern(C) uint clang_defaultReparseOptions(CXTranslationUnitImpl* TU);
extern(C) int clang_reparseTranslationUnit(CXTranslationUnitImpl* TU, uint num_unsaved_files, CXUnsavedFile* unsaved_files, uint options);
extern(C) byte* clang_getTUResourceUsageName(CXTUResourceUsageKind kind);
extern(C) CXTUResourceUsage clang_getCXTUResourceUsage(CXTranslationUnitImpl* TU);
extern(C) void clang_disposeCXTUResourceUsage(CXTUResourceUsage usage);
extern(C) CXTargetInfoImpl* clang_getTranslationUnitTargetInfo(CXTranslationUnitImpl* CTUnit);
extern(C) void clang_TargetInfo_dispose(CXTargetInfoImpl* Info);
extern(C) CXString clang_TargetInfo_getTriple(CXTargetInfoImpl* Info);
extern(C) int clang_TargetInfo_getPointerWidth(CXTargetInfoImpl* Info);
extern(C) CXCursor clang_getNullCursor();
extern(C) CXCursor clang_getTranslationUnitCursor(CXTranslationUnitImpl* );
extern(C) uint clang_equalCursors(CXCursor , CXCursor );
extern(C) int clang_Cursor_isNull(CXCursor cursor);
extern(C) uint clang_hashCursor(CXCursor );
extern(C) CXCursorKind clang_getCursorKind(CXCursor );
extern(C) uint clang_isDeclaration(CXCursorKind );
extern(C) uint clang_isInvalidDeclaration(CXCursor );
extern(C) uint clang_isReference(CXCursorKind );
extern(C) uint clang_isExpression(CXCursorKind );
extern(C) uint clang_isStatement(CXCursorKind );
extern(C) uint clang_isAttribute(CXCursorKind );
extern(C) uint clang_Cursor_hasAttrs(CXCursor C);
extern(C) uint clang_isInvalid(CXCursorKind );
extern(C) uint clang_isTranslationUnit(CXCursorKind );
extern(C) uint clang_isPreprocessing(CXCursorKind );
extern(C) uint clang_isUnexposed(CXCursorKind );
extern(C) CXLinkageKind clang_getCursorLinkage(CXCursor cursor);
extern(C) CXVisibilityKind clang_getCursorVisibility(CXCursor cursor);
extern(C) CXAvailabilityKind clang_getCursorAvailability(CXCursor cursor);
extern(C) int clang_getCursorPlatformAvailability(CXCursor cursor, int* always_deprecated, CXString* deprecated_message, int* always_unavailable, CXString* unavailable_message, CXPlatformAvailability* availability, int availability_size);
extern(C) void clang_disposeCXPlatformAvailability(CXPlatformAvailability* availability);
extern(C) CXLanguageKind clang_getCursorLanguage(CXCursor cursor);
extern(C) CXTLSKind clang_getCursorTLSKind(CXCursor cursor);
extern(C) CXTranslationUnitImpl* clang_Cursor_getTranslationUnit(CXCursor );
extern(C) CXCursorSetImpl* clang_createCXCursorSet();
extern(C) void clang_disposeCXCursorSet(CXCursorSetImpl* cset);
extern(C) uint clang_CXCursorSet_contains(CXCursorSetImpl* cset, CXCursor cursor);
extern(C) uint clang_CXCursorSet_insert(CXCursorSetImpl* cset, CXCursor cursor);
extern(C) CXCursor clang_getCursorSemanticParent(CXCursor cursor);
extern(C) CXCursor clang_getCursorLexicalParent(CXCursor cursor);
extern(C) void clang_getOverriddenCursors(CXCursor cursor, CXCursor** overridden, uint* num_overridden);
extern(C) void clang_disposeOverriddenCursors(CXCursor* overridden);
extern(C) void* clang_getIncludedFile(CXCursor cursor);
extern(C) CXCursor clang_getCursor(CXTranslationUnitImpl* , CXSourceLocation );
extern(C) CXSourceLocation clang_getCursorLocation(CXCursor );
extern(C) CXSourceRange clang_getCursorExtent(CXCursor );
extern(C) CXType clang_getCursorType(CXCursor C);
extern(C) CXString clang_getTypeSpelling(CXType CT);
extern(C) CXType clang_getTypedefDeclUnderlyingType(CXCursor C);
extern(C) CXType clang_getEnumDeclIntegerType(CXCursor C);
extern(C) long clang_getEnumConstantDeclValue(CXCursor C);
extern(C) ulong clang_getEnumConstantDeclUnsignedValue(CXCursor C);
extern(C) int clang_getFieldDeclBitWidth(CXCursor C);
extern(C) int clang_Cursor_getNumArguments(CXCursor C);
extern(C) CXCursor clang_Cursor_getArgument(CXCursor C, uint i);
extern(C) int clang_Cursor_getNumTemplateArguments(CXCursor C);
extern(C) CXTemplateArgumentKind clang_Cursor_getTemplateArgumentKind(CXCursor C, uint I);
extern(C) CXType clang_Cursor_getTemplateArgumentType(CXCursor C, uint I);
extern(C) long clang_Cursor_getTemplateArgumentValue(CXCursor C, uint I);
extern(C) ulong clang_Cursor_getTemplateArgumentUnsignedValue(CXCursor C, uint I);
extern(C) uint clang_equalTypes(CXType A, CXType B);
extern(C) CXType clang_getCanonicalType(CXType T);
extern(C) uint clang_isConstQualifiedType(CXType T);
extern(C) uint clang_Cursor_isMacroFunctionLike(CXCursor C);
extern(C) uint clang_Cursor_isMacroBuiltin(CXCursor C);
extern(C) uint clang_Cursor_isFunctionInlined(CXCursor C);
extern(C) uint clang_isVolatileQualifiedType(CXType T);
extern(C) uint clang_isRestrictQualifiedType(CXType T);
extern(C) uint clang_getAddressSpace(CXType T);
extern(C) CXString clang_getTypedefName(CXType CT);
extern(C) CXType clang_getPointeeType(CXType T);
extern(C) CXCursor clang_getTypeDeclaration(CXType T);
extern(C) CXString clang_getDeclObjCTypeEncoding(CXCursor C);
extern(C) CXString clang_Type_getObjCEncoding(CXType type);
extern(C) CXString clang_getTypeKindSpelling(CXTypeKind K);
extern(C) CXCallingConv clang_getFunctionTypeCallingConv(CXType T);
extern(C) CXType clang_getResultType(CXType T);
extern(C) int clang_getExceptionSpecificationType(CXType T);
extern(C) int clang_getNumArgTypes(CXType T);
extern(C) CXType clang_getArgType(CXType T, uint i);
extern(C) CXType clang_Type_getObjCObjectBaseType(CXType T);
extern(C) uint clang_Type_getNumObjCProtocolRefs(CXType T);
extern(C) CXCursor clang_Type_getObjCProtocolDecl(CXType T, uint i);
extern(C) uint clang_Type_getNumObjCTypeArgs(CXType T);
extern(C) CXType clang_Type_getObjCTypeArg(CXType T, uint i);
extern(C) uint clang_isFunctionTypeVariadic(CXType T);
extern(C) CXType clang_getCursorResultType(CXCursor C);
extern(C) int clang_getCursorExceptionSpecificationType(CXCursor C);
extern(C) uint clang_isPODType(CXType T);
extern(C) CXType clang_getElementType(CXType T);
extern(C) long clang_getNumElements(CXType T);
extern(C) CXType clang_getArrayElementType(CXType T);
extern(C) long clang_getArraySize(CXType T);
extern(C) CXType clang_Type_getNamedType(CXType T);
extern(C) uint clang_Type_isTransparentTagTypedef(CXType T);
extern(C) CXTypeNullabilityKind clang_Type_getNullability(CXType T);
extern(C) long clang_Type_getAlignOf(CXType T);
extern(C) CXType clang_Type_getClassType(CXType T);
extern(C) long clang_Type_getSizeOf(CXType T);
extern(C) long clang_Type_getOffsetOf(CXType T, byte* S);
extern(C) CXType clang_Type_getModifiedType(CXType T);
extern(C) long clang_Cursor_getOffsetOfField(CXCursor C);
extern(C) uint clang_Cursor_isAnonymous(CXCursor C);
extern(C) int clang_Type_getNumTemplateArguments(CXType T);
extern(C) CXType clang_Type_getTemplateArgumentAsType(CXType T, uint i);
extern(C) CXRefQualifierKind clang_Type_getCXXRefQualifier(CXType T);
extern(C) uint clang_Cursor_isBitField(CXCursor C);
extern(C) uint clang_isVirtualBase(CXCursor );
extern(C) CX_CXXAccessSpecifier clang_getCXXAccessSpecifier(CXCursor );
extern(C) CX_StorageClass clang_Cursor_getStorageClass(CXCursor );
extern(C) uint clang_getNumOverloadedDecls(CXCursor cursor);
extern(C) CXCursor clang_getOverloadedDecl(CXCursor cursor, uint index);
extern(C) CXType clang_getIBOutletCollectionType(CXCursor );
extern(C) uint clang_visitChildren(CXCursor parent, void* visitor, void* client_data);
extern(C) CXString clang_getCursorUSR(CXCursor );
extern(C) CXString clang_constructUSR_ObjCClass(byte* class_name);
extern(C) CXString clang_constructUSR_ObjCCategory(byte* class_name, byte* category_name);
extern(C) CXString clang_constructUSR_ObjCProtocol(byte* protocol_name);
extern(C) CXString clang_constructUSR_ObjCIvar(byte* name, CXString classUSR);
extern(C) CXString clang_constructUSR_ObjCMethod(byte* name, uint isInstanceMethod, CXString classUSR);
extern(C) CXString clang_constructUSR_ObjCProperty(byte* property, CXString classUSR);
extern(C) CXString clang_getCursorSpelling(CXCursor );
extern(C) CXSourceRange clang_Cursor_getSpellingNameRange(CXCursor , uint pieceIndex, uint options);
extern(C) uint clang_PrintingPolicy_getProperty(void* Policy, CXPrintingPolicyProperty Property);
extern(C) void clang_PrintingPolicy_setProperty(void* Policy, CXPrintingPolicyProperty Property, uint Value);
extern(C) void* clang_getCursorPrintingPolicy(CXCursor );
extern(C) void clang_PrintingPolicy_dispose(void* Policy);
extern(C) CXString clang_getCursorPrettyPrinted(CXCursor Cursor, void* Policy);
extern(C) CXString clang_getCursorDisplayName(CXCursor );
extern(C) CXCursor clang_getCursorReferenced(CXCursor );
extern(C) CXCursor clang_getCursorDefinition(CXCursor );
extern(C) uint clang_isCursorDefinition(CXCursor );
extern(C) CXCursor clang_getCanonicalCursor(CXCursor );
extern(C) int clang_Cursor_getObjCSelectorIndex(CXCursor );
extern(C) int clang_Cursor_isDynamicCall(CXCursor C);
extern(C) CXType clang_Cursor_getReceiverType(CXCursor C);
extern(C) uint clang_Cursor_getObjCPropertyAttributes(CXCursor C, uint reserved);
extern(C) CXString clang_Cursor_getObjCPropertyGetterName(CXCursor C);
extern(C) CXString clang_Cursor_getObjCPropertySetterName(CXCursor C);
extern(C) uint clang_Cursor_getObjCDeclQualifiers(CXCursor C);
extern(C) uint clang_Cursor_isObjCOptional(CXCursor C);
extern(C) uint clang_Cursor_isVariadic(CXCursor C);
extern(C) uint clang_Cursor_isExternalSymbol(CXCursor C, CXString* language, CXString* definedIn, uint* isGenerated);
extern(C) CXSourceRange clang_Cursor_getCommentRange(CXCursor C);
extern(C) CXString clang_Cursor_getRawCommentText(CXCursor C);
extern(C) CXString clang_Cursor_getBriefCommentText(CXCursor C);
extern(C) CXString clang_Cursor_getMangling(CXCursor );
extern(C) CXStringSet* clang_Cursor_getCXXManglings(CXCursor );
extern(C) CXStringSet* clang_Cursor_getObjCManglings(CXCursor );
extern(C) void* clang_Cursor_getModule(CXCursor C);
extern(C) void* clang_getModuleForFile(CXTranslationUnitImpl* , void* );
extern(C) void* clang_Module_getASTFile(void* Module);
extern(C) void* clang_Module_getParent(void* Module);
extern(C) CXString clang_Module_getName(void* Module);
extern(C) CXString clang_Module_getFullName(void* Module);
extern(C) int clang_Module_isSystem(void* Module);
extern(C) uint clang_Module_getNumTopLevelHeaders(CXTranslationUnitImpl* , void* Module);
extern(C) void* clang_Module_getTopLevelHeader(CXTranslationUnitImpl* , void* Module, uint Index);
extern(C) uint clang_CXXConstructor_isConvertingConstructor(CXCursor C);
extern(C) uint clang_CXXConstructor_isCopyConstructor(CXCursor C);
extern(C) uint clang_CXXConstructor_isDefaultConstructor(CXCursor C);
extern(C) uint clang_CXXConstructor_isMoveConstructor(CXCursor C);
extern(C) uint clang_CXXField_isMutable(CXCursor C);
extern(C) uint clang_CXXMethod_isDefaulted(CXCursor C);
extern(C) uint clang_CXXMethod_isPureVirtual(CXCursor C);
extern(C) uint clang_CXXMethod_isStatic(CXCursor C);
extern(C) uint clang_CXXMethod_isVirtual(CXCursor C);
extern(C) uint clang_CXXRecord_isAbstract(CXCursor C);
extern(C) uint clang_EnumDecl_isScoped(CXCursor C);
extern(C) uint clang_CXXMethod_isConst(CXCursor C);
extern(C) CXCursorKind clang_getTemplateCursorKind(CXCursor C);
extern(C) CXCursor clang_getSpecializedCursorTemplate(CXCursor C);
extern(C) CXSourceRange clang_getCursorReferenceNameRange(CXCursor C, uint NameFlags, uint PieceIndex);
extern(C) CXToken* clang_getToken(CXTranslationUnitImpl* TU, CXSourceLocation Location);
extern(C) CXTokenKind clang_getTokenKind(CXToken );
extern(C) CXString clang_getTokenSpelling(CXTranslationUnitImpl* , CXToken );
extern(C) CXSourceLocation clang_getTokenLocation(CXTranslationUnitImpl* , CXToken );
extern(C) CXSourceRange clang_getTokenExtent(CXTranslationUnitImpl* , CXToken );
extern(C) void clang_tokenize(CXTranslationUnitImpl* TU, CXSourceRange Range, CXToken** Tokens, uint* NumTokens);
extern(C) void clang_annotateTokens(CXTranslationUnitImpl* TU, CXToken* Tokens, uint NumTokens, CXCursor* Cursors);
extern(C) void clang_disposeTokens(CXTranslationUnitImpl* TU, CXToken* Tokens, uint NumTokens);
extern(C) CXString clang_getCursorKindSpelling(CXCursorKind Kind);
extern(C) void clang_getDefinitionSpellingAndExtent(CXCursor , byte** startBuf, byte** endBuf, uint* startLine, uint* startColumn, uint* endLine, uint* endColumn);
extern(C) void clang_enableStackTraces();
extern(C) void clang_executeOnThread(void* fn, void* user_data, uint stack_size);
extern(C) CXCompletionChunkKind clang_getCompletionChunkKind(void* completion_string, uint chunk_number);
extern(C) CXString clang_getCompletionChunkText(void* completion_string, uint chunk_number);
extern(C) void* clang_getCompletionChunkCompletionString(void* completion_string, uint chunk_number);
extern(C) uint clang_getNumCompletionChunks(void* completion_string);
extern(C) uint clang_getCompletionPriority(void* completion_string);
extern(C) CXAvailabilityKind clang_getCompletionAvailability(void* completion_string);
extern(C) uint clang_getCompletionNumAnnotations(void* completion_string);
extern(C) CXString clang_getCompletionAnnotation(void* completion_string, uint annotation_number);
extern(C) CXString clang_getCompletionParent(void* completion_string, CXCursorKind* kind);
extern(C) CXString clang_getCompletionBriefComment(void* completion_string);
extern(C) void* clang_getCursorCompletionString(CXCursor cursor);
extern(C) uint clang_getCompletionNumFixIts(CXCodeCompleteResults* results, uint completion_index);
extern(C) CXString clang_getCompletionFixIt(CXCodeCompleteResults* results, uint completion_index, uint fixit_index, CXSourceRange* replacement_range);
extern(C) uint clang_defaultCodeCompleteOptions();
extern(C) CXCodeCompleteResults* clang_codeCompleteAt(CXTranslationUnitImpl* TU, byte* complete_filename, uint complete_line, uint complete_column, CXUnsavedFile* unsaved_files, uint num_unsaved_files, uint options);
extern(C) void clang_sortCodeCompletionResults(CXCompletionResult* Results, uint NumResults);
extern(C) void clang_disposeCodeCompleteResults(CXCodeCompleteResults* Results);
extern(C) uint clang_codeCompleteGetNumDiagnostics(CXCodeCompleteResults* Results);
extern(C) void* clang_codeCompleteGetDiagnostic(CXCodeCompleteResults* Results, uint Index);
extern(C) ulong clang_codeCompleteGetContexts(CXCodeCompleteResults* Results);
extern(C) CXCursorKind clang_codeCompleteGetContainerKind(CXCodeCompleteResults* Results, uint* IsIncomplete);
extern(C) CXString clang_codeCompleteGetContainerUSR(CXCodeCompleteResults* Results);
extern(C) CXString clang_codeCompleteGetObjCSelector(CXCodeCompleteResults* Results);
extern(C) CXString clang_getClangVersion();
extern(C) void clang_toggleCrashRecovery(uint isEnabled);
extern(C) void clang_getInclusions(CXTranslationUnitImpl* tu, void* visitor, void* client_data);
extern(C) void* clang_Cursor_Evaluate(CXCursor C);
extern(C) CXEvalResultKind clang_EvalResult_getKind(void* E);
extern(C) int clang_EvalResult_getAsInt(void* E);
extern(C) long clang_EvalResult_getAsLongLong(void* E);
extern(C) uint clang_EvalResult_isUnsignedInt(void* E);
extern(C) ulong clang_EvalResult_getAsUnsigned(void* E);
extern(C) double clang_EvalResult_getAsDouble(void* E);
extern(C) byte* clang_EvalResult_getAsStr(void* E);
extern(C) void clang_EvalResult_dispose(void* E);
extern(C) void* clang_getRemappings(byte* path);
extern(C) void* clang_getRemappingsFromFileList(byte** filePaths, uint numFiles);
extern(C) uint clang_remap_getNumFiles(void* );
extern(C) void clang_remap_getFilenames(void* , uint index, CXString* original, CXString* transformed);
extern(C) void clang_remap_dispose(void* );
extern(C) CXResult clang_findReferencesInFile(CXCursor cursor, void* file, CXCursorAndRangeVisitor visitor);
extern(C) CXResult clang_findIncludesInFile(CXTranslationUnitImpl* TU, void* file, CXCursorAndRangeVisitor visitor);
extern(C) int clang_index_isEntityObjCContainerKind(CXIdxEntityKind );
extern(C) CXIdxObjCContainerDeclInfo* clang_index_getObjCContainerDeclInfo(CXIdxDeclInfo* );
extern(C) CXIdxObjCInterfaceDeclInfo* clang_index_getObjCInterfaceDeclInfo(CXIdxDeclInfo* );
extern(C) CXIdxObjCCategoryDeclInfo* clang_index_getObjCCategoryDeclInfo(CXIdxDeclInfo* );
extern(C) CXIdxObjCProtocolRefListInfo* clang_index_getObjCProtocolRefListInfo(CXIdxDeclInfo* );
extern(C) CXIdxObjCPropertyDeclInfo* clang_index_getObjCPropertyDeclInfo(CXIdxDeclInfo* );
extern(C) CXIdxIBOutletCollectionAttrInfo* clang_index_getIBOutletCollectionAttrInfo(CXIdxAttrInfo* );
extern(C) CXIdxCXXClassDeclInfo* clang_index_getCXXClassDeclInfo(CXIdxDeclInfo* );
extern(C) void* clang_index_getClientContainer(CXIdxContainerInfo* );
extern(C) void clang_index_setClientContainer(CXIdxContainerInfo* , void* );
extern(C) void* clang_index_getClientEntity(CXIdxEntityInfo* );
extern(C) void clang_index_setClientEntity(CXIdxEntityInfo* , void* );
extern(C) void* clang_IndexAction_create(void* CIdx);
extern(C) void clang_IndexAction_dispose(void* );
extern(C) int clang_indexSourceFile(void* , void* client_data, IndexerCallbacks* index_callbacks, uint index_callbacks_size, uint index_options, byte* source_filename, byte** command_line_args, int num_command_line_args, CXUnsavedFile* unsaved_files, uint num_unsaved_files, CXTranslationUnitImpl** out_TU, uint TU_options);
extern(C) int clang_indexSourceFileFullArgv(void* , void* client_data, IndexerCallbacks* index_callbacks, uint index_callbacks_size, uint index_options, byte* source_filename, byte** command_line_args, int num_command_line_args, CXUnsavedFile* unsaved_files, uint num_unsaved_files, CXTranslationUnitImpl** out_TU, uint TU_options);
extern(C) int clang_indexTranslationUnit(void* , void* client_data, IndexerCallbacks* index_callbacks, uint index_callbacks_size, uint index_options, CXTranslationUnitImpl* );
extern(C) void clang_indexLoc_getFileLocation(CXIdxLoc loc, void** indexFile, void** file, uint* line, uint* column, uint* offset);
extern(C) CXSourceLocation clang_indexLoc_getCXSourceLocation(CXIdxLoc loc);
extern(C) uint clang_Type_visitFields(CXType T, void* visitor, void* client_data);
