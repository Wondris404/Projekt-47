extends Node

const MAX_SAVE_BYTES = 64 * 1024 * 1024
var last_error = ""
var base_dir = "user://saves"
const TEST_DIR = "user://test_tmp_saves"

# Testy a sonda nesmu pisat do skutocnych slotov: prepnu sa na docasny adresar a po teste ho zmazu.
func use_test_dir() -> void:
	base_dir = TEST_DIR

func cleanup_test_dir() -> void:
	var p = ProjectSettings.globalize_path(TEST_DIR)
	if DirAccess.dir_exists_absolute(p):
		for f in DirAccess.get_files_at(p):
			DirAccess.remove_absolute(p.path_join(f))
		DirAccess.remove_absolute(p)
	base_dir = "user://saves"

func saves_dir() -> String:
	var p = ProjectSettings.globalize_path(base_dir)
	var e = DirAccess.make_dir_recursive_absolute(p)
	if e != OK and e != ERR_ALREADY_EXISTS:
		last_error = "Priečinok savov sa nedá vytvoriť (%d)." % e
	return p

# Staré savy z res://saves (len na čítanie, fallback).
func legacy_dir() -> String:
	return ProjectSettings.globalize_path("res://saves")

func _slot_name(slot: int) -> String:
	return "slot_%d.json" % slot

func _within_save_limit(text: String, limit: int = MAX_SAVE_BYTES) -> bool:
	return text.to_utf8_buffer().size() <= limit

# Vracia cestu pri úspechu, inak text chyby (zachované API); podrobnosť je v last_error.
func save_slot(slot: int) -> String:
	GameState.finish_pending_day()
	last_error = ""
	var path = saves_dir().path_join(_slot_name(slot))
	var tmp = path + ".tmp"
	var text = JSON.stringify(GameState.to_dict())
	if not _within_save_limit(text):
		last_error = "Uložená hra prekračuje limit 64 MiB; pôvodný slot zostal zachovaný."
		return last_error
	var f = FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		last_error = "Save zlyhal (zápis do dočasného súboru)."
		return last_error
	f.store_string(text)
	f.flush()
	f.close()
	if FileAccess.get_file_as_string(tmp).length() != text.length():
		DirAccess.remove_absolute(tmp)
		last_error = "Save zlyhal (nezhodná veľkosť)."
		return last_error
	# Godot na Windowse pri premenovaní najprv odstráni existujúci cieľ.
	# Pred nahradením preto overíme samostatnú kópiu posledného slotu.
	var had_previous = FileAccess.file_exists(path)
	var backup = path + ".backup"
	if had_previous:
		var original_hash = FileAccess.get_sha256(path)
		if original_hash == "" or DirAccess.copy_absolute(path, backup) != OK or FileAccess.get_sha256(backup) != original_hash:
			last_error = "Save zlyhal (záložná kópia sa nedá bezpečne vytvoriť); pôvodný slot zostal zachovaný."
			return last_error
	if DirAccess.rename_absolute(tmp, path) != OK:
		DirAccess.remove_absolute(tmp)
		last_error = "Save zlyhal (premenovanie); predchádzajúci slot je v záložnej kópii." if had_previous else "Save zlyhal (premenovanie)."
		return last_error
	return path

func _find_slot(slot: int) -> String:
	var p = saves_dir().path_join(_slot_name(slot))
	if FileAccess.file_exists(p):
		return p
	if FileAccess.file_exists(p + ".backup"):
		return p + ".backup"  # obnova, keď presun nového slotu po odstránení cieľa zlyhal
	if base_dir == TEST_DIR:
		return ""  # test nesmie citat skutocne ani legacy sloty
	var legacy = legacy_dir().path_join(_slot_name(slot))
	if FileAccess.file_exists(legacy):
		return legacy
	return ""

# Vracia "" pri úspechu, inak text chyby; pri chybe sa živý stav nemení.
func load_slot(slot: int) -> String:
	last_error = ""
	var path = _find_slot(slot)
	if path == "":
		return "Slot je prázdny."
	var f = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return "Slot sa nedá čítať."
	if f.get_length() > MAX_SAVE_BYTES:
		return "Save je príliš veľký."
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return "Poškodený save."
	var err = GameState.from_dict(data)
	if err != "":
		last_error = err
	return err

func has_slot(slot: int) -> bool:
	return _find_slot(slot) != ""
