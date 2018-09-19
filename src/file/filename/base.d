module file.filename.base;

import std.algorithm;
import std.typecons;
import std.file : SpanMode, isDir;
public import std.string : toStringz; // for stringForReading/Writing

package interface IFilename {
public:
immutable:
    @property string rootless()       nothrow pure;
    @property string extension()      nothrow pure;
    @property string file()           nothrow pure;
    @property string rootlessNoExt()  nothrow pure;
    @property string fileNoExtNoPre() nothrow pure;
    @property string dirRootless()    nothrow pure;
    @property string dirInnermost()   nothrow pure;
    @property char   preExtension()   nothrow pure;

    Filename guaranteedDirOnly() nothrow;

    // These can throw on file 404
    std.stdio.File openForReading(in string mode = "r");
    std.stdio.File openForWriting(in string mode = "w");
    const(void)[] readIntoVoidArray();

    // Silently return null if file not found
    string stringForReading() nothrow;
    string stringForWriting();

    // dirExists(a/b/) checks if b exists.
    // dirExists(a/b/c) checks if b exists, no matter whether file c is inside.
    bool fileExists() nothrow;
    bool dirExists() nothrow;

    // These throw on error.
    void mkdirRecurse();
    void deleteFile();

    final bool isChildOf(Filename parent) nothrow
    {
        return parent.file.length == 0 // parent names a directory
            && parent.rootless.length <= rootless.length
            && parent.rootless == rootless[0 .. parent.rootless.length];
    }

    final bool hasImageExtension() nothrow
    {
        return imageExtensions.find(extension) != null;
    }

    // Search files in a directory, with or without recursion through subdirs.
    // Whenever what == "", every possible file is retrieved because
    // hasCorrectEnding("") will always be true; see that function for details.
    final MutFilename[] findFiles(in string what = "") immutable
    {
        return findImpl(SpanMode.shallow, false, what);
    }

    final MutFilename[] findDirs() immutable
    {
        return findImpl(SpanMode.shallow, true, "");
    }

    final MutFilename[] findTree(in string what = "") immutable
    {
        return findImpl(SpanMode.breadth, false, what);
    }

protected:
    MutFilename[] findImpl(in SpanMode, in bool wantDirs, in string) immutable;
}

alias Filename = immutable(IFilename);
alias MutFilename = Rebindable!Filename;

bool fnLessThan(Filename lhs, Filename rhs)
{
    // I roll my own here instead of using string's opCmp. Reason:
    // I use the convention throughout the program that file-less directory
    // names end with '/'. The directory "abc-def/" is therefore smaller
    // than "abc/", since '-' < '/' in ASCII, but we want lexicographical
    // sorting in the program's directory listings.
    // Thus, this function here makes '/' smaller than anything.
    if (lhs is null && rhs is null) return false;
    else if (lhs is null)           return true;
    else if (rhs is null)           return false;
    foreach (i; 0 .. min(lhs.rootless.length, rhs.rootless.length)) {
        immutable a = lhs.rootless[i];
        immutable b = rhs.rootless[i];
        if (a != b)
            return a == '/' ? true
                :  b == '/' ? false : a < b;
    }
    // If we get here, one string is an initial segment of the other.
    return lhs.rootless.length < rhs.rootless.length;
}

static immutable imageExtensions = [ ".png", ".bmp", ".tga", ".pcx",
                                     ".PNG", ".BMP", ".TGA", ".PCX" ];

package pure bool hasEnding(in string fn, in string ending)
{
    return fn.length >= ending.length
     &&    fn[($ - ending.length) .. $] == ending;
}
