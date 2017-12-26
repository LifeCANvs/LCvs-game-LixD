module graphic.internal.vars;

/*
 *  All global state of package graphic.internal goes in here.
 */

import basics.globals;
import basics.matrix;
import graphic.cutbit;
public import graphic.color;
public import net.style;

package:

bool wantRecoloredGraphics;

Cutbit _lixRawSprites;
Cutbit[string]    internal;
Cutbit[Style.max] spritesheets;
Cutbit[Style.max] panelInfoIcons;
Cutbit[Style.max] skillButtonIcons;

Cutbit nullCutbit; // invalid bitmap to return instead of null pointer

Alcol3D[Style.max] alcol3DforStyles;

Matrix!Point eyesOnSpritesheet;

immutable int magicnrSpritesheets = 1;
immutable int magicnrPanelInfoIcons = 2;
immutable int magicnrSkillButtonIcons = 3;

string scaleDir() // From which dir should we load?
{
    return _scaleDir != "" ? _scaleDir : dirDataBitmap.rootless;
}

void implSetScale(in float scale)
{
    _scaleDir =
        scale < 1.5f ? dirDataBitmap.rootless
     :  scale < 2.0f ? dirDataBitmapScale ~ "150/"
     :  scale < 3.0f ? dirDataBitmapScale ~ "200/"
     :                 dirDataBitmapScale ~ "300/";
}

private string _scaleDir = "";
