extends RefCounted
# Only immutable coordinate snapshots are read by workers; each job owns its result.
var _index := {}
var _jobs: Array = []
var _tasks: Array = []
var _ready := false
var _chunk := 0

func start(ids: Array, countries: Dictionary) -> void:
	if not _jobs.is_empty() or ids.is_empty():
		return
	var coords: Array = []
	for i in ids.size():
		var iso = str(ids[i])
		_index[iso] = i
		var c: Dictionary = countries.get(iso, {})
		coords.append([float(c.get("lat", 0.0)), float(c.get("lon", 0.0))])
	var workers = clampi(OS.get_processor_count() - 1, 1, 4)
	_chunk = ceili(float(ids.size()) / float(workers))
	for start_index in range(0, ids.size(), _chunk):
		var job = {"start": start_index, "end": mini(start_index + _chunk, ids.size()), "coords": coords, "rows": []}
		_jobs.append(job)
		_tasks.append(WorkerThreadPool.add_task(_calculate.bind(job), false, "Vzdialenosti trás"))

func _calculate(job: Dictionary) -> void:
	var coords: Array = job.coords
	var rows: Array = []
	for i in range(int(job.start), int(job.end)):
		var row = PackedFloat64Array()
		row.resize(coords.size())
		var a: Array = coords[i]
		for j in coords.size():
			var b: Array = coords[j]
			var p1 = deg_to_rad(float(a[0]))
			var p2 = deg_to_rad(float(b[0]))
			var dp = deg_to_rad(float(b[0]) - float(a[0]))
			var dl = deg_to_rad(float(b[1]) - float(a[1]))
			var s = sin(dp * 0.5)
			var t = sin(dl * 0.5)
			var h = s * s + cos(p1) * cos(p2) * t * t
			row[j] = 2.0 * 6371.0 * asin(minf(1.0, sqrt(h)))
		rows.append(row)
	job["rows"] = rows

func poll() -> bool:
	if _ready:
		return true
	if _tasks.is_empty():
		return false
	for task in _tasks:
		if not WorkerThreadPool.is_task_completed(task):
			return false
	for task in _tasks:
		WorkerThreadPool.wait_for_task_completion(task)
	_tasks.clear()
	_ready = true
	return true

func distance(a: String, b: String, fallback: float) -> float:
	if not _ready or not _index.has(a) or not _index.has(b):
		return fallback
	var i = int(_index[a])
	var j = int(_index[b])
	var job: Dictionary = _jobs[i / _chunk]
	var row: PackedFloat64Array = job.rows[i - int(job.start)]
	return row[j]

func wait_for_completion() -> void:
	for task in _tasks:
		WorkerThreadPool.wait_for_task_completion(task)
	_tasks.clear()
	if not _jobs.is_empty():
		_ready = true
