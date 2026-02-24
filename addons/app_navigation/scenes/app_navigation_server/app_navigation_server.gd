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
extends Node

## Signal fired when a paged is pushed onto the navigation stack. It includes the new page as an argument. [br]
## [br]
## The framework uses this signal to instantiate and animate pages.
signal page_pushed (new_page: AppPage)

## Signal fired when the current page is popped from the navigation stack. It includes the previous page as an argument. [br]
## [br]
## The framework uses this signal to instantiate and animate pages.
signal page_popped (old_page: AppPage)

var _registered_routes: Dictionary[String,String]

var _stack: AppNavigationStack

func _ready () -> void:
	_load_routes()

func _exit_tree () -> void:
	_save_routes()

func _load_routes () -> void:
	if _stack == null:
		_stack = AppNavigationStack.new()
	_registered_routes = {}
	if !DirAccess.dir_exists_absolute("res://addons/app_navigation/__routeconfig__/"):
		DirAccess.make_dir_recursive_absolute("res://addons/app_navigation/__routeconfig__/")
	for p in DirAccess.get_files_at("res://addons/app_navigation/__routeconfig__/"):
		var file := FileAccess.open("res://addons/app_navigation/__routeconfig__/" + p,FileAccess.READ)
		_registered_routes.get_or_add(p.split(".").get(0),file.get_as_text())
		file.close()

func _save_routes () -> void:
	if !DirAccess.dir_exists_absolute("res://addons/app_navigation/__routeconfig__/"):
		DirAccess.make_dir_recursive_absolute("res://addons/app_navigation/__routeconfig__/")
	for route in _registered_routes.keys():
		var file := FileAccess.open("res://addons/app_navigation/__routeconfig__/" + route + ".txt",FileAccess.WRITE)
		file.store_string(_registered_routes.get(route))
		file.close()

## Registers a page route for future use. [br]
## This method is called by the framework's editor dock.
func register_route (key: String, resource_path: String) -> Error:
	_load_routes()
	var instantiable: Resource = ResourceLoader.load(resource_path)
	if len(key) == 0:
		push_error("Route key cannot be empty.")
		return Error.FAILED
	if instantiable is PackedScene:
		var type_tester = instantiable.instantiate()
		if type_tester is AppPage:
			_registered_routes[key] = resource_path
			_save_routes()
			return Error.OK
		else:
			push_error("Type Error: Registered route doesn't lead to an AppPage.")
			return Error.FAILED
	elif instantiable is GDScript:
		var type_tester = instantiable.new()
		if type_tester is AppPage:
			_registered_routes[key] = resource_path
			_save_routes()
			return Error.OK
		else:
			push_error("Type Error: Registered route doesn't lead to an AppPage.")
			return Error.FAILED
	else:
		push_error("Type Error: Registered route cannot be instanced because it is neither a PackedScene nor a GDScript.")
		return Error.FAILED

## Pushes a new route atop the navigation stack.
func push (route: AppRoute) -> Error:
	_load_routes()
	if _registered_routes.has(route.key):
		var page_instantiator = ResourceLoader.load(_registered_routes[route.key])
		var page: AppPage
		if page_instantiator is PackedScene:
			page = page_instantiator.instantiate()
		elif page_instantiator is GDScript:
			page = page_instantiator.new()
		else:
			return Error.FAILED
		_stack.push(route)
		page._on_navigation_entered(route.route_parameters)
		page_pushed.emit(page)
		return Error.OK
	else:
		return Error.ERR_FILE_NOT_FOUND

## Pushes a new route atop the navigation stack, replacing its current top.
func push_and_replace_top (route: AppRoute) -> Error:
	_load_routes()
	if _registered_routes.has(route.key):
		var page_instantiator = ResourceLoader.load(_registered_routes[route.key])
		var page: AppPage
		if page_instantiator is PackedScene:
			page = page_instantiator.instantiate()
		elif page_instantiator is GDScript:
			page = page_instantiator.new()
		else:
			return Error.FAILED
		_stack.pop()
		_stack.push(route)
		page._on_navigation_entered(route.route_parameters)
		page_pushed.emit(page)
		return Error.OK
	else:
		return Error.ERR_FILE_NOT_FOUND

## Removes the topmost page from the navigation stack.
func pop_top () -> Error:
	_load_routes()
	if _stack.count() <= 1:
		return Error.ERR_DOES_NOT_EXIST
	else:
		var popped := _stack.pop()
		var page_instantiator = ResourceLoader.load(_registered_routes[_stack.get_current().key])
		var page: AppPage
		if page_instantiator is PackedScene:
			page = page_instantiator.instantiate()
		elif page_instantiator is GDScript:
			page = page_instantiator.new()
		else:
			_stack.push(popped)
			return Error.FAILED
		page._on_navigation_entered(_stack.get_current().route_parameters)
		page_popped.emit(page)
		return Error.OK
