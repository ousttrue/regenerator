import std.traits;

template rawtype(T)
{
    static if (isPointer!T)
    {
        rawtype!(PointerTarget!T) rawtype;
    }
    else
    {
        T rawtype;
    }
}

ulong get_hash(T)()
{
    auto ti = typeid(T);
    auto hash = ti.toHash();
    // logf("%s => %d", ti.name, hash);
    return hash;
}
