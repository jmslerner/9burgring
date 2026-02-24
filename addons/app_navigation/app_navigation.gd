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
extends EditorPlugin

var _config_dock

func _enable_plugin() -> void:
	# Add autoloads here.
	add_autoload_singleton("AppNavigationServer","scenes/app_navigation_server/app_navigation_server.tscn")
	add_autoload_singleton("AppUiAdder","scenes/app_ui/app_ui_adder.gd")


func _disable_plugin() -> void:
	# Remove autoloads here.
	remove_autoload_singleton("AppUiAdder")
	remove_autoload_singleton("AppNavigationServer")


func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	add_custom_type("AppPage","ScrollContainer",preload("types/app_page.gd"),preload("icons/app_page.svg"))
	add_custom_type("AppNavigationElement","Node",preload("types/app_navigation_element.gd"),preload("icons/app_navigation_element.svg"))
	add_custom_type("AppRoute","AppNavigationElement",preload("types/app_route.gd"),preload("icons/app_route.svg"))
	add_custom_type("AppNavigationStack","AppNavigationElement",preload("types/app_navigation_stack.gd"),preload("icons/app_navigation_stack.svg"))
	# Docks.
	_config_dock = preload("scenes/route_config_dock/route_config_dock.tscn").instantiate()
	add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_UR,_config_dock)


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	remove_custom_type("AppPage")
	remove_custom_type("AppNavigationStack")
	remove_custom_type("AppRoute")
	remove_custom_type("AppNavigationElement")
	# Docks.
	remove_control_from_docks(_config_dock)
	_config_dock.free()
