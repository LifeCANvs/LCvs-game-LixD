module editor.io;

import std.algorithm;
import std.conv;
import std.string;

import basics.globals;
import basics.globconf;
import basics.user; // hotkeys for the popup dialogs
import editor.dragger;
import editor.editor;
import editor.gui.panel;
import editor.paninit;
import file.filename;
import file.date;
import file.language;
import graphic.map;
import gui;
import hardware.keyset;
import hardware.sound;
import level.level;
import menu.browser.saveas;
import tile.gadtile;

package:

void implConstructor(Editor editor) { with (editor)
{
    _level = new Level(_loadedFrom);
    _levelToCompareForDataLoss = new Level(_loadedFrom);

    Map newMap() { with (_level) return new Map(topology,
        Geom.screenXls.to!int, (Geom.screenYls - Geom.panelYls).to!int); }
    _map        = newMap();
    _mapTerrain = newMap();
    _map.centerOnAverage(
        _level.gadgets[GadType.HATCH].map!(h => h.screenCenter.x),
        _level.gadgets[GadType.HATCH].map!(h => h.screenCenter.y));
    _dragger = new MouseDragger();
    editor.makePanel();
}}

void implDestructor(Editor editor)
{
    if (editor._panel)
        rmElder(editor._panel);
}

void newLevel(Editor editor) {
    with (editor)
{
    editor.askForDataLossThenExecute(delegate void() {
        _hover = null;
        _selection = null;
        _loadedFrom = null;
        _panel.currentFilename = null;

        _level        = new Level;
        _level.author = basics.globconf.userName;
        _levelToCompareForDataLoss        = new Level;
        _levelToCompareForDataLoss.author = userName;
    });
}}

void saveToExistingFile(Editor editor) {
    with (editor)
{
    if (editor._loadedFrom) {
        basics.user.singleLastLevel = editor._loadedFrom;
        if (_level != _levelToCompareForDataLoss)
            _level.built = Date.now();
        _level.saveToFile(_loadedFrom);
        _levelToCompareForDataLoss = new Level(_loadedFrom);
        playLoud(Sound.DISKSAVE);
    }
    else
        editor.openSaveAsBrowser();
}}

void openSaveAsBrowser(Editor editor) {
    with (editor)
{
    assert (mainUIisActive);
    _saveBrowser = new SaveBrowser(dirLevels);
    _saveBrowser.highlight(_loadedFrom ? _loadedFrom : singleLastLevel);
    addFocus(_saveBrowser);
}}

void askForDataLossThenExecute(
    Editor editor,
    void delegate() unlessCancelledExecuteThis
) {
    with (editor)
{
    assert (mainUIisActive);
    assert (_level !is _levelToCompareForDataLoss);
    if     (_level  == _levelToCompareForDataLoss) {
        unlessCancelledExecuteThis();
    }
    else {
        MsgBox box = new MsgBox(Lang.saveBoxTitleSave.transl);
        if (_loadedFrom) {
            box.addMsg(Lang.saveBoxQuestionUnsavedChangedLevel.transl);
            box.addMsg("%s %s".format(Lang.saveBoxFileName.transl,
                                      _loadedFrom.rootless));
        }
        else {
            box.addMsg(Lang.saveBoxQuestionUnsavedNewLevel.transl);
        }
        if (_level.name != null)
            box.addMsg("%s %s".format(Lang.saveBoxLevelName.transl,
                                      _level.name));
        box.addButton(Lang.saveBoxYesSave.transl, keyMenuOkay, () {
            _askForDataLoss = null;
            editor.saveToExistingFile();
            unlessCancelledExecuteThis();
        });
        box.addButton(Lang.saveBoxNoDiscard.transl, keyMenuDelete, () {
            _askForDataLoss = null;
            unlessCancelledExecuteThis();
        });
        box.addButton(Lang.saveBoxNoCancel.transl,
                      KeySet(keyMenuExit, keyEditorExit), () {
            _askForDataLoss = null;
        });
        addFocus(box);
        _askForDataLoss = box;
    }
}}
