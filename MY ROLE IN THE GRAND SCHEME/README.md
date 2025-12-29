Notes on the organization of this project
=========================================

Scenes
------

**Main_V2.tscn** is the scene where most of the game play takes place: it
contains the play area for cards and links; a reserve for putting cards away; a
menu bar and popup menu; a legend explaining the colors of links and allowing
the player to filter them; an area in the bottom left corner displaying
information about the current card; etc.

**Interaction.tscn** is where all dice-rolling interactions take place. Note
that an instance of Interaction.tscn is also found in Short_Event_Overlay.tscn,
where it is used for break-in and run-away attempts only; for dialogues,
investigations and combats, the standalone scene is used.

**The_Game.tscn** is the top-level scene which brings in one of the other scenes
as required: Main_V2 for gameplay; Interaction for dialogues, investigations and
combats; options, settings, credits, tutorial, etc. There is only one sub-scene
present at any given time, and The_Game.tscn makes nice transitions when the
current scene changes.

**Globals.tscn** contains stuff which is always useful, regardless of the
current scene (Main_V2, Interaction, etc.): the mouse; overlays for making the
image shaky and the text hard to read; sound effects and music; and a sub-scene
containing all the message boxes, dialogs, etc. (see Short_Event_Overlay.tscn
below).

**Short_Event_Overlay.tscn** is used to display messages and warnings, to ask
the player questions, and for relatively simple interactions (break-in and
run-away). It is included in Globals.tscn so that it is always present. Note
that Godot does not itself make any provision for modal dialogs; it is up to us
to block any extraneous UI inputs while a modal dialog is displayed. To that
end, the scene emits *pre_dialog* and *post_dialog* signals, which are handled
by other scenes to pause and resume input handling.

Cards and Links
---------------

Each type of card is represented by a scene: NPC_Card.tscn, Location_Card.tscn,
etc. Each scene defines a class (NpcCard, LocationCard, etc.) which is a
subclass of Card, defined in Card.gd, which provides most of the functionality
for cards.

The class Link is defined in scene Link.tscn (and the script Link.gd). Each link
contains two pins (instances of Pin_Small.tscn) for its endpoints. Each pin is
attached to either a Card or a Link (because a link can connect a card to
another link).

Main_V2.tscn, which is the only scene where links and pins are displayed,
parents all cards, links and pins to the same node: see its `populate()` method.
It is responsible for ordering them in such a way that pins are displayed in
front of the cards and links they are attached to; that the current card is
displayed in front of other cards; and that the current card's links and pins
are displayed in front of other links and pins.

Note that Card and Link instances are owned either by the Player (see Player.gd)
or by the Case (see Case.gd), and *not* by the scene where they are visible at
any given time. NPC, location and object cards, and links between them, are
owned by the Case; dialogue, investigation, combat and abstract cards are owned
by the Player. Both the Player singleton and Case instances are found in
Game_State.gd, which is autoloaded, and so is always present.

Cards, links and pins are all subclasses of Node2D, which means that, unless we
do something about it, they are automatically deleted when the scene where they
are displayed is deleted. To prevent that, Main_V2.tscn and Interaction.tscn are
both responsible for detaching the corresponding nodes before switching scenes:
see the methods `_detach_cards()` in those scenes.

Note also the distinction between *links*, which are visible to the player, and
*connections*, which are not. Connections are determined once and for all, when
the case is generated, and are stored in the relevant cards (so each connection
is actually stored in *two* cards).

Other Scripts
-------------

**Game_State.gd** contains all the gameplay logic, in particular for dialogues,
investigations and combats. It also contains the player (Player.gd) and all the
cases that have been created (Case.gd). It is autoloaded and so is always
present.

**Player.gd** contains all the player's attributes, his mastery and fallback
cards, and lots of other information about the last time he slept, whether he is
confined to bed or jail, etc.

**Case.gd** defines a single case: its NPCs, locations, objects, links between
them, etc. All cases (active and inactive) are contained in Game_State.gd.
