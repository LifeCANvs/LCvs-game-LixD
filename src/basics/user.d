module basics.user;

/* User settings read from the user config file. This file differs from the
 * global config file, see globconf.d. Whenever the user file doesn't exist,
 * the default values from static this() are used.
 */

import std.typecons; // rebindable
import std.algorithm; // sort filenames before outputting them
import std.conv;
import std.stdio;

import basics.alleg5;
import basics.globals;
import basics.globconf;
import file.filename;
import file.date;
import file.io;
import file.log; // when writing to disk fails
import lix.enums;

/*  static this();
 *  void load();
 *  void save();
 *  const(Result) get_level_result          (Filename);
 *  void          set_level_result_carefully(Filename, Result, in int);
 */

private Result[Rebindable!(const Filename)] results;

Filename file_language;
int      option_group = 0;

bool scroll_edge        = true;
bool scroll_right       = true;
bool scroll_middle      = true;
bool replay_cancel      = true;
int  replay_cancel_at   = 30;
int  mouse_speed        = 20;
int  mouse_acceleration = 0;
int  scroll_speed_edge  = 5;
int  scroll_speed_click = 6;
bool multiple_builders  = true;
bool batter_priority    = true;
bool prioinv_middle     = true;
bool prioinv_right      = true;

int  sound_volume       = 10;

bool screen_windowed    = false;
bool arrows_replay      = true;
bool arrows_network     = true;
bool gameplay_help      = true;
int  debris_amount      = 2;
int  debris_type        = 1;

int  gui_color_red      = 0x70;
int  gui_color_green    = 0x80;
int  gui_color_blue     = 0xA0;

bool editor_hex_level_size = false;
int  editor_grid_selected  = 1;
int  editor_grid_custom    = 8;

Filename single_last_level;
Filename network_last_level;
Filename replay_last_level;

Style    network_last_style = Style.RED;

Filename editor_last_dir_terrain;
Filename editor_last_dir_steel;
Filename editor_last_dir_hatch;
Filename editor_last_dir_goal;
Filename editor_last_dir_deco;
Filename editor_last_dir_hazard;

int key_force_left      = ALLEGRO_KEY_S;
int key_force_right     = ALLEGRO_KEY_F;
int key_scroll          = ALLEGRO_KEY_PAD_MINUS;
int key_priority        = ALLEGRO_KEY_PAD_MINUS;
int key_rate_minus      = ALLEGRO_KEY_1;
int key_rate_plus       = ALLEGRO_KEY_2;
int key_pause           = ALLEGRO_KEY_SPACE;
int key_speed_slow      = ALLEGRO_KEY_3;
int key_speed_fast      = ALLEGRO_KEY_4;
int key_speed_turbo     = ALLEGRO_KEY_5;
int key_restart         = ALLEGRO_KEY_F1;
int key_state_load      = ALLEGRO_KEY_F2;
int key_state_save      = ALLEGRO_KEY_F5;
int key_zoom            = ALLEGRO_KEY_Y;
int key_nuke            = ALLEGRO_KEY_F12;
int key_spec_tribe      = ALLEGRO_KEY_TAB;
int key_chat            = ALLEGRO_KEY_ENTER;
int key_ga_exit         = ALLEGRO_KEY_ESCAPE;

int key_me_okay         = ALLEGRO_KEY_SPACE;
int key_me_edit         = ALLEGRO_KEY_F;
int key_me_export       = ALLEGRO_KEY_R;
int key_me_delete       = ALLEGRO_KEY_G;
int key_me_up_dir       = ALLEGRO_KEY_A;
int key_me_up_1         = ALLEGRO_KEY_S;
int key_me_up_5         = ALLEGRO_KEY_W;
int key_me_down_1       = ALLEGRO_KEY_D;
int key_me_down_5       = ALLEGRO_KEY_E;
int key_me_exit         = ALLEGRO_KEY_ESCAPE;
int key_me_main_single  = ALLEGRO_KEY_F;
int key_me_main_network = ALLEGRO_KEY_D;
int key_me_main_replay  = ALLEGRO_KEY_S;
int key_me_main_options = ALLEGRO_KEY_A;

int key_ed_left         = ALLEGRO_KEY_S;
int key_ed_right        = ALLEGRO_KEY_F;
int key_ed_up           = ALLEGRO_KEY_E;
int key_ed_down         = ALLEGRO_KEY_D;
int key_ed_copy         = ALLEGRO_KEY_A;
int key_ed_delete       = ALLEGRO_KEY_G;
int key_ed_grid         = ALLEGRO_KEY_C;
int key_ed_sel_all      = ALLEGRO_KEY_ALT;
int key_ed_sel_frame    = ALLEGRO_KEY_LSHIFT;
int key_ed_sel_add      = ALLEGRO_KEY_V;
int key_ed_background   = ALLEGRO_KEY_T;
int key_ed_foreground   = ALLEGRO_KEY_B;
int key_ed_mirror       = ALLEGRO_KEY_W;
int key_ed_rotate       = ALLEGRO_KEY_R;
int key_ed_dark         = ALLEGRO_KEY_N;
int key_ed_noow         = ALLEGRO_KEY_M;
int key_ed_zoom         = ALLEGRO_KEY_Y;
int key_ed_help         = ALLEGRO_KEY_H;
int key_ed_menu_size    = ALLEGRO_KEY_5;
int key_ed_menu_vars    = ALLEGRO_KEY_Q;
int key_ed_menu_skills  = ALLEGRO_KEY_X;
int key_ed_add_terrain  = ALLEGRO_KEY_SPACE;
int key_ed_add_steel    = ALLEGRO_KEY_TAB;
int key_ed_add_hatch    = ALLEGRO_KEY_1;
int key_ed_add_goal     = ALLEGRO_KEY_2;
int key_ed_add_deco     = ALLEGRO_KEY_3;
int key_ed_add_hazard   = ALLEGRO_KEY_4;
int key_ed_exit         = ALLEGRO_KEY_ESCAPE;

int[Ac.MAX] key_skill;

static this()
{
    file_language            = new Filename(file_language_english);

    key_skill[Ac.WALKER]     = ALLEGRO_KEY_D;
    key_skill[Ac.RUNNER]     = ALLEGRO_KEY_LSHIFT;
    key_skill[Ac.BASHER]     = ALLEGRO_KEY_E;
    key_skill[Ac.BUILDER]    = ALLEGRO_KEY_A;
    key_skill[Ac.PLATFORMER] = ALLEGRO_KEY_T;
    key_skill[Ac.DIGGER]     = ALLEGRO_KEY_W;
    key_skill[Ac.MINER]      = ALLEGRO_KEY_G;
    key_skill[Ac.BLOCKER]    = ALLEGRO_KEY_X;
    key_skill[Ac.CUBER]      = ALLEGRO_KEY_X;
    key_skill[Ac.EXPLODER]   = ALLEGRO_KEY_V;
    key_skill[Ac.EXPLODER2]  = ALLEGRO_KEY_V;

    key_skill[Ac.CLIMBER]    = ALLEGRO_KEY_B;
    key_skill[Ac.FLOATER]    = ALLEGRO_KEY_Q;
    key_skill[Ac.JUMPER]     = ALLEGRO_KEY_R;
    key_skill[Ac.BATTER]     = ALLEGRO_KEY_C;

    single_last_level  = new Filename(dir_levels_single);
    network_last_level = new Filename(dir_levels_network);
    replay_last_level  = new Filename(dir_replays);

    editor_last_dir_terrain = new Filename(dir_bitmap);
    editor_last_dir_steel   = new Filename(dir_bitmap);
    editor_last_dir_hatch   = new Filename(dir_bitmap);
    editor_last_dir_goal    = new Filename(dir_bitmap);
    editor_last_dir_deco    = new Filename(dir_bitmap);
    editor_last_dir_hazard  = new Filename(dir_bitmap);
}



// ############################################################################
// ############################################################## struct Result
// ############################################################################



class Result {
    Date built;
    int  lix_saved;
    int  skills_used;
    int  updates_used;

    this ()
    {
        built = Date.now();
        // all other fields are initialized to zero
    }

    this (Date bu, in int sa, in int sk, in int up)
    {
        built = bu; lix_saved = sa; skills_used = sk; updates_used = up;
    }

    int opEquals(in Result rhs) const
    {
        return built        == rhs.built
         &&    lix_saved    == rhs.lix_saved
         &&    skills_used  == rhs.skills_used
         &&    updates_used == rhs.updates_used;
    }

    // A newly built level's result is always better than older results,
    // when compared with this. However, the user wouldn't want to replace
    // an old solving result with a new-built-using non-solving result.
    // To check in results into the database of solved levels, use
    // set_level_result_carefully() from this module.
    int opCmp(in Result r) const
    {
        return built    != r.built        ? built        < r.built
         : lix_saved    != r.lix_saved    ? lix_saved    < r.lix_saved
         : skills_used  != r.skills_used  ? skills_used  > r.skills_used
         : updates_used != r.updates_used ? updates_used > r.updates_used
         : 0; // all are equal
    }

}
// end class Result



const(Result) get_level_result(in Filename fn)
{
    Result* ret = (rebindable!(const Filename)(fn) in results);
    return ret ? (*ret) : null;
}



void set_level_result_carefully(
    in Filename _fn,
    Result r,
    in int required
) {
    auto fn = rebindable!(const Filename)(_fn);
    auto saved_result = (fn in results);

    if (saved_result is null) {
        results[fn] = r;
    }
    else if (saved_result.built == r.built) {
        // carefully means: if the level build times are the same, use the
        // better result of these two
        if (*saved_result < r) results[fn] = r;
    }
    else {
        // carefully also means: when the bulid times differ, a non-solving
        // result of a new version is worse than a solving result of the old
        // version. Otherwise, the new version is always preferred.
        // required should be supplied by Gameplay, it's the required count
        // for the new Result r
        if (saved_result.lix_saved >= required && r.lix_saved < required) {
            // do nothing, keep the old result
        }
        else results[fn] = r;
    }
}



// ############################################################################
// ############################################### saving/loading the user file
// ############################################################################




private Filename user_file_name()
{
    return new Filename(dir_data_user.dir_rootful
     ~ basics.help.user_name_escape_for_filename(user_name)
     ~ ext_config);
}


void load()
{
    if (user_name == null) {
        // This happens upon first start after installation
        return;
    }

    while (basics.globconf.user_name.length > player_name_max_length) {
        user_name = basics.help.backspace(user_name);
    }

    IoLine[] lines;
    try
        lines = fill_vector_from_file(user_file_name());
    catch (Exception e) {
        Log.log(e.msg);
        Log.log("User config for user `" ~ user_name ~ "' was not found.");
    }

    results = null;

    foreach (i; lines) switch (i.type) {

    case '$':
        if      (i.text1 == user_language               ) file_language      = new Filename(i.text2);

        else if (i.text1 == user_single_last_level      ) single_last_level  = new Filename(i.text2);
        else if (i.text1 == user_network_last_level     ) network_last_level = new Filename(i.text2);
        else if (i.text1 == user_replay_last_level      ) replay_last_level  = new Filename(i.text2);

        else if (i.text1 == user_editor_last_dir_terrain) editor_last_dir_terrain = new Filename(i.text2);
        else if (i.text1 == user_editor_last_dir_steel  ) editor_last_dir_steel   = new Filename(i.text2);
        else if (i.text1 == user_editor_last_dir_hatch  ) editor_last_dir_hatch   = new Filename(i.text2);
        else if (i.text1 == user_editor_last_dir_goal   ) editor_last_dir_goal    = new Filename(i.text2);
        else if (i.text1 == user_editor_last_dir_deco   ) editor_last_dir_deco    = new Filename(i.text2);
        else if (i.text1 == user_editor_last_dir_hazard ) editor_last_dir_hazard  = new Filename(i.text2);
        break;

    case '#':
        if      (i.text1 == user_option_group           ) option_group           = i.nr1;

        else if (i.text1 == user_mouse_speed            ) mouse_speed            = i.nr1;
        else if (i.text1 == user_mouse_acceleration     ) mouse_acceleration     = i.nr1;
        else if (i.text1 == user_scroll_speed_edge      ) scroll_speed_edge      = i.nr1;
        else if (i.text1 == user_scroll_speed_click     ) scroll_speed_click     = i.nr1;
        else if (i.text1 == user_scroll_edge            ) scroll_edge            = i.nr1 > 0;
        else if (i.text1 == user_scroll_right           ) scroll_right           = i.nr1 > 0;
        else if (i.text1 == user_scroll_middle          ) scroll_middle          = i.nr1 > 0;
        else if (i.text1 == user_replay_cancel          ) replay_cancel          = i.nr1 > 0;
        else if (i.text1 == user_replay_cancel_at       ) replay_cancel_at       = i.nr1;
        else if (i.text1 == user_multiple_builders      ) multiple_builders      = i.nr1 > 0;
        else if (i.text1 == user_batter_priority        ) batter_priority        = i.nr1 > 0;
        else if (i.text1 == user_prioinv_middle         ) prioinv_middle         = i.nr1 > 0;
        else if (i.text1 == user_prioinv_right          ) prioinv_right          = i.nr1 > 0;

        else if (i.text1 == user_screen_windowed        ) screen_windowed        = i.nr1 > 0;
        else if (i.text1 == user_arrows_replay          ) arrows_replay          = i.nr1 > 0;
        else if (i.text1 == user_arrows_network         ) arrows_network         = i.nr1 > 0;
        else if (i.text1 == user_gameplay_help          ) gameplay_help          = i.nr1 > 0;
        else if (i.text1 == user_debris_amount          ) debris_amount          = i.nr1;
        else if (i.text1 == user_debris_type            ) debris_type            = i.nr1;
        else if (i.text1 == user_gui_color_red          ) gui_color_red          = i.nr1;
        else if (i.text1 == user_gui_color_green        ) gui_color_green        = i.nr1;
        else if (i.text1 == user_gui_color_blue         ) gui_color_blue         = i.nr1;

        else if (i.text1 == user_sound_volume           ) sound_volume           = i.nr1;

        else if (i.text1 == user_editor_hex_level_size  ) editor_hex_level_size  = i.nr1 > 0;
        else if (i.text1 == user_editor_grid_selected   ) editor_grid_selected   = i.nr1;
        else if (i.text1 == user_editor_grid_custom     ) editor_grid_custom     = i.nr1;

        else if (i.text1 == user_network_last_style) {
            try network_last_style = to!Style(i.nr1);
            catch (ConvException e) network_last_style = Style.RED;
            if (network_last_style < Style.RED) network_last_style = Style.RED;
        }

        else if (i.text1 == user_key_force_left         ) key_force_left         = i.nr1;
        else if (i.text1 == user_key_force_right        ) key_force_right        = i.nr1;
        else if (i.text1 == user_key_scroll             ) key_scroll             = i.nr1;
        else if (i.text1 == user_key_priority           ) key_priority           = i.nr1;
        else if (i.text1 == user_key_rate_minus         ) key_rate_minus         = i.nr1;
        else if (i.text1 == user_key_rate_plus          ) key_rate_plus          = i.nr1;
        else if (i.text1 == user_key_pause              ) key_pause              = i.nr1;
        else if (i.text1 == user_key_speed_slow         ) key_speed_slow         = i.nr1;
        else if (i.text1 == user_key_speed_fast         ) key_speed_fast         = i.nr1;
        else if (i.text1 == user_key_speed_turbo        ) key_speed_turbo        = i.nr1;
        else if (i.text1 == user_key_restart            ) key_restart            = i.nr1;
        else if (i.text1 == user_key_state_load         ) key_state_load         = i.nr1;
        else if (i.text1 == user_key_state_save         ) key_state_save         = i.nr1;
        else if (i.text1 == user_key_zoom               ) key_zoom               = i.nr1;
        else if (i.text1 == user_key_nuke               ) key_nuke               = i.nr1;
        else if (i.text1 == user_key_spec_tribe         ) key_spec_tribe         = i.nr1;
        else if (i.text1 == user_key_chat               ) key_chat               = i.nr1;
        else if (i.text1 == user_key_ga_exit            ) key_ga_exit            = i.nr1;

        else if (i.text1 == user_key_me_okay            ) key_me_okay            = i.nr1;
        else if (i.text1 == user_key_me_edit            ) key_me_edit            = i.nr1;
        else if (i.text1 == user_key_me_export          ) key_me_export          = i.nr1;
        else if (i.text1 == user_key_me_delete          ) key_me_delete          = i.nr1;
        else if (i.text1 == user_key_me_up_dir          ) key_me_up_dir          = i.nr1;
        else if (i.text1 == user_key_me_up_1            ) key_me_up_1            = i.nr1;
        else if (i.text1 == user_key_me_up_5            ) key_me_up_5            = i.nr1;
        else if (i.text1 == user_key_me_down_1          ) key_me_down_1          = i.nr1;
        else if (i.text1 == user_key_me_down_5          ) key_me_down_5          = i.nr1;
        else if (i.text1 == user_key_me_exit            ) key_me_exit            = i.nr1;
        else if (i.text1 == user_key_me_main_single     ) key_me_main_single     = i.nr1;
        else if (i.text1 == user_key_me_main_network    ) key_me_main_network    = i.nr1;
        else if (i.text1 == user_key_me_main_replay     ) key_me_main_replay     = i.nr1;
        else if (i.text1 == user_key_me_main_options    ) key_me_main_options    = i.nr1;

        else if (i.text1 == user_key_ed_left            ) key_ed_left            = i.nr1;
        else if (i.text1 == user_key_ed_right           ) key_ed_right           = i.nr1;
        else if (i.text1 == user_key_ed_up              ) key_ed_up              = i.nr1;
        else if (i.text1 == user_key_ed_down            ) key_ed_down            = i.nr1;
        else if (i.text1 == user_key_ed_copy            ) key_ed_copy            = i.nr1;
        else if (i.text1 == user_key_ed_delete          ) key_ed_delete          = i.nr1;
        else if (i.text1 == user_key_ed_grid            ) key_ed_grid            = i.nr1;
        else if (i.text1 == user_key_ed_sel_all         ) key_ed_sel_all         = i.nr1;
        else if (i.text1 == user_key_ed_sel_frame       ) key_ed_sel_frame       = i.nr1;
        else if (i.text1 == user_key_ed_sel_add         ) key_ed_sel_add         = i.nr1;
        else if (i.text1 == user_key_ed_background      ) key_ed_background      = i.nr1;
        else if (i.text1 == user_key_ed_foreground      ) key_ed_foreground      = i.nr1;
        else if (i.text1 == user_key_ed_mirror          ) key_ed_mirror          = i.nr1;
        else if (i.text1 == user_key_ed_rotate          ) key_ed_rotate          = i.nr1;
        else if (i.text1 == user_key_ed_dark            ) key_ed_dark            = i.nr1;
        else if (i.text1 == user_key_ed_noow            ) key_ed_noow            = i.nr1;
        else if (i.text1 == user_key_ed_zoom            ) key_ed_zoom            = i.nr1;
        else if (i.text1 == user_key_ed_help            ) key_ed_help            = i.nr1;
        else if (i.text1 == user_key_ed_menu_size       ) key_ed_menu_size       = i.nr1;
        else if (i.text1 == user_key_ed_menu_vars       ) key_ed_menu_vars       = i.nr1;
        else if (i.text1 == user_key_ed_menu_skills     ) key_ed_menu_skills     = i.nr1;
        else if (i.text1 == user_key_ed_add_terrain     ) key_ed_add_terrain     = i.nr1;
        else if (i.text1 == user_key_ed_add_steel       ) key_ed_add_steel       = i.nr1;
        else if (i.text1 == user_key_ed_add_hatch       ) key_ed_add_hatch       = i.nr1;
        else if (i.text1 == user_key_ed_add_goal        ) key_ed_add_goal        = i.nr1;
        else if (i.text1 == user_key_ed_add_deco        ) key_ed_add_deco        = i.nr1;
        else if (i.text1 == user_key_ed_add_hazard      ) key_ed_add_hazard      = i.nr1;
        else if (i.text1 == user_key_ed_exit            ) key_ed_exit            = i.nr1;

        else {
            Ac ac = string_to_ac(i.text1);
            if (ac != Ac.MAX) key_skill[ac] = i.nr1;
        }
        break;

    case '<': {
        auto fn = rebindable!(const Filename)(new Filename(i.text1));
        Result result_read = new Result(new Date(i.text2), i.nr1,i.nr2,i.nr3);
        Result* result_in_database = (fn in results);
        if (! result_in_database || *result_in_database < result_read) {
            results[fn] = result_read;
        }
        break; }

    default:
        break;

    }
}



nothrow void save()
{
    if (user_name is null) {
        // may happen under very strange circumstances, but generally
        // shouldn't happen. We have to warn the user when he enters an
        // empty name in the options.
        return;
    }
    try {
        std.stdio.File f = File(user_file_name().rootful, "w");

        void fwr(in IoLine line)
        {
            f.writeln(line);
            f.flush();
        }

        fwr(IoLine.Dollar(user_language, file_language.rootless));
        fwr(IoLine.Hash  (user_option_group, option_group));
        f.writeln();

        fwr(IoLine.Hash  (user_mouse_speed,             mouse_speed));
        fwr(IoLine.Hash  (user_mouse_acceleration,      mouse_acceleration));
        fwr(IoLine.Hash  (user_scroll_speed_edge,       scroll_speed_edge));
        fwr(IoLine.Hash  (user_scroll_speed_click,      scroll_speed_click));
        fwr(IoLine.Hash  (user_scroll_edge,             scroll_edge));
        fwr(IoLine.Hash  (user_scroll_right,            scroll_right));
        fwr(IoLine.Hash  (user_scroll_middle,           scroll_middle));
        fwr(IoLine.Hash  (user_replay_cancel,           replay_cancel));
        fwr(IoLine.Hash  (user_replay_cancel_at,        replay_cancel_at));
        fwr(IoLine.Hash  (user_multiple_builders,       multiple_builders));
        fwr(IoLine.Hash  (user_batter_priority,         batter_priority));
        fwr(IoLine.Hash  (user_prioinv_middle,          prioinv_middle));
        fwr(IoLine.Hash  (user_prioinv_right,           prioinv_right));
        f.writeln();

        fwr(IoLine.Hash  (user_screen_windowed,         screen_windowed));
        fwr(IoLine.Hash  (user_arrows_replay,           arrows_replay));
        fwr(IoLine.Hash  (user_arrows_network,          arrows_network));
        fwr(IoLine.Hash  (user_gameplay_help,           gameplay_help));
        fwr(IoLine.Hash  (user_debris_amount,           debris_amount));
        fwr(IoLine.Hash  (user_debris_type,             debris_type));
        fwr(IoLine.Hash  (user_gui_color_red,           gui_color_red));
        fwr(IoLine.Hash  (user_gui_color_green,         gui_color_green));
        fwr(IoLine.Hash  (user_gui_color_blue,          gui_color_blue));
        f.writeln();

        fwr(IoLine.Hash  (user_sound_volume,            sound_volume));
        f.writeln();

        fwr(IoLine.Hash  (user_editor_hex_level_size,   editor_hex_level_size));
        fwr(IoLine.Hash  (user_editor_grid_selected,    editor_grid_selected));
        fwr(IoLine.Hash  (user_editor_grid_custom,      editor_grid_custom));
        f.writeln();

        fwr(IoLine.Dollar(user_single_last_level,       single_last_level.rootless));
        fwr(IoLine.Dollar(user_network_last_level,      network_last_level.rootless));
        fwr(IoLine.Dollar(user_replay_last_level,       replay_last_level.rootless));
        fwr(IoLine.Hash  (user_network_last_style,      network_last_style));
        f.writeln();

        fwr(IoLine.Dollar(user_editor_last_dir_terrain, editor_last_dir_terrain.rootless));
        fwr(IoLine.Dollar(user_editor_last_dir_steel,   editor_last_dir_steel.rootless));
        fwr(IoLine.Dollar(user_editor_last_dir_hatch,   editor_last_dir_hatch.rootless));
        fwr(IoLine.Dollar(user_editor_last_dir_goal,    editor_last_dir_goal.rootless));
        fwr(IoLine.Dollar(user_editor_last_dir_deco,    editor_last_dir_deco.rootless));
        fwr(IoLine.Dollar(user_editor_last_dir_hazard,  editor_last_dir_hazard.rootless));
        f.writeln();

        fwr(IoLine.Hash  (user_key_force_left,  key_force_left));
        fwr(IoLine.Hash  (user_key_force_right, key_force_right));
        fwr(IoLine.Hash  (user_key_scroll,      key_scroll));
        fwr(IoLine.Hash  (user_key_priority,    key_priority));
        fwr(IoLine.Hash  (user_key_rate_minus,  key_rate_minus));
        fwr(IoLine.Hash  (user_key_rate_plus,   key_rate_plus));
        fwr(IoLine.Hash  (user_key_pause,       key_pause));
        fwr(IoLine.Hash  (user_key_speed_slow,  key_speed_slow));
        fwr(IoLine.Hash  (user_key_speed_fast,  key_speed_fast));
        fwr(IoLine.Hash  (user_key_speed_turbo, key_speed_turbo));
        fwr(IoLine.Hash  (user_key_restart,     key_restart));
        fwr(IoLine.Hash  (user_key_state_load,  key_state_load));
        fwr(IoLine.Hash  (user_key_state_save,  key_state_save));
        fwr(IoLine.Hash  (user_key_zoom,        key_zoom));
        fwr(IoLine.Hash  (user_key_nuke,        key_nuke));
        fwr(IoLine.Hash  (user_key_spec_tribe,  key_spec_tribe));
        fwr(IoLine.Hash  (user_key_chat,        key_chat));
        fwr(IoLine.Hash  (user_key_ga_exit,     key_ga_exit));

        foreach (int i, mapped_key; key_skill) {
            if (mapped_key != 0) {
                try {
                    Ac ac = to!Ac(i);
                    fwr(IoLine.Hash(ac_to_string(ac), mapped_key));
                }
                catch (ConvException) { }
            }
        }
        f.writeln();

        fwr(IoLine.Hash  (user_key_me_okay,          key_me_okay));
        fwr(IoLine.Hash  (user_key_me_edit,          key_me_edit));
        fwr(IoLine.Hash  (user_key_me_export,        key_me_export));
        fwr(IoLine.Hash  (user_key_me_delete,        key_me_delete));
        fwr(IoLine.Hash  (user_key_me_up_dir,        key_me_up_dir));
        fwr(IoLine.Hash  (user_key_me_up_1,          key_me_up_1));
        fwr(IoLine.Hash  (user_key_me_up_5,          key_me_up_5));
        fwr(IoLine.Hash  (user_key_me_down_1,        key_me_down_1));
        fwr(IoLine.Hash  (user_key_me_down_5,        key_me_down_5));
        fwr(IoLine.Hash  (user_key_me_exit,          key_me_exit));
        fwr(IoLine.Hash  (user_key_me_main_single,   key_me_main_single));
        fwr(IoLine.Hash  (user_key_me_main_network,  key_me_main_network));
        fwr(IoLine.Hash  (user_key_me_main_replay,   key_me_main_replay));
        fwr(IoLine.Hash  (user_key_me_main_options,  key_me_main_options));
        f.writeln();

        fwr(IoLine.Hash  (user_key_ed_left,        key_ed_left));
        fwr(IoLine.Hash  (user_key_ed_right,       key_ed_right));
        fwr(IoLine.Hash  (user_key_ed_up,          key_ed_up));
        fwr(IoLine.Hash  (user_key_ed_down,        key_ed_down));
        fwr(IoLine.Hash  (user_key_ed_copy,        key_ed_copy));
        fwr(IoLine.Hash  (user_key_ed_delete,      key_ed_delete));
        fwr(IoLine.Hash  (user_key_ed_grid,        key_ed_grid));
        fwr(IoLine.Hash  (user_key_ed_sel_all,     key_ed_sel_all));
        fwr(IoLine.Hash  (user_key_ed_sel_frame,   key_ed_sel_frame));
        fwr(IoLine.Hash  (user_key_ed_sel_add,     key_ed_sel_add));
        fwr(IoLine.Hash  (user_key_ed_background,  key_ed_background));
        fwr(IoLine.Hash  (user_key_ed_foreground,  key_ed_foreground));
        fwr(IoLine.Hash  (user_key_ed_mirror,      key_ed_mirror));
        fwr(IoLine.Hash  (user_key_ed_rotate,      key_ed_rotate));
        fwr(IoLine.Hash  (user_key_ed_dark,        key_ed_dark));
        fwr(IoLine.Hash  (user_key_ed_noow,        key_ed_noow));
        fwr(IoLine.Hash  (user_key_ed_zoom,        key_ed_zoom));
        fwr(IoLine.Hash  (user_key_ed_help,        key_ed_help));
        fwr(IoLine.Hash  (user_key_ed_menu_size,   key_ed_menu_size));
        fwr(IoLine.Hash  (user_key_ed_menu_vars,   key_ed_menu_vars));
        fwr(IoLine.Hash  (user_key_ed_menu_skills, key_ed_menu_skills));
        fwr(IoLine.Hash  (user_key_ed_add_terrain, key_ed_add_terrain));
        fwr(IoLine.Hash  (user_key_ed_add_steel,   key_ed_add_steel));
        fwr(IoLine.Hash  (user_key_ed_add_hatch,   key_ed_add_hatch));
        fwr(IoLine.Hash  (user_key_ed_add_goal,    key_ed_add_goal));
        fwr(IoLine.Hash  (user_key_ed_add_deco,    key_ed_add_deco));
        fwr(IoLine.Hash  (user_key_ed_add_hazard,  key_ed_add_hazard));
        fwr(IoLine.Hash  (user_key_ed_exit,        key_ed_exit));

        // output all results, sorting the hash-based associative array first
        bool wrote_newline = false;
        auto sorted_keys = results.keys.sort();
        foreach (fn; sorted_keys) {
            if (! wrote_newline) {
                f.writeln();
                wrote_newline = true;
                // The sane implementation of this newline before the first
                // element, of course, is to check for array emptiness before
                // the loop. However, this drove up release compile time from
                // 9 seconds to 40 seconds! Compiler bug in dmd v2.065?
                // It's still 23 seconds with dmd v2.067.
            }
            Result r = results[fn];
            fwr(IoLine.Angle(fn.rootless,
             r.lix_saved, r.skills_used, r.updates_used, r.built.toString()));
        }

        f.close();

    }
    catch (Exception e) {
        Log.log(e.msg);
        return;
    }
}
