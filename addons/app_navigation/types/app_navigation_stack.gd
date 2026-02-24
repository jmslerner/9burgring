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

## [b]History of app navigation requests.[/b] [br]
## [br]
## Does not have a visual representation.
@tool
class_name AppNavigationStack extends AppNavigationElement

@export var _stack: Array[AppRoute] = []

## Gets the number of elements in the stack.
func count () -> int:
	return len(_stack)

## Pushes a navigation route atop the stack.
func push (nav: AppRoute) -> void:
	_stack.push_back(nav)

## Pops the topmost navigation route from the stack and returns it. Returns [code]null[/code] if the stack was empty.
func pop () -> AppRoute:
	return _stack.pop_back()

## Gets the topmost navigation route on the stack.
func get_current () -> AppRoute:
	if len(_stack) > 0:
		return _stack.back()
	else:
		return null
