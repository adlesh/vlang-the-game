module main

import os

struct SdlContext {
pub:
mut:
	screen_width		int
	screen_height		int
    scale_x         f32
	scale_y         f32
    window          voidptr
	renderer        voidptr
	screen          voidptr
}

struct Textures {
pub:
mut:
    cursor &TextureType
    valex &TextureType
    valex_jump &TextureType
    valex_big &TextureType
    valex_bigjump &TextureType
}

struct Sounds {
pub:
mut:
    jump Sound
    big_jump Sound
    scream Sound
}

struct Game {
pub:
mut:
    _delta f64
    last_tick u32
    menu_action int

    level int
    lives int
    score int
    scroll_x int
    scroll_y int
    
    player_x f64
    player_y f64
    player_xo f64
    player_yo f64
    player_w int
    player_h int

    quit bool
    show_menu bool

    datadir string
    current_menu &Menu
    mus MusicState
    sounds Sounds
    sdl SdlContext
    tex Textures

    keymap KeyMap
    input_state InputState
    physics Physics
    tile_map &TileMap

    // states for gui screens
    title_state TitleState

    level_subsets []LevelSubset

    current_level &Level
    current_subset &LevelSubset

    font_white &Font
    font_black &Font
    font_blue &Font
    font_gold &Font
    font_red &Font
}

fn (game mut Game) load_data() {
    game.mus.title_song = game.load_music('title.mod')
    game.tex.cursor = game.load_texture('images/gui/mousecursor.png')
    game.font_white = game.load_font('white', 16, 18)
    game.font_black = game.load_font('black', 16, 18)
    game.font_blue = game.load_font('blue', 16, 18)
    game.font_red = game.load_font('red', 16, 18)
    game.font_gold = game.load_font('gold', 16, 18)

    game.tex.valex = game.load_texture('images/sprites/valex.png')
    game.tex.valex_jump = game.load_texture('images/sprites/valex-jump.png')
    game.tex.valex_big = game.load_texture('images/sprites/bigvalex.png')
    game.tex.valex_bigjump = game.load_texture('images/sprites/bigvalex-jump.png')

    game.sounds.jump = game.load_sound('jump.wav')
    game.sounds.big_jump = game.load_sound('bigjump.wav')
    game.sounds.scream = game.load_sound('scream.wav')

    game.tile_map_init()
}

fn (game mut Game) draw_cursor() {
    x := 0
    y := 0
    C.SDL_GetMouseState(&x, &y)

    if x == 0 && y == 0 {
        return
    }

    game.texture_draw_part(game.tex.cursor, 0, 0, int(f32(x) / game.sdl.scale_x), int(f32(y) / game.sdl.scale_y), 32, 32, 255)
}

fn (game mut Game) setup() {
    w := 854
    h := 480

	C.SDL_Init(C.SDL_INIT_VIDEO | C.SDL_INIT_AUDIO | C.SDL_INIT_JOYSTICK)
	//C.atexit(C.SDL_Quit)

    mut sdl := &game.sdl
    C.SDL_CreateWindowAndRenderer(w, h, 0, &sdl.window, &sdl.renderer)
    C.SDL_SetHint(C.SDL_HINT_RENDER_SCALE_QUALITY, 'linear')
    C.SDL_SetRenderDrawBlendMode(&sdl.renderer, C.SDL_BLENDMODE_BLEND)
	C.SDL_SetWindowTitle(sdl.window, 'Vlang the game')
    C.SDL_ShowCursor(C.SDL_DISABLE)
	sdl.screen_width = w
	sdl.screen_height = h
    sdl.scale_x = 1.0
    sdl.scale_y = 1.0
	sdl.screen = C.SDL_CreateTexture(sdl.renderer, C.SDL_PIXELFORMAT_ARGB8888, C.SDL_TEXTUREACCESS_STREAMING, w, h)

	C.Mix_Init(0)
	//C.atexit(C.Mix_Quit)
	if C.Mix_OpenAudio(44100, C.AUDIO_S16, 2, 2048) < 0 {
		println('couldn\'t open audio')
	}

    //game.mus.use_music = true
    if os.file_exists('data') {
        game.datadir = './data/'
    } else {
        game.datadir = '../data/'
    }
    game.menu_action = MENU_ACTION_NONE

    game.keymap_setup()
}

fn (game mut Game) free() {
    game.current_level = NULL
    game.current_subset = NULL
    free(game)
}

fn main() {
    mut game := &Game{}

    game.setup()
    game.load_data()
    game.load_subsets()

    game.play_current_music()

    mut done := false
    for {
        done = game.title()
        if done {
            break
        }
    }

    game.free()
}