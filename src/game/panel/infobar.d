module game.panel.infobar;

import std.string; // format;
import std.typecons; // Rebindable;

import basics.globals; // game panel icons
import net.repdata; // Update
import basics.user; // languageIsEnglish
import file.language;
import game.tribe;
import graphic.color;
import graphic.internal;
import gui;
import hardware.display; // show fps
import hardware.sound; // warn when too few lix alive to win
import lix;

class InfoBar : Button {
private:
    int _targetDescNumber;
    Rebindable!(const(Lixxie)) _targetDescLixxie;
    Rebindable!(const(Tribe))  _tribe;
    bool _showSpawnInterval;
    int _spawnInterval;

    CutbitElement _bOut, _bHatch, _bSaved, _bTime;
    Label         _lOut, _lHatch, _lSaved, _lTime;
    Label _targetDesc, _fps;

    // This is 0 if you have enough lix alive to win.
    // This is >= 0 if you don't have enough lix alive.
    // While it is <= the max number, increase it every frame.
    // If it's > 0 and < max, flicker the exit icon.
    int _warningSignFlicker;

public:
    this(Geom g)
    {
        super(g);
        implConstructor();
    }

    void describeTarget(in Lixxie l, in int nr)
    {
        if (_targetDescLixxie !is l || _targetDescNumber != nr)
            reqDraw();
        _targetDescLixxie = l;
        _targetDescNumber = nr;
    }

    void dontShowSpawnInterval() { _showSpawnInterval = false; }
    void showSpawnInterval(in int si)
    {
        _showSpawnInterval = true;
        _spawnInterval = si;
    }

    void showTribe(in Tribe tribe) {
        with (tribe)
    {
        assert (tribe);
        reqDraw();
        _lHatch.shown = _bHatch.shown = lixHatch > 0;
        _lOut.shown = _bOut.shown = lixHatch + lixOut > 0;
        _lHatch.number = lixHatch;
        _bHatch.yf = 1;
        _lOut.number = lixHatch + lixOut;
        _bOut.yf = lixHatch + lixOut > 0 ? 0 : 1;
        if (basics.user.showFPS.value)
            _fps.text  = "FPS: %d".format(displayFps);
        formatGoal(tribe);
        handleWarningSignFlicker(tribe);
    }}

protected:
    override void calcSelf() { down = false; }
    override void drawOntoButton() { formatTargetDesc(); }

private:
    void formatTargetDesc()
    in {
        assert (  _targetDesc);
        assert (  _targetDescNumber >= 0,
            format("_targetDescNumber == %d, not >= 0", _targetDescNumber));
        assert ( (_targetDescNumber == 0) == (_targetDescLixxie is null),
            format("_targetDescLixxie %s, but _targetDescNumber == %d",
            _targetDescLixxie ? "exists" : "null", _targetDescNumber));
    }
    body { with (_targetDescLixxie) {
        string s = "";
        if (_targetDescLixxie) {
            s = "%d %s%s".format(
                _targetDescNumber,
                ac.acToNiceCase,
                _targetDescNumber > 1 && languageIsEnglish ? "s" : "");
            if (auto bc = cast (const BrickCounter) constJob)
                s ~= " [%d]".format(bc.skillsQueued * bc.bricksAtStart
                                    + bc.bricksLeft);
            if (abilityToRun || abilityToClimb || abilityToFloat)
                s ~= " (%s%s%s)".format(
                    abilityToRun   ? "R" : "",
                    abilityToClimb ? "C" : "",
                    abilityToFloat ? "F" : "");
        }
        else if (_showSpawnInterval)
            s = "%s: %d".format(Lang.winConstantsSpawnint.transl,
                                _spawnInterval);
        _targetDesc.text = s;
    }}

    void implConstructor()
    {
        assert (! _bOut);
        auto makeElements(ref CutbitElement cbe, ref Label lab,
            in int x, in int xl, in int xf
        ) {
            cbe = new CutbitElement(new Geom(x, 0, this.ylg, this.ylg,
                            From.LEFT), getPanelInfoIcon(Style.garden));
            cbe.xf = xf;
            lab = new Label(new Geom(x + this.ylg, 0, xl - this.ylg, this.ylg,
                            From.LEFT));
            // Reason for undraw color: When the displayed values change or
            // when we show/hide these, we reqDraw() on the entire panel
            // anyway. Therefore, color.transp can't leave anything during
            // undraw of cbe and lab. If we don't put color.transp here, then
            // the panel will flicker once with the undraw color after these
            // are hidden. Reason for the flickering: They undraw after
            // the parent (this) is drawn, and they overlay not only a
            // gui-medium-color area, but (this)'s 3D button effect.
            cbe.undrawColor = color.transp;
            lab.undrawColor = color.transp;
            addChildren(cbe, lab);
        }
        makeElements(_bHatch, _lHatch,   4, 56, 4);
        makeElements(_bOut,   _lOut,    60, 60, 3);
        makeElements(_bSaved, _lSaved, 120, 80, 5);
        makeElements(_bTime,  _lTime,  200, 70, 7);
        // I want to show the time in multiplayer. Until I have that,
        // I display the spawn interval in singleplayer.
        _bTime.hide();
        _fps        = new Label(new Geom(280, 0, 70, this.ylg, From.LEFT));
        _targetDesc = new Label(new Geom(
            TextButton.textXFromLeft, 0, this.xlg, this.ylg, From.RIGHT));
        addChildren(_targetDesc, _fps);
    }

    void formatGoal(in Tribe tribe) {
        with (tribe)
    {
        if (lixSaved < lixRequired)
            _lSaved.number = lixRequired - lixSaved;
        else
            _lSaved.text = "%d/%d".format(lixSaved, lixRequired);
    }}

    void handleWarningSignFlicker(in Tribe tribe) {
        with (tribe)
    {
        enum flickerFreq = 0x10; // total duration of one cycle of 2 frames
        enum flickerMax = 4 * flickerFreq + 1;
        if (lixSaved + lixHatch + lixOut >= lixRequired)
            _warningSignFlicker = 0;
        else if (nuke)
            _warningSignFlicker = flickerMax;
        else if (_warningSignFlicker < flickerMax) {
            if (_warningSignFlicker == 0)
                hardware.sound.playLoud(Sound.CANT_WIN);
            ++_warningSignFlicker;
        }
        _bSaved.xf = (_warningSignFlicker + flickerFreq - 1) % flickerFreq
            > flickerFreq/2 ? 5 : 10; // 5 = regular exit, 10 = warning sign
        _bSaved.yf = _bSaved.xf == 10 ? 0 // colorful warning sign
            : lixSaved >= lixRequired ? 2 : 1; // green or grayed-out
    }}
}
