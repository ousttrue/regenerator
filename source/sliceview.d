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

struct KeyValue(K, V)
{
    K key;
    V value;
}

SliceView!(KeyValue!(K, V)) makeView(K, V)(V[K] aa)
{
    alias kv = KeyValue!(K, V);
    kv[] array;
    foreach (k, v; aa)
    {
        array ~= kv(k, v);
    }
    return SliceView!kv(array);
}
