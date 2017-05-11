module graphic.color;

import std.random;

public import basics.alleg5 : Alcol;

import basics.alleg5;
import basics.user;

public ColorPrivate color;

// bar graph 3D colors for a Lix style, or GUI button outlines
public struct Alcol3D {
    Alcol l, m, d;
    static assert (is (typeof(l.r) == float));
    bool isValid() const { return l.r == l.r; /* i.e., it's not NaN */ }
}

void initialize()
{
    computeColors(basics.user.guiColorRed,
                  basics.user.guiColorGreen,
                  basics.user.guiColorBlue);
}

void deinitialize() { destroy(color); color = null; }

void computeColors(in int r, in int g, in int b)
{
    if (color)
        destroy(color);
    color = new ColorPrivate(r, g, b);
}

private class ColorPrivate {

    @property Alcol random()
    {
        alias rnd = uniform01!float;
        float[] arr = [rnd(), 0.7 + 0.3 * rnd(), 0.3 * rnd()];
        arr.randomShuffle();
        return Alcol(arr[0], arr[1], arr[2], 1);
    }

    Alcol makecol(int r, int g, int b)
    {
        return Alcol(r / 255f, g / 255f, b / 255f, 1);
    }

    Alcol
        bad,
        transp,
        pink,

        cbBadFrame,
        cbBadBitmap,

        white,
        red,
        black,

        lixFileEye, // for detection of where exploder fuses are positioned

        guiFileSha, // how it looks in an image file, these get
        guiFileD,   // recolored to guiD, guiOnD, ..., accordingly.
        guiFileM,
        guiFileL,

        screenBorder,
        triggerArea,
        torusSeamD,
        torusSeamL,

        guiSha,
        guiD,
        guiM,
        guiL,
        guiDownD,
        guiDownM,
        guiDownL,
        guiOnD,
        guiOnM,
        guiOnL,

        guiText,
        guiTextOn,

        guiPicOnD,
        guiPicOnM,
        guiPicOnL,
        guiPicD,
        guiPicM,
        guiPicL;

private:
    int _guiColorRed, _guiColorGreen, _guiColorBlue;

    this(in int _r, in int _g, in int _b)
    {
        _guiColorRed   = _r;
        _guiColorGreen = _g;
        _guiColorBlue  = _b;

        //                    red   green blue  alpha
        bad           = Alcol(0.00, 0.00, 0.00, 0.5);
        transp        = Alcol(0.00, 0.00, 0.00, 0  );
        pink          = Alcol(1,    0,    1,    1  );

        cbBadFrame  = Alcol(0.8,  0.8,  0.8,  1  );
        cbBadBitmap = Alcol(1,    0.5,  0.5,  1  );

        lixFileEye   = makecol(0x50, 0x50, 0x50);

        white         = Alcol(1,    1,    1,    1  );
        red           = Alcol(1,    0,    0,    1  );
        black         = Alcol(0,    0,    0,    1  );

        // how it looks in an image file
        guiFileSha = makecol(0x40, 0x40, 0x40);
        guiFileD   = makecol(0x80, 0x80, 0x80);
        guiFileM   = makecol(0xC0, 0xC0, 0xC0);
        guiFileL   = makecol(0xFF, 0xFF, 0xFF);

        screenBorder = make_sepia(2f / 16f);
        triggerArea  = makecol(0x60, 0xFF, 0xFF);
        torusSeamD   = make_sepia(0.25f);
        torusSeamL   = make_sepia(0.4f);

        guiSha    = make_sepia(3f / 16f);
        guiD      = make_sepia(7.75f / 16f / 1.2f);
        guiM      = make_sepia(7.75f / 16f);
        guiL      = make_sepia(7.75f / 16f * 1.2f);
        guiDownD  = make_sepia(8.75f / 16f / 1.1f);
        guiDownM  = make_sepia(8.75f / 16f);
        guiDownL  = make_sepia(8.75f / 16f * 1.1f);
        guiOnD    = make_sepia(11f   / 16f / 1.1f);
        guiOnM    = make_sepia(11f   / 16f);
        guiOnL    = make_sepia(11f   / 16f * 1.1f);

        guiText   = make_sepia(14f   / 16f); // lighter than an image
        guiTextOn = make_sepia(1.0);         // pure white

        guiPicD   = make_sepia(11f   / 16f / 1.2f);
        guiPicM   = make_sepia(11f   / 16f);
        guiPicL   = make_sepia(11f   / 16f * 1.2f);
        guiPicOnD = make_sepia(14f   / 16f / 1.2f);
        guiPicOnM = make_sepia(14f   / 16f);
        guiPicOnL = make_sepia(1.0);
    }

    // light: max is 1.0, min is 0.0
    Alcol make_sepia(in float light)
    {
        if      (light <= 0.0) return Alcol(0, 0, 0, 1);
        else if (light >= 1.0) return Alcol(1, 1, 1, 1);

        // the user file suggests a base color via integers in 0 .. 255+1
        alias r = _guiColorRed;
        alias g = _guiColorGreen;
        alias b = _guiColorBlue;
        r = (r > 0xFF ? 0xFF : r < 0 ? 0 : r);
        g = (g > 0xFF ? 0xFF : g < 0 ? 0 : g);
        b = (b > 0xFF ? 0xFF : b < 0 ? 0 : b);
        if      (light == 0.5) return Alcol(r / 255f, g / 255f, b / 255f, 1);
        else if (light <  0.5) return Alcol(r * 2 * light / 255f,
                                            g * 2 * light / 255f,
                                            b * 2 * light / 255f, 1);
        else return Alcol((r + (255 - r) * 2 * (light - 0.5)) / 255f,
                          (g + (255 - g) * 2 * (light - 0.5)) / 255f,
                          (b + (255 - b) * 2 * (light - 0.5)) / 255f, 1);
    }

}
