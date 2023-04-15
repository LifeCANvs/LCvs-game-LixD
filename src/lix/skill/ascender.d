module lix.skill.ascender;

import std.algorithm;

import lix;

class Ascender : Job {
    override bool blockable() const { return false; }

    override void onBecome(in Job old)
    {
        bool solidPixelWithAirAbove(in int y)
        {
            return lixxie.isSolid(0, y) && ! lixxie.isSolid(0, y-1);
        }
        int swh = 0;
        enum checkBelowHeight = 26; // must be rather high like this,
                                    // for (climber -> this)
        while (swh < checkBelowHeight && ! solidPixelWithAirAbove(2 - swh))
            ++swh;

        // Prevent moving up a giant amount if there is no wall at all
        // in front of the lix, which led to a bug reported by Nepster in
        // 2014-06. This assumes that all pixels are empty. It might create
        // a further bug when all pixels are solid, but I don't think
        // become_ascender is ever called when that is the case.
        if (swh == checkBelowHeight) {
            lixxie.become(Ac.faller);
            return;
        }
        // Available frames are 0, 1, 2, 3, 4, 5.
        // If swh is >= 0 and < 4, use frame 5. Late frames == low height.
        frame = std.algorithm.clamp(6 - (swh / 2), 0, 5);
        immutable int swhLeftToAscendDuringPerform = 10 - frame * 2;
        assert (swh >= swhLeftToAscendDuringPerform);
        lixxie.moveUp(swh - swhLeftToAscendDuringPerform);
    }

    override void perform()
    {
        if (frame != 5) {
            lixxie.moveUp(2);
        }
        if (lixxie.isLastFrame) {
            lixxie.become(Ac.walker);
        }
        else {
            lixxie.advanceFrame();
        }
    }
}
