extends Node

@onready var bullet_hit: AudioStreamPlayer = $BulletHit
@onready var copy: AudioStreamPlayer = $Copy
@onready var cut: AudioStreamPlayer = $Cut
@onready var fail: AudioStreamPlayer = $Fail
@onready var menu_click: AudioStreamPlayer = $MenuClick
@onready var paste: AudioStreamPlayer = $Paste
@onready var pause_sfx: AudioStreamPlayer = $Pause
@onready var resume_sfx: AudioStreamPlayer = $Resume
@onready var turret_shoot: AudioStreamPlayer = $TurretShoot
@onready var walk: AudioStreamPlayer = $Walk
@onready var music: AudioStreamPlayer = $Music

# Volume cache (0.0–1.0)
var music_volume := 1.0
var sfx_volume := 1.0

# --- Generic SFX player ---
func play_sfx(player: AudioStreamPlayer):
	if player.playing:
		player.stop()
	player.play()

# --- SFX ---
func play_bullet_hit(): play_sfx(bullet_hit)
func play_copy(): play_sfx(copy)
func play_cut(): play_sfx(cut)
func play_fail(): play_sfx(fail) # unplayed
func play_menu_click(): play_sfx(menu_click)
func play_paste(): play_sfx(paste)
func play_pause(): play_sfx(pause_sfx)
func play_resume(): play_sfx(resume_sfx)
func play_turret_shoot(): play_sfx(turret_shoot)

func play_walk():
	if not walk.playing:
		walk.play()
	
func stop_walk():
	walk.stop()
	
# --- MUSIC ---

func play_music():
	music.play()

func stop_music():
	music.stop()

func pause_music():
	music.stream_paused = true

func resume_music():
	music.stream_paused = false
	
# ------- VOLUME CONTROL -------
#func set_music_volume(value: float):
	#music_volume = value
	#AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(value))
#
#func set_sfx_volume(value: float):
	#sfx_volume = value
	#AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(value))
#
#
#func linear_to_db(value: float) -> float:
	#if value <= 0.0:
		#return -80.0
	#return 20.0 * log10(value)
