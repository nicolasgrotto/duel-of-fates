extends SceneTree

const TESTS_ROOT: String = "res://tests"
const TEST_PREFIX: String = "test_"


func _initialize() -> void:
	var filter: String = _read_filter()
	var paths: PackedStringArray = []
	_collect_test_files(TESTS_ROOT, paths)
	paths.sort()
	var passed: int = 0
	var failed: int = 0
	var report: PackedStringArray = []
	for path in paths:
		var script: GDScript = load(path) as GDScript
		if script == null:
			report.append("%s: could not load" % path)
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
			test_case.before_each()
			test_case.call(method_name)
			if test_case.failures.is_empty():
				passed += 1
			else:
				failed += 1
				report.append_array(test_case.failures)
	for line in report:
		printerr("FAIL ", line)
	print("Tests: %d passed, %d failed" % [passed, failed])
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
