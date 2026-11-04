class_name SettingsPanel
extends PanelContainer
## Settings: fullscreen, master volume, autosave (user://settings.cfg) and a button to the
## controls page (KeybindPanel, user://keybinds.cfg).

signal closed
signal controls_requested


func _ready() -> void:
	var sb := UI.panel_style(UI.NEON_BG, UI.NEON_PINK)
	sb.set_border_width_all(2)
	sb.set_content_margin_all(18)
	add_theme_stylebox_override("panel", sb)
	custom_minimum_size = Vector2(520, 0)
	var v := UI.vbox(14)
	add_child(v)
	var head := UI.hbox(10)
	v.add_child(head)
	head.add_child(UI.label("SETTINGS", 22, UI.NEON_PINK))
	head.add_child(UI.spacer())
	head.add_child(UI.button("Back", func(): closed.emit()))

	var fs := CheckButton.new()
	fs.text = "Fullscreen"
	fs.button_pressed = bool(SaveGame.settings["fullscreen"])
	fs.toggled.connect(func(on): _change("fullscreen", on))
	v.add_child(fs)

	var au := CheckButton.new()
	au.text = "Autosave when docking and arriving in a system"
	au.button_pressed = bool(SaveGame.settings["autosave"])
	au.toggled.connect(func(on): _change("autosave", on))
	v.add_child(au)

	var vol_row := UI.hbox(12)
	v.add_child(vol_row)
	vol_row.add_child(UI.label("Master volume", 14))
	var vol := HSlider.new()
	vol.min_value = 0.0
	vol.max_value = 1.0
	vol.step = 0.05
	vol.value = float(SaveGame.settings["volume"])
	vol.custom_minimum_size = Vector2(240, 0)
	vol.value_changed.connect(func(x): _change("volume", x))
	vol_row.add_child(vol)
	v.add_child(UI.label("(No sound in the game yet – the setting is ready for it.)", 12, UI.TEXT_DIM))
	v.add_child(UI.menu_button("Controls …", func(): controls_requested.emit(), UI.NEON_CYAN, 480))


func _change(key: String, value) -> void:
	SaveGame.settings[key] = value
	SaveGame.save_settings()
