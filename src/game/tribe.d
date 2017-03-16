module game.tribe;

/* A tribe is a team. It can have multiple masters, when a multiplayer
 * team game is played. Each tribe has a color, number of lixes, etc.
 * In singleplayer, there is one tribe with one master.
 *
 * Tribe doesn't know about masters; if that info is needed, the game must
 * fetch it from the replay.
 */

import enumap;

import basics.globals;
import basics.help;
import game.score;
import net.repdata;
import lix;
import level.level; // spawnintMax

class Tribe {

    private static struct PublicValueFields {
        Style style;

        int  lixInitial;
        int  lixRequired;
        int  lixHatch;
        int  lixSaved;
        int  lixSavedLate; // after the goals have been locked
        int  lixOut;       // change this only when killing/generating lixes.
        int  lixLeaving;   // these have been scored, but keep game running
        int  spawnint;
        bool nuke;
        Ac   nukeSkill;

        Phyu updatePreviousSpawn = Phyu(-Level.spawnintMax); // => at once
        Phyu updatePreviousSave; // ...within the time limit
        int nextHatch; // Initialized by the state initalizer with the permu.
                       // We don't need the permu afterwards for spawns.
        int skillsUsed;
    }

    PublicValueFields valueFields;
    alias valueFields this;

    Enumap!(Ac, int) skills;
    Lixxie[] lixvec;

    this() { }

    this(in Tribe rhs)
    {
        assert (rhs, "don't copy-construct from a null Tribe");
        valueFields = rhs.valueFields;
        skills      = rhs.skills;
        lixvec      = rhs.lixvec .clone;
    }

    Tribe clone() const { return new Tribe(this); }

    @property int stillPlaying() const { return lixOut+lixLeaving+lixHatch; }

    @property Score score() const
    {
        Score ret;
        ret.style = style;
        ret.current = lixSaved;
        ret.potential = lixSaved + lixOut + lixHatch;
        return ret;
    }

    void returnSkills(in Ac ac, in int amount)
    {
        skillsUsed -= amount;
        if (skills[ac] != skillInfinity)
            skills[ac] += amount;
    }
}
