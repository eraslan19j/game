extends Node
## Basit performans olcumu.
## Bazi karelerde FPS ve cizim istatistiklerini loga yazar; boylece
## CI headless calistirmasinda bile sahnenin gercekten cizildigini dogrulariz.

@export var sample_frames: int = 90

## Tani modu: CI'da tek calistirmada 4 ekran goruntusu alip kare artefaktinin
## kaynagini kesin tespit etmek icin (su / arazi / bitki / hepsi).
@export var debug_extra_shots: bool = false

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
	var vp2 := get_viewport()
	if vp2 != null:
		print("[Perf] cizim=%d  ucgen=%d  nesne=%d" % [
			int(vp2.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME)),
			int(vp2.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME)),
			int(vp2.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_OBJECTS_IN_FRAME))])
	print("[Perf] kalite=%s  golge=%s  fps_hedefi=30+" % [
		QualitySettings.level_name(),
		"acik" if QualitySettings.preset()["shadow_enabled"] else "kapali"])
	_maybe_screenshot()
	if debug_extra_shots:
		_debug_isolate()


## Tani: sirayla su, arazi ve bitkileri gizleyip ekran goruntusu alir.
func _debug_isolate() -> void:
	var path := OS.get_environment("CAPTURE_PATH")
	var base := path.get_basename() if path != "" else "res://ci_screenshot"
	var water := get_node_or_null("../Water") as Node3D
	var terrain := get_node_or_null("../Terrain") as Node3D
	var nature := get_node_or_null("../Nature") as Node3D
	if water == null or terrain == null or nature == null:
		print("[Debug] sahne dugumleri bulunamadi")
		return
	# 1) su yok
	water.visible = false
	await _shot(base + "_nowater.png", "suyu gizle")
	water.visible = true
	# 2) arazi yok
	terrain.visible = false
	await _shot(base + "_noterrain.png", "araziyi gizle")
	terrain.visible = true
	# 3) bitki yok
	nature.visible = false
	await _shot(base + "_nonature.png", "bitkileri gizle")
	nature.visible = true
	# 4) sadece gok (hepsi gizli)
	water.visible = false
	terrain.visible = false
	nature.visible = false
	await _shot(base + "_skyonly.png", "sadece gok")
	water.visible = true
	terrain.visible = true
	nature.visible = true


func _shot(p: String, label_text: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var vp := get_viewport()
	if vp == null:
		return
	var img := vp.get_texture().get_image()
	if img == null:
		return
	var err := img.save_png(p)
	print("[Debug] %s -> %s (%s)" % [p, "OK" if err == OK else str(err), label_text])


## Sadece CI'da (CAPTURE_SCREENSHOT=1) ekran goruntusu alir.
## Boylece yapilan isin gercekten dogru gorundugu kontrol edilebilir.
func _maybe_screenshot() -> void:
	if OS.get_environment("CAPTURE_SCREENSHOT") == "":
		return
	await RenderingServer.frame_post_draw
	var vp := get_viewport()
	if vp == null:
		return
	var img := vp.get_texture().get_image()
	if img == null:
		print("[Shot] ekran goruntusu alinamadi")
		return
	var path := OS.get_environment("CAPTURE_PATH")
	if path == "":
		path = "res://ci_screenshot.png"
	var err := img.save_png(path)
	print("[Shot] %s -> %s (%dx%d)" % [path, "OK" if err == OK else str(err), img.get_width(), img.get_height()])
