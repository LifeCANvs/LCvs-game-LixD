module game.panel.skillbar;

import optional;

import opt = file.option.allopts;
import game.core.view;
import gui;
import hardware.keyboard;
import hardware.sound;
import physics.tribe;

class SkillBar : Element {
private:
    SkillButton[] _skills;
    Ac _previouslyOn;
    View _view;

public:
    this(Geom g, in View v)
    {
        super(g);
        _view = v;
        _skills.length = opt.skillSort.length;
        immutable float skillXl = xlg / opt.skillSort.length;
        foreach (int id, ac; opt.skillSort) {
            _skills[id] = new SkillButton(new Geom(id * skillXl, 0,
                skillXl, ylg, From.LEFT));
            _skills[id].skill = ac;
            _skills[id].hotkey = opt.keySkill[opt.skillSort[id]].value;
            addChild(_skills[id]);
        }
    }

    void setLikeTribe(in Tribe tr, in Ac ploderToDisplay)
    {
        foreach (b; _skills) {
            b.style = tr.style;
            if (b.skill.isPloder) {
                b.skill = ploderToDisplay;
            }
            b.number = tr.hasNuked && ! _view.showSkillsInPanelAfterNuking
                ? 0 : tr.usesLeft(b.skill);
        }
        choose(_previouslyOn);
    }

    void setAllSkillsToZero() nothrow @safe
    {
        foreach (b; _skills) {
            b.number = 0; // This also sets skill buttons to off.
        }
    }

    inout(SkillButton) currentSkillOrNull() inout pure nothrow @safe @nogc
    {
        foreach (b; _skills)
            if (b.on && b.skill != Ac.nothing && b.number != 0)
                return b;
        return null;
    }

    void chooseLeftmostSkill() nothrow @safe
    {
        foreach (b; _skills) {
            if (b.number == 0) {
                continue;
            }
            choose(b.skill);
            return;
        }
    }

    Ac hoveredSkill() const nothrow @safe @nogc
    {
        foreach (b; _skills) {
            if (b.isMouseHere) {
                return b.skill;
            }
        }
        return Ac.nothing;
    }

protected:
    override void calcSelf()
    {
        if (! _view.canAssignSkills) {
            return;
        }
        foreach (candidate; _skills) {
            if (candidate.on || ! candidate.execute) {
                continue;
            }
            if (candidate.available) {
                choose(candidate.skill);
                hardware.sound.playLoud(Sound.PANEL);
            }
            else if (candidate.hotkey.wasTapped) {
                choose(Ac.nothing); // Avoid misassignmets to other skills.
                hardware.sound.playQuiet(Sound.PANEL_EMPTY);
            }
        }
    }

private:
    /*
     * Soft-choose the skill, maybe because we've rewound and now have it
     * available again.
     */
    void choose(in Ac wanted) nothrow @safe
    {
        _previouslyOn = wanted;
        foreach (b; _skills) {
            b.on = b.skill == wanted && b.available && _view.canAssignSkills;
        }
    }
}
