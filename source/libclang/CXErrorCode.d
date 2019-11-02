module libclang.CXErrorCode;
enum CXErrorCode
{
    CXError_Success = 0x0,
    CXError_Failure = 0x1,
    CXError_Crashed = 0x2,
    CXError_InvalidArguments = 0x3,
    CXError_ASTReadError = 0x4,
}
