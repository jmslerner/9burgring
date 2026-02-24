	#AppNavigation (Godot 4.5 addon)
	#Copyright (C) 2026  Minotaurs at Work
#
	#This program is free software: you can redistribute it and/or modify
	#it under the terms of the GNU Affero General Public License as published by
	#the Free Software Foundation, either version 3 of the License, or
	#(at your option) any later version.
#
	#This program is distributed in the hope that it will be useful,
	#but WITHOUT ANY WARRANTY; without even the implied warranty of
	#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	#GNU General Public License for more details.
#
	#You should have received a copy of the GNU General Public License
	#along with this program.  If not, see <https://www.gnu.org/licenses/>.

@tool
extends Control

var _grid: GridContainer
var _key_edits: Array[LineEdit] = []
var _value_edits: Array[_AnadDroppableButton] = []
var _values: Array[String] = []
var _save_buttons: Array[Button] = []
var _add_new_route_button: Button

func _on_new_row () -> void:
	_grid.remove_child(_add_new_route_button)
	var controls := _create_grid_row("","")
	_values.push_back("")
	for c in controls:
		_grid.add_child(c)
	var item_idx: int = len(_key_edits)
	_key_edits.push_back(controls.get(1))
	_key_edits.back().text_changed.connect(_on_key_changed.bind(item_idx))
	_value_edits.push_back(controls.get(3))
	_value_edits.back().pressed.connect(_on_file_button_pressed.bind(item_idx))
	_value_edits.back().file_dropped.connect(_on_page_uploaded.bind(item_idx,null))
	_save_buttons.push_back(controls.get(4))
	_save_buttons.back().disabled = true
	_save_buttons.back().pressed.connect(_on_row_saved.bind(item_idx))
	_grid.add_child(_add_new_route_button)

func _on_row_saved (route_idx: int) -> void:
	var e: Error = AppNavigationServer.register_route(_key_edits.get(route_idx).text,_values.get(route_idx))
	if e == Error.OK:
		_save_buttons.get(route_idx).disabled = true

func _on_key_changed (new_key: String, route_idx: int) -> void:
	_save_buttons.get(route_idx).disabled = (_values.get(route_idx) == null)

func _on_page_uploaded (path: String, route_idx: int, dialog: FileDialog) -> void:
	if dialog != null:
		dialog.hide()
		dialog.queue_free()
	_values[route_idx] = path
	var path_sections := path.split("/")
	_value_edits.get(route_idx).text = path_sections.get(len(path_sections) - 1)
	_save_buttons.get(route_idx).disabled = (len(_key_edits.get(route_idx).text) == 0)

func _on_file_button_pressed (route_idx: int) -> void:
	var f_dialog: FileDialog = FileDialog.new()
	f_dialog.access = FileDialog.ACCESS_RESOURCES
	f_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	f_dialog.add_filter("*.gd, *.tscn")
	f_dialog.title = "Load App Page"
	f_dialog.file_selected.connect(_on_page_uploaded.bind(route_idx,f_dialog))
	f_dialog.show()
	print("Upload file dialog should be open now. If this isn't the case, try dragging the file ('.gd' or '.tscn') onto the button instead.")

func _create_grid_row (key: String, value: String) -> Array[Control]:
	var key_label := Label.new()
	key_label.text = "Page ID:"
	var key_field := LineEdit.new()
	key_field.text = key
	var value_label := Label.new()
	value_label.text = "Page Scene/Script:"
	var value_field := _AnadDroppableButton.new()
	value_field.icon = EditorInterface.get_base_control().get_theme_icon("Load","EditorIcons")
	if value != "":
		var path_sections := value.split("/")
		value_field.text = path_sections.get(len(path_sections) - 1)
	else:
		value_field.text = "Add AppPage"
	var save_button := Button.new()
	save_button.icon = EditorInterface.get_base_control().get_theme_icon("Save","EditorIcons")
	return [key_label,key_field,value_label,value_field,save_button]

func _ready () -> void:
	var scrollie := ScrollContainer.new()
	scrollie.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scrollie)
	_grid = GridContainer.new()
	_grid.columns = 5
	_grid.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrollie.add_child(_grid)
	await get_tree().process_frame
	for item_idx in range(len(AppNavigationServer._registered_routes)):
		var key := AppNavigationServer._registered_routes.keys().get(item_idx)
		var value := AppNavigationServer._registered_routes.get(key)
		_values.push_back(value)
		var controls := _create_grid_row(key,value)
		for c in controls:
			_grid.add_child(c)
		_key_edits.push_back(controls.get(1))
		_key_edits.back().text_changed.connect(_on_key_changed.bind(item_idx))
		_value_edits.push_back(controls.get(3))
		_value_edits.back().pressed.connect(_on_file_button_pressed.bind(item_idx))
		_value_edits.back().file_dropped.connect(_on_page_uploaded.bind(item_idx,null))
		_save_buttons.push_back(controls.get(4))
		_save_buttons.back().pressed.connect(_on_row_saved.bind(item_idx))
	_add_new_route_button = Button.new()
	_add_new_route_button.text = "Add Route"
	_add_new_route_button.icon = EditorInterface.get_base_control().get_theme_icon("Add","EditorIcons")
	_add_new_route_button.pressed.connect(_on_new_row)
	_grid.add_child(_add_new_route_button)
