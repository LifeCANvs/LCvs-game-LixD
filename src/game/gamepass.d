module game.gamepass;

/* This was gamepl_c.cpp in old Lix.
 * These calculations are performed even while a replay is running
 */

import basics.alleg5;
import game;
import hardware.keyboard;
import hardware.mousecur;

package void
impl_calc_passive(Game game) { with (game)
{
    if (key_once(ALLEGRO_KEY_ESCAPE))
        game._goto_menu = true;

    mouse.xf = 0;
    mouse.yf = 0;

    map.calc_scrolling();
    if (map.scrolling_now)
        mouse.xf = 3;
}}
// end with (game), end function impl_calc_passive
