extends Node
## Basit iki dilli metin tablosu (Autoload: I18N).
## Yeni metin eklemek icin STRINGS sozlugune satir eklemek yeterli.

const DEFAULT_LANG := "tr"

const STRINGS := {
	"tr": {
		"settings": "Ayarlar",
		"quality": "Kalite",
		"quality_low": "Dusuk",
		"quality_medium": "Orta",
		"quality_high": "Yuksek",
		"quality_hint": "Dusuk = daha akici, Yuksek = daha guzel",
		"time_of_day": "Gunun saati",
		"close": "Kapat",
		"language": "Dil",
		"fps": "FPS",
		"phase_dawn": "Gun dogumu",
		"phase_morning": "Sabah",
		"phase_midday": "Ogle",
		"phase_afternoon": "Oglenden sonra",
		"phase_sunset": "Gun batimi",
		"phase_dusk": "Alacakaranlik",
		"phase_night": "Gece",
		"applied": "Uygulandi",
	},
	"en": {
		"settings": "Settings",
		"quality": "Quality",
		"quality_low": "Low",
		"quality_medium": "Medium",
		"quality_high": "High",
		"quality_hint": "Low = smoother, High = prettier",
		"time_of_day": "Time of day",
		"close": "Close",
		"language": "Language",
		"fps": "FPS",
		"phase_dawn": "Sunrise",
		"phase_morning": "Morning",
		"phase_midday": "Midday",
		"phase_afternoon": "Afternoon",
		"phase_sunset": "Sunset",
		"phase_dusk": "Dusk",
		"phase_night": "Night",
		"applied": "Applied",
	},
}

var lang: String = DEFAULT_LANG


func _ready() -> void:
	load_lang()


func get_string(key: String) -> String:
	var table: Dictionary = STRINGS.get(lang, STRINGS[DEFAULT_LANG])
	if table.has(key):
		return table[key]
	var fallback: Dictionary = STRINGS[DEFAULT_LANG]
	return fallback.get(key, key)


## Gunun saatine (0..1) gore evre adi.
func phase_name(phase: float) -> String:
	var p := fmod(phase + 1.0, 1.0)
	if p < 0.06 or p >= 0.94:
		return get_string("phase_dawn")
	if p < 0.16:
		return get_string("phase_morning")
	if p < 0.36:
		return get_string("phase_midday")
	if p < 0.58:
		return get_string("phase_afternoon")
	if p < 0.72:
		return get_string("phase_sunset")
	if p < 0.86:
		return get_string("phase_dusk")
	return get_string("phase_night")


func set_lang(new_lang: String) -> void:
	lang = new_lang if STRINGS.has(new_lang) else DEFAULT_LANG
	save_lang()


func toggle_lang() -> String:
	set_lang("en" if lang == "tr" else "tr")
	return lang


func save_lang() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("ui", "lang", lang)
	cfg.save("user://ui.cfg")


func load_lang() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://ui.cfg") == OK:
		var v := str(cfg.get_value("ui", "lang", DEFAULT_LANG))
		lang = v if STRINGS.has(v) else DEFAULT_LANG
