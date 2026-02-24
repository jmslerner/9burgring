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

extends Node

@onready var _page_container: Control = $"./PageLayer/PageContainer"

func _on_page_popped (old_page: AppPage) -> void:
	if _page_container.get_child_count() > 0:
		await (_page_container.get_child(0) as AppPage).play_pop_animation_async()
		_page_container.get_child(0).queue_free()
	_page_container.add_child(old_page)
	if old_page.get_animation_configuration().has("play_push_after_another_pops") && old_page.get_animation_configuration()["play_push_after_another_pops"]:
		await old_page.play_push_animation_async()

func _on_page_pushed (new_page: AppPage) -> void:
	if (_page_container.get_child_count() > 0) && _page_container.get_child(0).get_animation_configuration().has("play_pop_before_another_pushes") && _page_container.get_child(0).get_animation_configuration()["play_pop_before_another_pushes"]:
		await (_page_container.get_child(0) as AppPage).play_pop_animation_async()
	if _page_container.get_child_count() > 0:
		_page_container.get_child(0).queue_free()
	_page_container.add_child(new_page)
	await new_page.play_push_animation_async()

func _ready () -> void:
	AppNavigationServer.page_popped.connect(_on_page_popped)
	AppNavigationServer.page_pushed.connect(_on_page_pushed)
	var home_route := AppRoute.new()
	home_route.key = "index"
	home_route.route_parameters = {}
	AppNavigationServer.push_and_replace_top(home_route)

func _notification (what: int) -> void:
	if (what == NOTIFICATION_WM_GO_BACK_REQUEST) || (what == NOTIFICATION_WM_CLOSE_REQUEST):
		var result := AppNavigationServer.pop_top()
		if result == Error.ERR_DOES_NOT_EXIST:
			get_tree().quit()

func _input (event: InputEvent) -> void:
	if Input.is_action_just_released("ui_cancel"):
		self.notification(NOTIFICATION_WM_GO_BACK_REQUEST)
