module gui.numpick;

/* A GUI element to pick a number using plus/minus buttons at the sides.
 * To instantiate: Make a struct NumPickConfig first, set values that differ
 * from the defaults there, then pass the struct to the class constructor.
 */

import std.algorithm; // clamp, any
import std.range; // retro
import std.math;

import basics.help;
import basics.globals; // filename of button sticker
import gui;
import graphic.color;
import graphic.cutbit;
import graphic.internal;

struct NumPickConfig {
    int  digits     = 2;
    bool sixButtons = false;
    int  min        =   0;
    int  max        =  99;
    int  stepSmall  =   1;
    int  stepMedium =  10;
    int  stepBig    = 100;
    bool allowWrap  = true; // Allow wrapping between minimum and maximum
    bool whiteZero  = false;
    bool time       = false; // the colon counts towards the digits needed
    bool hex        = false;
    bool signAlways = false; // always show + or - if value != 0
    char minusOneChar = 0;   // if non-null, show all this instead of -1
}

class NumPick : Element {
private:
    enum int fixedCharXSpacing = 10;

    int _value;
    int _previousValue; // Only to compute execute().
    bool _execute;
    NumPickConfig cfg;
    BitmapButton[] but;
    Label[] lab; // one per digit

public:
    this(Geom g,
        in NumPickConfig newCfg = NumPickConfig(),
        in int initial = 0
    ) {
        g.yl = 20;
        super(g);
        cfg = newCfg;
        _value = clamp(initial, cfg.min, cfg.max);
        _previousValue = _value;
        implConstructor();
    }

    int number() const pure nothrow @safe @nogc { return _value; }
    int number(in int i)
    {
        _value = clamp(i, cfg.min, cfg.max);
        _previousValue = _value;
        formatVal();
        return i;
    }

    bool execute() const pure nothrow @safe @nogc { return _execute; }

protected:
    override void calcSelf()
    {
        _execute = _value != _previousValue;
        _previousValue = _value;
    }

    override void drawSelf() { undraw(); super.drawSelf(); }

private:

private void
implConstructor()
{
    int bbGeomCount = 0;
    BitmapButton bbGeom(in int x, From from, in int change)
    {
        auto b = new BitmapButton(
            new Geom(x - 20 * (! cfg.sixButtons), 0, 20, 20, from),
            InternalImage.guiNumber.toCutbit);
        b.xf = bbGeomCount;
        b.onExecute = () { this.buttonCallback(change); };

        addChild(b);
        if (! cfg.sixButtons && (bbGeomCount == 0 || bbGeomCount == 5))
            b.hide();
        ++bbGeomCount;
        return b;
    }
    but = [
        bbGeom( 0, From.TOP_LEFT, -cfg.stepBig),
        bbGeom(20, From.TOP_LEFT, -cfg.stepMedium),
        bbGeom(40, From.TOP_LEFT, -cfg.stepSmall),
        bbGeom(40, From.TOP_RIGHT, cfg.stepSmall),
        bbGeom(20, From.TOP_RIGHT, cfg.stepMedium),
        bbGeom( 0, From.TOP_RIGHT, cfg.stepBig),
    ];
    assert (cfg.digits >= 0);
    foreach (i; 0 .. cfg.digits) {
        int x = (-cfg.digits + 2*i + 1) * NumPick.fixedCharXSpacing/2;
        if (i == 0 && cfg.hex)
            // looks better with the small "0x" printed here
            x -= 1;
        lab ~= new Label(new Geom(x, 0, 20, 20, From.TOP));
        addChild(lab[$-1]);
        assert (lab[$-1].aligned == From.CENTER);
    }
    formatVal();
}

private void
buttonCallback(in int change)
{
    _value
        = (cfg.allowWrap && change > 0 && _value == cfg.max) ? cfg.min
        : (cfg.allowWrap && change < 0 && _value == cfg.min) ? cfg.max
        : clamp(_value + change, cfg.min, cfg.max);
    formatVal();
}

private void formatVal()
{
    reqDraw();
    if (_value == -1 && cfg.minusOneChar != 0)
        foreach (la; lab) {
            la.text  = [cfg.minusOneChar];
            la.color = color.guiTextOn;
        }
    else if (cfg.hex)  formatValHex();
    else if (cfg.time) formatValTime();
    else               formatValDecimal();
}

private void formatValDecimal()
{
    if (_value == 0 && lab.len > 0) {
        lab[$-1].text = "0";
        lab[$-1].color = cfg.whiteZero ? color.guiTextOn : color.guiText;
        foreach (la; lab[0 .. $-1])
            la.text = "";
    }
    else {
        int remainder = _value.abs;
        int pos = lab.len - 1;
        while (pos >= 0 && remainder != 0) {
            lab[pos].text  = [remainder % 10 + '0'];
            lab[pos].color = color.guiTextOn;
            remainder /= 10;
            --pos;
        }
        if (pos >= 0 && (cfg.signAlways || _value < 0)) {
            lab[pos].text  = _value < 0 ? "\u2212" : "+"; // unicode minus
            lab[pos].color = _value < 0 ? color.guiTextOn : color.guiText;
            --pos;
        }
        while (pos >= 0)
            lab[pos--].text = "";
    }
}

private void
formatValHex()
{
    // hex digit NumPickers are always drawn with leading zeroes,
    // and they can't display negative values. (No error, value is handled
    // correctly, only displayed without the minus sign.)
    if (cfg.digits > 0) {
        lab[0].text  = "\u2080\u2093"; // subscript of 0x
        lab[0].color = color.guiText;
    }
    int remainder = _value.abs;
    for (int i = lab.len - 1; i >= 1; --i) {
        lab[i].text  = ["0123456789ABCDEF"[remainder % 16]];
        lab[i].color = remainder != 0 ? color.guiTextOn : color.guiText;
        remainder /= 16;
    }
    if (cfg.whiteZero && lab.len > 0)
        lab[$-1].color = color.guiTextOn;
}

private void formatValTime()
{
    // Treat val as seconds, format as mm:ss.
    // Time always prints leading zeroes.
    int remainder = _value.abs;
    for (int pos = lab.len - 1; pos >= 0; --pos) {
        lab[pos].color = remainder > 0 ? color.guiTextOn : color.guiText;
        if (pos == lab.len - 1) {
            if (cfg.whiteZero)
                lab[pos].color = color.guiTextOn;
            lab[pos].text  = [remainder % 10 + '0'];
            remainder /= 10;
        }
        else if (pos == lab.len - 2) {
            lab[pos].text = [remainder % 6 + '0'];
            remainder /= 6;
        }
        else if (pos == lab.len - 3) {
            lab[pos].text  = ":";
        }
        else {
            // minute digits
            lab[pos].text = [remainder % 10 + '0'];
            remainder /= 10;
        }
    }
}

}
// end class
