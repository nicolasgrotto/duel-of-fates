extends SceneTree

const TESTS_ROOT: String = "res://tests"
const TEST_PREFIX: String = "test_"

var _errors: ErrorCollector = ErrorCollector.new()


class ErrorCollector:
	extends Logger

	var messages: PackedStringArray = []
	var _mutex: Mutex = Mutex.new()

	func _log_error(function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_WARNING:
			return
		_mutex.lock()
		messages.append("%s (%s:%d %s) %s" % [rationale if rationale != "" else code, file, line, function, code])
		_mutex.unlock()

	func take() -> PackedStringArray:
		_mutex.lock()
		var taken: PackedStringArray = messages.duplicate()
		messages.clear()
		_mutex.unlock()
		return taken


func _initialize() -> void:
	OS.add_logger(_errors)
	var filter: String = _read_filter()
	var paths: PackedStringArray = []
	_collect_test_files(TESTS_ROOT, paths)
	paths.sort()
	var passed: int = 0
	var failed: int = 0
	var report: PackedStringArray = []
	for path in paths:
		_errors.take()
		var script: GDScript = load(path) as GDScript
		var load_errors: PackedStringArray = _errors.take()
		if script == null or not script.can_instantiate() or not load_errors.is_empty():
			report.append("%s: could not load %s" % [path, " | ".join(load_errors)])
			failed += 1
			continue
		for method in script.get_script_method_list():
			var method_name: String = method["name"]
			if not method_name.begins_with(TEST_PREFIX):
				continue
			if filter != "" and not (path + "::" + method_name).contains(filter):
				continue
			var test_case: TestCase = script.new() as TestCase
			test_case.current_test = "%s::%s" % [path.get_file(), method_name]
			_errors.take()
			test_case.before_each()
			test_case.call(method_name)
			for message in _errors.take():
				test_case.failures.append("%s: script error: %s" % [test_case.current_test, message])
			if test_case.failures.is_empty():
				passed += 1
			else:
				failed += 1
				report.append_array(test_case.failures)
	for line in report:
		printerr("FAIL ", line)
	print("Tests: %d passed, %d failed" % [passed, failed])
	OS.remove_logger(_errors)
	quit(1 if failed > 0 else 0)


func _read_filter() -> String:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var index: int = args.find("--filter")
	if index >= 0 and index + 1 < args.size():
		return args[index + 1]
	return ""


func _collect_test_files(folder: String, paths: PackedStringArray) -> void:
	var dir: DirAccess = DirAccess.open(folder)
	if dir == null:
		return
	for sub in dir.get_directories():
		_collect_test_files(folder.path_join(sub), paths)
	for file in dir.get_files():
		if file.begins_with(TEST_PREFIX) and file.ends_with(".gd"):
			paths.append(folder.path_join(file))
