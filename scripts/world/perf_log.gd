extends Node
## Basit performans olcumu.
## Bazi karelerde FPS ve cizim istatistiklerini loga yazar; boylece
## CI headless calistirmasinda bile sahnenin gercekten cizildigini dogrulariz.

@export var sample_frames: int = 90

var _frames: int = 0
var _time: float = 0.0
var _reported: bool = false


func _process(delta: float) -> void:
	if _reported:
		return
	_frames += 1
	_time += delta
	if _frames < sample_frames:
		return
	_reported = true
	var fps := float(_frames) / maxf(_time, 0.0001)
	var vp := get_viewport()
	var draw_calls := 0
	var prims := 0
	if vp != null:
		draw_calls = int(vp.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME))
		prims = int(vp.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME))
	print("[Perf] renderer=%s  fps=%.1f (%d kare / %.2f sn)  cizim=%d  ucgen=%d" % [
		RenderingServer.get_video_adapter_name(), fps, _frames, _time, draw_calls, prims])
	print("[Perf] kalite=%s  golge=%s  fps_hedefi=30+" % [
		QualitySettings.level_name(),
		"acik" if QualitySettings.preset()["shadow_enabled"] else "kapali"])
