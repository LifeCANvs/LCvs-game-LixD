module graphic.internal.getters;

import std.exception : enforce;

import basics.globals;
import file.filename;
import graphic.cutbit;
import graphic.internal.loadfile;
import graphic.internal.recol;
import graphic.internal.vars;

private enum imgExt = ".png";

package:

Cutbit getLixRawSprites()
out (ret) {
    assert (valid(ret), "can't find Lix spritesheet");
}
body {
    static Cutbit cached = null;
    if (cached)
        return cached;
    auto fn = new VfsFilename(fileImageSpritesheet.rootless ~ imgExt);
    loadFromDisk(fn);
    enforce(fn.rootlessNoExt in internal, "Can't find Lix spritesheet"
        ~ " at `" ~ fn.rootless ~ "'. The spritesheet is required for physics"
        ~ " because the number of sprites per row affect worker cycles."
        ~ " Is your Lix installation broken?");
    cached = *(fn.rootlessNoExt in internal);
    return cached;
}

// Input: filename without any scaling subdir
// Output: The cutbit from the correct scaling subdir, or a replacement image
// See comment near graphic.internal.vars.internal about how we save strings
Cutbit getInternalMutable(in Filename fn)
{
    if (dontWantRecoloredGraphics)
        return nullCutbit;
    auto correctScale  = new VfsFilename(scaleDir ~ fn.file ~ imgExt);
    auto fallbackScale = new VfsFilename(fn.rootless ~ imgExt);
    if (auto ret = correctScale.rootlessNoExt in internal)
        return *ret;
    if (auto ret = fallbackScale.rootlessNoExt in internal)
        return *ret;
    // Neither the correcty-scaled image nor the fallback have already
    // been successfully loaded. Try to load from disk in this order.
    loadFromDisk(correctScale);
    if (auto ret = correctScale.rootlessNoExt in internal) {
        if (fn.needGuiRecoloring)
            eidrecol(*ret, 0);
        return *ret;
    }
    loadFromDisk(fallbackScale);
    if (auto ret = fallbackScale.rootlessNoExt in internal) {
        if (fn.needGuiRecoloring)
            eidrecol(*ret, 0);
        return *ret;
    }
    return nullCutbit;
}

const(Cutbit) implGetLixSprites(in Style st)
out (ret) { assert(ret); }
body {
    if (dontWantRecoloredGraphics)
        return getLixRawSprites();
    if (spritesheets[st] is null)
        makeLixSprites(st);
    return spritesheets[st];
}

const(Cutbit) implGetPanelInfoIcon(in Style st)
out (ret) { assert(ret); }
body {
    if (dontWantRecoloredGraphics)
        return nullCutbit;
    if (panelInfoIcons[st] is null)
        makePanelInfoIcon(st);
    return panelInfoIcons[st];
}

const(Cutbit) implGetSkillButton(in Style st)
out (ret) { assert(ret); }
body {
    if (dontWantRecoloredGraphics)
        return nullCutbit;
    if (skillButtonIcons[st] is null)
        makeSkillButtonIcon(st);
    return skillButtonIcons[st];
}

const(Alcol3D) implGetAlcol3D(in Style style)
body {
    if (! alcol3DforStyles[style].isValid)
        makeAlcol3DforStyle(style);
    return alcol3DforStyles[style];
}

