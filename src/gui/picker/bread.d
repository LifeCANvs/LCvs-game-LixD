module gui.picker.bread;

/* Breadcrumb navigation
 * A series of buttons with one nested subdirectory per button.
 *
 * This doesn't check whether directories exist! Ls would throw when
 * we search a nonexisting dir, but Breadcrumb won't.
 */

import std.algorithm;

import basics.help; // len
import basics.user;
import gui;
import file.filename;

class Breadcrumb : Element {
private:
    Filename _baseDir;
    MutFilename  _currentDir;
    TextButton[] _buttons;
    Label        _label;
    bool         _execute;

package:
    // need package: because Picker's search button shall have same shape
    enum butXl = 100f;

public:
    this(Geom g, Filename aBaseDir)
    in { assert (aBaseDir !is null); }
    body {
        super(g);
        _label = new Label(new Geom(0, 0, butXl, 20, From.LEFT));
        _baseDir = aBaseDir;
        addChild(_label);
    }

    @property bool execute() const { return _execute; }

    @property Filename baseDir() const { return _baseDir; }
    @property Filename currentDir() const { return _currentDir; }
    @property Filename currentDir(Filename fn)
    {
        assert (baseDir, "set basedir before setting current dir");
        MutFilename newCur = (fn && fn.isChildOf(baseDir))
                           ? fn.guaranteedDirOnly() : baseDir;
        if (newCur != _currentDir) {
            _currentDir = newCur;
            makeButtons();
        }
        return _currentDir;
    }

protected:
    override void calcSelf()
    {
        _execute = false;
        foreach (int i, Button b; _buttons)
            if (b.execute) {
                string s = currentDir.dirRootless;
                foreach (unused; 0 .. _buttons.len - i) {
                    // erase one dir from the end of the path
                    assert (s.length == 0 || s[$-1] == '/');
                    s = s[0 .. $-1];
                    while (s.length > 0 && s[$-1] != '/')
                        s = s[0 .. $-1];
                }
                currentDir = new VfsFilename(s);
                _execute = true;
                break;
            }
    }

    override void drawSelf()
    {
        undrawSelf();
        super.drawSelf();
    }

private:
    void makeButtons()
    {
        assert (baseDir, "set basedir before creating buttons");
        reqDraw();
        _buttons.each!(b => rmChild(b));
        _buttons = null;
        float butX() { return _buttons.map!(b => b.xlg).sum; }
        int lastButtonIter = 0;
        int iter = baseDir.dirRootless.len;
        for ( ; iter < currentDir.dirRootless.len; ++iter) {
            string cap = currentDir.dirRootless[lastButtonIter .. iter];
            if (cap.len > 0 && cap[$-1] == '/') {
                _buttons ~= new TextButton(new Geom(butX, 0, butXl, ylg), cap);
                lastButtonIter = iter;
            }
        }
        if (_buttons.len > 0) {
            _buttons[$-1].hotkey = keyMenuUpDir;
            _buttons.each!(b => addChild(b));
        }
        _label.move(butX + 4, 0);
        _label.text = currentDir.dirRootless[lastButtonIter .. iter];
    }
}
