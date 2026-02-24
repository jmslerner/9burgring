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

## [b]Instance of an app navigation request.[/b] [br]
## [br]
## Does not have a visual representation.
@tool
class_name AppRoute extends AppNavigationElement

## Key of the page being requested.
@export var key: String

## Data to send to the requested page.
@export var route_parameters: Dictionary
