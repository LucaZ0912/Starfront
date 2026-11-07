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

	# package 28a: one volume slider per channel
	for spec in [["Master volume", "volume"], ["Music", "vol_music"], ["Atmosphere", "vol_ambience"], ["Effects", "vol_sfx"]]:
		var key: String = spec[1]
		var vol_row := UI.hbox(12)
		v.add_child(vol_row)
		var vl := UI.label(spec[0], 14)
		vl.custom_minimum_size = Vector2(140, 0)
		vol_row.add_child(vl)
		var vol := HSlider.new()
		vol.min_value = 0.0
		vol.max_value = 1.0
		vol.step = 0.05
		vol.value = float(SaveGame.settings[key])
		vol.custom_minimum_size = Vector2(240, 0)
		vol.value_changed.connect(func(x): _change(key, x))
		vol_row.add_child(vol)
		var pct := UI.label("%d %%" % int(round(vol.value * 100.0)), 13, UI.TEXT_DIM)
		vol.value_changed.connect(func(x): pct.text = "%d %%" % int(round(x * 100.0)))
		vol_row.add_child(pct)
	v.add_child(UI.label("Interface sounds follow the effects volume.", 12, UI.TEXT_DIM))
	v.add_child(UI.menu_button("Controls …", func(): controls_requested.emit(), UI.NEON_CYAN, 480))


func _change(key: String, value) -> void:
	SaveGame.settings[key] = value
	SaveGame.save_settings()
