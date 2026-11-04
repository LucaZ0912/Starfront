class_name SaveBrowser
extends PanelContainer
## List of save games. mode "load": Load / Delete per slot.
## mode "save": overwrite a slot or create a new one with a name.

signal closed
signal slot_chosen(slot: String)    # load mode: the player picked a save

var mode := "load"
var list: VBoxContainer
var name_edit: LineEdit
var status: Label
var _confirm_delete := ""


func _init(p_mode: String = "load") -> void:
	mode = p_mode


func _ready() -> void:
	var sb := UI.panel_style(UI.NEON_BG, UI.NEON_CYAN)
	sb.set_border_width_all(2)
	sb.set_content_margin_all(18)
	add_theme_stylebox_override("panel", sb)
	custom_minimum_size = Vector2(720, 520)
	var v := UI.vbox(10)
	add_child(v)
	var head := UI.hbox(10)
	v.add_child(head)
	head.add_child(UI.label("SAVE GAME" if mode == "save" else "LOAD GAME", 22, UI.NEON_CYAN))
	head.add_child(UI.spacer())
	head.add_child(UI.button("Back", func(): closed.emit()))
	if mode == "save":
		var row := UI.hbox(8)
		v.add_child(row)
		name_edit = LineEdit.new()
		name_edit.placeholder_text = "Name for a new save …"
		name_edit.text = "%s %s" % [GameState.pilot_name, Time.get_date_string_from_system()]
		name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_edit)
		row.add_child(UI.button("Save as new", _save_new))
	status = UI.label("", 13, UI.GOOD)
	v.add_child(status)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	list = UI.vbox(6)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	refresh()


func refresh() -> void:
	UI.clear(list)
	var saves := SaveGame.list_saves()
	if saves.is_empty():
		list.add_child(UI.label("No saves yet.", 14, UI.TEXT_DIM))
	for s in saves:
		var slot: String = s["slot"]
		var m: Dictionary = s["meta"]
		var box := UI.neon_panel(Color(UI.NEON_CYAN, 0.35), Color(0.04, 0.05, 0.1, 0.9), 1)
		list.add_child(box)
		var row := UI.hbox(12)
		box.add_child(row)
		var info := UI.vbox(1)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		info.add_child(UI.label(String(m["label"]), 16, UI.NEON_CYAN))
		if s.get("old", false):
			info.add_child(UI.label("Older alpha – cannot be loaded any more (module rework of package 19)", 12, UI.BAD))
		info.add_child(UI.label("%s  •  %s  •  %s" % [m["pilot"], GameData.fmt_credits(int(m["credits"])), m["ship"]], 13))
		info.add_child(UI.label("%s  •  played %s  •  saved %s" % [m["location"], SaveGame.fmt_time(float(m["play_time"])), String(m["saved_at"]).replace("T", " ").substr(0, 16)], 12, UI.TEXT_DIM))
		if mode == "load":
			row.add_child(UI.button("Load", func(): slot_chosen.emit(slot)))
		else:
			var label: String = m["label"]
			row.add_child(UI.button("Overwrite", func(): _save(slot, label)))
		var del := UI.button("Confirm delete" if _confirm_delete == slot else "Delete", func(): _delete(slot))
		row.add_child(del)


func _save(slot: String, label: String) -> void:
	var err := SaveGame.save_game(slot, label)
	_status(err if err != "" else "Saved: %s" % label, err == "")
	refresh()


func _save_new() -> void:
	var label := name_edit.text.strip_edges()
	if label == "":
		_status("Please enter a name.", false)
		return
	var slot := SaveGame.slot_name(label)
	var n := 2
	var base := slot
	while FileAccess.file_exists(SaveGame.slot_path(slot)):
		slot = "%s_%d" % [base, n]
		n += 1
	_save(slot, label)


func _delete(slot: String) -> void:
	if _confirm_delete != slot:
		_confirm_delete = slot
		refresh()
		return
	_confirm_delete = ""
	SaveGame.delete_save(slot)
	_status("Deleted.", true)
	refresh()


func _status(text: String, ok: bool) -> void:
	status.text = text
	status.add_theme_color_override("font_color", UI.GOOD if ok else UI.BAD)
