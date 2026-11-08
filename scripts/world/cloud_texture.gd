extends RefCounted
## Bulutlar icin kodla uretilen (prosedurel) gurultu dokusu.
## Dis gorsel dosyasi yok; FastNoiseLite + Image kullanilir.

const SIZE := 512


static func build(seed_value: int = 4242) -> ImageTexture:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.seed = seed_value
	noise.frequency = 0.0085
	noise.fractal_octaves = 4
	noise.fractal_lacunarity = 2.0
	noise.fractal_gain = 0.5

	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGB8)
	for y in SIZE:
		for x in SIZE:
			# Kenarlarda tekrar eden (tileable) gorunum icin hafif aynalama.
			var n := noise.get_noise_2d(float(x), float(y))
			var v := clampf(n * 0.5 + 0.5, 0.0, 1.0)
			img.set_pixel(x, y, Color(v, v, v))
	return ImageTexture.create_from_image(img)
