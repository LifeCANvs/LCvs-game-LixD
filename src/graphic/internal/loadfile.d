module graphic.internal.loadfile;

import std.algorithm; // find

import basics.alleg5;
import basics.globals;
import file.filename;
import graphic.color;
import graphic.cutbit;
import graphic.internal.getters;
import graphic.internal.vars;
import graphic.internal.recol;

package:

void loadFromDisk(Filename fn)
{
    if (! fn.fileExists || ! fn.hasImageExtension) {
        return;
    }
    Cutbit cb = new Cutbit(fn, Cutbit.Cut.ifGridExists);
    if (!cb || !cb.valid) {
        return;
    }
    al_convert_mask_to_alpha(cb.albit, color.pink);
    internal[fn.rootlessNoExt] = cb;
    assert (fn.rootlessNoExt in internal);
}

bool needGuiRecoloring(Filename fn)
{
    return [fileImageAbility,
            fileImageGuiNumber,
            fileImageEditFlip,
            fileImageEditHatch,
            fileImageEditPanel,
            fileImageGameArrow,
            fileImageGamePanel,
            fileImageGamePanel2,
            fileImageGamePanelHints,
            fileImageGameSpawnint,
            fileImageGamePause,
            fileImageLobbySpec,
            fileImageMenuCheckmark,
            fileImagePreviewIcon
        ].find(fn) != null;
}

void makeLixSprites(in Style st)
{
    assert (spritesheets[st] is null);
    auto src = getLixRawSprites;
    spritesheets[st] = lockThenRecolor!magicnrSpritesheets(src, st);
}

void makePanelInfoIcon(in Style st)
{
    recolorForGuiAndPlayer!magicnrPanelInfoIcons(
        fileImageGameIcon, panelInfoIcons, st);
}

void makeSkillButtonIcon(in Style st)
{
    recolorForGuiAndPlayer!magicnrSkillButtonIcons(
        fileImageSkillIcons, skillButtonIcons, st);
}

private:

void recolorForGuiAndPlayer(int magicnr)(
    in Filename fn,
    ref Cutbit[Style.max] vec,
    in Style st
) {
    assert (vec[st] is null);
    Cutbit sourceCb = getInternalMutable(fn);
    vec[st] = lockThenRecolor!magicnr(sourceCb, st);
}
