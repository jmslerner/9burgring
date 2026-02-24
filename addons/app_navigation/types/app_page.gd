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

## [b]Base class for navigation-capable app pages.[/b][br]
## [br]
## Override its method [code]_on_navigation_entered(Dictionary)[/code] to read and use route parameters. [br]
## Override its methods [code]play_push_animation_async()[/code] and [code]play_pop_animation_async()[/code]
## in order to customise your page's navigation animations and [code]get_animation_configuration() -> Dictionary[String,bool][/code]
## in order to configure when/whether certain animations play.
@tool
class_name AppPage extends ScrollContainer

## Method called when the framework navigates onto this page. It can be used to read and process route parameters.
func _on_navigation_entered (route_params: Dictionary) -> void:
	pass

## Plays an animation for entering the screen.
func play_push_animation_async () -> void:
	position = Vector2(0,get_viewport().get_visible_rect().size.y)
	var t := get_tree().create_tween().set_ease(Tween.EASE_IN_OUT)
	t.tween_property(self,"position",Vector2.ZERO,0.3)
	t.play()
	await t.finished

## Plays an animation for exiting the screen.
func play_pop_animation_async () -> void:
	var t := get_tree().create_tween().set_ease(Tween.EASE_IN_OUT)
	t.tween_property(self,"position",Vector2(0,get_viewport().get_visible_rect().size.y),0.3)
	t.play()
	await t.finished

## Gets this page's configuration with the following keys. [br]
## "play_pop_before_another_pushes": Whether this page should play its pop animation before another page is pushed on top of it.
## "play_push_after_another_pops": Whether this page should play its push animation after another page is popped from on top of it.
func get_animation_configuration () -> Dictionary[String,bool]:
	return {
		"play_pop_before_another_pushes": false,
		"play_push_after_another_pops": false
	}
