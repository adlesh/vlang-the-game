module main

struct KeyMap {
mut:
    player_sprint u32
    player_jump u32
    player_left u32
    player_right u32
}

fn (game mut Game) keymap_setup() {
    game.keymap.player_sprint = u32(C.SDLK_LSHIFT)
    game.keymap.player_jump = u32(C.SDLK_SPACE)
    game.keymap.player_left = u32(C.SDLK_LEFT)
    game.keymap.player_right = u32(C.SDLK_RIGHT)
}