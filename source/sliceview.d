module sliceview;

struct SliceView(T)
{
    T* ptr;
    ulong size;

    this(T[] src)
    {
        ptr = src.ptr;
        size = src.length;
    }
}

SliceView!T makeView(T)(T[] slice)
{
    return SliceView!T(slice);
}
