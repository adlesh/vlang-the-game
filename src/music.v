module main

struct MusicState {
pub:
mut:
    current MusicType
    title_song voidptr
    level_song voidptr
}

struct Sound {
mut:
    data voidptr
}

enum MusicType {
    NO_MUSIC,
    MENU_MUSIC,
    LEVEL_MUSIC,
    ACID_MUSIC
}

//mut use_music := true

fn (game &Game) load_sound(file string) Sound {
    filename := game.datadir + 'sounds/' + file
    println('loading sound: ' + filename)
    data := C.Mix_LoadWAV(filename.str)
    return Sound {
        data: data
    }
}

[inline]
fn (sound mut Sound) free() {
    if sound.data != 0 {
        C.Mix_FreeChunk(sound.data)
        sound.data = 0
    }
}

[inline]
fn (sound &Sound) play() {
    C.Mix_PlayChannel(-1, sound.data, 0)
}

[inline]
fn (sound &Sound) play_loop(loops int) {
    C.Mix_PlayChannel(-1, sound.data, loops)
}

fn (game &Game) load_music(file string) voidptr {
    filename := game.datadir + 'music/' + file
    println('loading music: ' + filename)
    return C.Mix_LoadMUS(filename.str)
}

/*fn load_music(file string) voidptr {
    return C.Mix_LoadMUS(file.str)
}*/

fn free_music(song voidptr) {
    C.Mix_FreeMusic(song)
}

fn play_music(song voidptr, loops int) {
    C.Mix_PlayMusic(song, loops)
}

fn halt_music() {
    C.Mix_HaltMusic()
}

fn playing_music() int {
    return C.Mix_PlayingMusic()
}

fn (game mut Game) set_current_music(song MusicType) {
    game.mus.current = song
}

fn (game &Game) get_current_music() MusicType {
    return game.mus.current
}

fn (game &Game) play_current_music() {
    if playing_music() != 0 {
        halt_music()
    }

    match int(game.mus.current) {
        1 /* MENU_MUSIC */ => { play_music(game.mus.title_song, -1) }
        2 /* LEVEL_MUSIC */ => {
            if game.current_level != NULL && game.current_level.music != NULL {
                play_music(game.current_level.music, -1)
            }
        }
        else => { halt_music() }
    }
}