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

class_name _AnadDroppableButton extends Button

signal file_dropped (path: String)

func _can_drop_data (at_position: Vector2, data: Variant) -> bool:
	return (typeof(data) == TYPE_DICTIONARY) && data.has("files") && (data["files"].get(0).contains(".gd") || data["files"].get(0).contains(".tscn"))

func _drop_data (at_position: Vector2, data: Variant) -> void:
	file_dropped.emit(data["files"].get(0))
