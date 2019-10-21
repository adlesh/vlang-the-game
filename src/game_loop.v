module main

import math

const (
    DIR_LEFT = -1
    DIR_RIGHT = 1

    WALK_SPEED = 2.2
    SPRINT_SPEED = 2.8
    WALK_ACCEL = 0.03
    SPRINT_ACCEL = 0.04
)

struct InputState {
mut:
    dir int
    old_dir int
    left bool
    right bool
    jump bool
    sprint bool
    old_jump bool
    can_jump bool
    jumping bool
}

fn (state mut InputState) reset() {
    state.left = false
    state.right = false
    state.jump = false
    state.old_jump = false
    state.dir = DIR_RIGHT
    state.old_dir = DIR_RIGHT
    state.can_jump = true
    state.jumping = false
}

fn (game mut Game) handle_game_sdl_event(key int, state bool) bool {
    match u32(key) {
        game.keymap.player_left => {
            game.input_state.left = state
            return true
        }
        game.keymap.player_right => {
            game.input_state.right = state
            return true
        }
        game.keymap.player_jump => {
            game.input_state.jump = state
            return true
        }
        game.keymap.player_sprint => {
            game.input_state.sprint = state
            return true
        }
    }

    return false
}

fn (game mut Game) process_input() {
    mut vx := game.physics.vel_x
    mut ax := game.physics.accel_x
    duck := false
    
    game.player_xo = game.player_x
    game.player_yo = game.player_y

    mut accel := WALK_ACCEL
    mut speed := WALK_SPEED

    if game.input_state.sprint {
        accel = SPRINT_ACCEL
        speed = SPRINT_SPEED
    }

    mut dir_s := f64(0)

    if !game.input_state.left && game.input_state.right && (!duck || game.physics.vel_y != 0) {
        game.input_state.old_dir = game.input_state.dir
        game.input_state.dir = DIR_RIGHT
        dir_s = f64(DIR_RIGHT)
    } else if game.input_state.left && !game.input_state.right && (!duck || game.physics.vel_y != 0) {
        game.input_state.old_dir = game.input_state.dir
        game.input_state.dir = DIR_LEFT
        dir_s = f64(DIR_LEFT)
    }

    ax = dir_s * WALK_ACCEL
    //println('$dir_s $ax')

    if (vx >= speed) && (dir_s == DIR_RIGHT) { // clamp speed
        vx = speed
        ax = 0    
    } else if (vx <= -speed) && (dir_s == DIR_LEFT) {
        vx = -speed
        ax = 0    
    }

    if dir_s != 0 && (C.fabs(vx) < speed) {
        vx = dir_s * speed
    }

    if dir_s == 0 {
        if C.fabs(vx) < speed {
            vx = 0
            ax = 0
        } else if vx < 0 {
            ax = accel * 1.5
        } else {
            ax = accel * -1.5
        }
    }

    if game.player_on_ground() {
        if -game.physics.vel_y < 0 {
            game.physics.vel_y = 0
        }

        game.physics.handle_gravity = false
        game.player_y = f64(int(game.player_y) & 0xffffffe0)
    } else {
        game.physics.handle_gravity = true
    }

    game.physics.vel_x = vx
    game.physics.accel_x = ax

    if game.player_on_ground() && !game.input_state.can_jump {
        game.input_state.can_jump = true
    }

    if game.input_state.jump || (!game.input_state.jump && game.input_state.jumping) {
        if game.input_state.jump && game.input_state.can_jump {
            if game.player_on_ground() {
                game.sounds.jump.play()

                if C.fabs(game.physics.vel_x) > WALK_SPEED {
                    game.physics.vel_y = -5.8
                } else {
                    game.physics.vel_y = -5.2
                }

                game.player_y--
                game.input_state.jumping = true
                game.input_state.can_jump = false
            }
        } else if !game.input_state.jump && game.input_state.jumping {
            game.input_state.jumping = false

            if -game.physics.vel_y > 0 {
                game.physics.vel_y = 0
            }
        }

        if game.current_level.is_solid((int(game.player_x) + game.player_w / 2) / 32, (int(game.player_y) + game.player_h + 64) / 32)
            && game.current_level.is_solid((int(game.player_x) + 1) / 32, (int(game.player_y) + game.player_h + 64) / 32)
            && game.current_level.is_solid((int(game.player_x) + game.player_w - 1) / 32, (int(game.player_y) + game.player_h + 64) / 32)
            && !game.input_state.jumping && !game.input_state.can_jump && game.input_state.jump && !game.input_state.old_jump {
            game.input_state.can_jump = true
        }

        game.input_state.old_jump = game.input_state.jump
    }
}

fn (game mut Game) process_physics(delta f64) {
    res := game.physics.handle(delta, game.player_x, game.player_y)
    game.player_x = res.x
    game.player_y = res.y
    mut in_solid := false

    game.collision_post()

    if res.x != game.player_x {
        game.physics.vel_x = 0
    }

    if game.player_on_ground() {
        if -game.physics.vel_y < 0 {
            game.player_y = f64(int(game.player_y) & 0xffffffe0)
            game.physics.vel_y = 0
        }

        game.physics.handle_gravity = false
    } else {
        game.physics.handle_gravity = true
        if game.player_under_solid() {
            game.physics.vel_y = 0
            in_solid = true
        }
    }

    if in_solid {
        game.player_y++
        game.player_yo++
        if game.player_on_ground() {
            game.input_state.jumping = false
        }
    }

    if game.player_x > (game.scroll_x + game.sdl.screen_width / 2) {
        game.scroll_x = int(game.player_x) - (game.sdl.screen_width / 2)
    } else if game.player_x - game.scroll_x < 300 {
        game.scroll_x = int(game.player_x) - 300
    }

    if game.player_y > (game.scroll_y + (game.sdl.screen_height * 8 / 10)) {
        game.scroll_y = int(game.player_y) - (game.sdl.screen_height * 8 / 10)
    } else if game.player_y - game.scroll_y < 240 {
        game.scroll_y = int(game.player_y) - 240
    }

    if game.scroll_x < 0 {
        game.scroll_x = 0
    } else if game.scroll_x > (game.current_level.width * 32) - game.sdl.screen_width {
        game.scroll_x = (game.current_level.width * 32) - game.sdl.screen_width
    }

    if game.scroll_y < 0 {
        game.scroll_y = 0
    } else if game.scroll_y > (game.current_level.height * 32) - game.sdl.screen_height {
        game.scroll_y = (game.current_level.height * 32) - game.sdl.screen_height
    }
}

fn (game mut Game) collision_post() {
    mut lpath := f64(0)
    mut xd := f64(0)
    mut yd := f64(0)
    mut h := 0
    mut steps := 0

    if game.player_x == game.player_xo && game.player_y == game.player_yo {
        return
    } else if game.player_x == game.player_xo && game.player_y != game.player_yo {
        lpath = game.player_y - game.player_yo
        yd = 1
        xd = 0
        h = 1

        if lpath < 0 {
            yd = -1
        }

        lpath = math.abs(lpath)
    } else if game.player_x != game.player_xo && game.player_y == game.player_yo {
        lpath = game.player_x - game.player_xo
        xd = 1
        yd = 0
        h = 2

        if lpath < 0 {
            xd = -1
        }

        lpath = math.abs(lpath)
    } else {
        lpath = math.abs(game.player_x - game.player_xo)
        if math.abs(game.player_y - game.player_yo) > lpath {
            lpath = math.abs(game.player_y - game.player_yo)
        }

        h = 3
        xd = (game.player_x - game.player_xo) / lpath
        yd = (game.player_y - game.player_yo) / lpath
    }

    steps = int(lpath / 16.0)
    orig_x := game.player_xo
    orig_y := game.player_yo
    game.player_xo += xd
    game.player_yo += yd

    for i := 0; i <= int(lpath); i++ {
        game.player_xo += xd
        game.player_yo += yd

        if steps > 0 {
            game.player_xo += xd * 16
            game.player_yo += yd * 16
            steps--
        }
        
        if game.collision_map(game.player_xo, game.player_yo, game.player_w, game.player_h) {
            match h {
                1 => {
                    game.player_y = game.player_yo - yd
                    for game.collision_map(game.player_x, game.player_y, game.player_w, game.player_h) {
                        game.player_y -= yd
                    }
                }
                2 => {
                    game.player_x = game.player_xo - xd
                    for game.collision_map(game.player_x, game.player_y, game.player_w, game.player_h) {
                        game.player_x -= xd
                    }
                }
                3 => {
                    xt := game.player_x
                    yt := game.player_y
                    game.player_x = game.player_xo - xd
                    game.player_y = game.player_yo - yd

                    for game.collision_map(game.player_x, game.player_y, game.player_w, game.player_h) {
                        game.player_x -= xd
                        game.player_y -= yd
                    }

                    mut temp := game.player_x
                    game.player_x = xt
                    if !game.collision_map(game.player_x, game.player_y, game.player_w, game.player_h) {
                        break
                    }

                    game.player_x = temp
                    temp = game.player_y
                    game.player_y = yt

                    if game.collision_map(game.player_x, game.player_y, game.player_w, game.player_h) {
                        game.player_y = temp
                        for !game.collision_map(game.player_x, game.player_y, game.player_w, game.player_h) {
                            game.player_y += yd
                        }
                        game.player_y -= yd
                    }
                    break
                }
            }
            break
        }
    }

    if (xd > 0 && game.player_x < orig_x) || (xd < 0 && game.player_x > orig_x) {
        game.player_x = orig_x
    }

    if (yd > 0 && game.player_y < orig_y) || (yd < 0 && game.player_y > orig_y) {
        game.player_y = orig_y
    }

    game.player_xo = game.player_x
    game.player_yo = game.player_y
}

fn (game &Game) collision_map(pos_x, pos_y, w, h f64) bool {
    if game.current_level == NULL {
        return false
    }

    level := game.current_level
    start_x := int(pos_x + 1) / 32
    start_y := int(pos_y + 1) / 32
    max_x := int(pos_x + w)
    max_y := int(pos_y + h)

    for x := start_x; x * 32 < max_x; x++ {
        for y := start_y; y * 32 < max_y; y++ {
            tid := C.vp_get(level.layer_ic, (y * level.width) + x)
            if tid != 0 {
                tile := &Tile(game.tile_map.tiles.get(int(tid)))
                if tile != NULL && tile.solid() {
                    game.fillrect(x * 32 - game.scroll_x, y * 32 - game.scroll_y, 32, 32, 255, 0, 0, 50)
                    return true
                }
            }
            
            game.fillrect(x * 32 - game.scroll_x, y * 32 - game.scroll_y, 32, 32, 0, 255, 0, 50)
        }
    }

    return false
}

fn (game &Game) draw_player() {
    //game.fillrect(game.player_x - game.scroll_x, game.player_y - game.scroll_y, 32, 32, 255, 128 + game.input_state.dir * 64, 0, 128)
    if game.input_state.dir == DIR_LEFT {
        game.texture_draw_flip(game.tex.valex, int(game.player_x) - game.scroll_x, int(game.player_y) - game.scroll_y, C.SDL_FLIP_HORIZONTAL)
    } else {
        game.texture_draw_flip(game.tex.valex, int(game.player_x) - game.scroll_x, int(game.player_y) - game.scroll_y, 0)
    }
}

fn (game &Game) player_on_ground() bool {
    if game.current_level == NULL {
        return false
    }

    return game.current_level.is_solid(int(f32(game.player_x + game.player_w / 2) / 32.0), int(f32(game.player_y + game.player_h) / 32.0))
        && game.current_level.is_solid(int(f32(game.player_x + 1) / 32.0), int(f32(game.player_y + game.player_h) / 32.0))
        && game.current_level.is_solid(int(f32(game.player_x + game.player_w - 1) / 32.0), int(f32(game.player_y + game.player_h) / 32.0))
}

fn (game &Game) player_under_solid() bool {
    if game.current_level == NULL {
        return false
    }

    return game.current_level.is_solid(int(f32(game.player_x + game.player_w / 2) / 32.0), int(f32(game.player_y) / 32.0))
        && game.current_level.is_solid(int(f32(game.player_x + 1) / 32.0), int(f32(game.player_y) / 32.0))
        && game.current_level.is_solid(int(f32(game.player_x + game.player_w - 1) / 32.0), int(f32(game.player_y) / 32.0))
}

fn (game mut Game) game_loop() bool {
    mut done := false
    mut eff_x := 0
    mut eff_y := 0

    for {
        if done || game.quit {
            break
        }

        game.poll_quits()

        if eff_y <= game.sdl.screen_height / 2 {
            game.fillrect(0, 0, game.sdl.screen_width, eff_y, 0, 0, 0, 255) // top band
            game.fillrect(0, game.sdl.screen_height - eff_y, game.sdl.screen_width, eff_y, 0, 0, 0, 255) // bottom band
            eff_y += 3
        }

        if eff_x < game.sdl.screen_width / 2 {
            game.fillrect(0, 0, eff_x, game.sdl.screen_height, 0, 0, 0, 255) // left band
            game.fillrect(game.sdl.screen_width - eff_x, 0, eff_x, game.sdl.screen_height, 0, 0, 0, 255) // right band
            eff_x += 4
        } else {
            break
        }

        C.SDL_Delay(10)
        game.flipscreen()
    }

    game.input_state.reset()
    game.physics.reset()
    game.set_current_music(MusicType.LEVEL_MUSIC)
    game.play_current_music()

    mut delay := f64(0)
    level_text := 'LEVEL $game.level'
    live_text := 'ALEX x $game.lives'
    level := game.current_level
    game.delta()

    for {
        if done || game.quit {
            break
        }

        if game.poll_quits() {
            delay = 1
        }

        game.clearscreen(0, 0, 0)

        game.font_red.draw_align(level_text, game.sdl.screen_width / 2, game.sdl.screen_height / 2 - 30, ALIGN_CENTER | ALIGN_MIDDLE, 255)
        game.font_white.draw_align(level.name, game.sdl.screen_width / 2, game.sdl.screen_height / 2, ALIGN_CENTER | ALIGN_MIDDLE, 255)
        game.font_gold.draw_align(live_text, game.sdl.screen_width / 2, game.sdl.screen_height / 2 + 30, ALIGN_CENTER | ALIGN_MIDDLE, 255)
        
        C.SDL_Delay(10)
        game.flipscreen()
        
        delay += game.delta()
        if delay >= 1 {
            delay = 1
            break
        }
    }

    mut max_tiles_x := game.sdl.screen_width / 32 + 2
    mut max_tiles_y := game.sdl.screen_height / 32 + 2
    mut idx := 0
    mut tile := byte(0)

    if max_tiles_x > level.width {
        max_tiles_x = level.width
    }

    if max_tiles_y > level.height {
        max_tiles_y = level.height
    }

    if 3 == 4 { // just to make V shut up for now
        done = true
    }

    init_x := 70
    init_y := 100
    game.player_x = init_x
    game.player_y = init_y
    game.player_w = 32
    game.player_h = 32
    game.delta()

    for {
        if done || game.quit {
            break
        }

        for C.st_poll_event() {
            if C.st_event_type() == C.SDL_QUIT {
                game.quit = true
                break
            } else if C.st_event_type() == C.SDL_KEYDOWN {
                key := C.st_event_sym()
                game.handle_game_sdl_event(key, true)
            } else if C.st_event_type() == C.SDL_KEYUP {
                key := C.st_event_sym()
                game.handle_game_sdl_event(key, false)
            }
        }
        game.clearscreen(0, 0, 0)

        if level.background != NULL {
            game.texture_draw_bg(level.background)
        }

        start_x := game.scroll_x / 32
        start_y := game.scroll_y / 32
        rem_x := game.scroll_x & 31
        rem_y := game.scroll_y & 31

        // draw background and interactive layer
        for y := 0; y < max_tiles_y; y++ {
            if start_y + y >= level.height {
                break
            }
            
            for x := 0; x < max_tiles_x; x++ {
                if start_x + x >= level.width {
                    break
                }

                idx = ((start_y + y) * level.width) + start_x + x

                tile = C.vp_get(level.layer_bg, idx)
                game.tile_map.draw_tile(tile, 32 * x - rem_x, 32 * y - rem_y)

                tile = C.vp_get(level.layer_ic, idx)
                game.tile_map.draw_tile(tile, 32 * x - rem_x, 32 * y - rem_y)
            }
        }

        if delay == 0 {
            game.draw_player()
        }

        // draw foreground layer
        for y := 0; y < max_tiles_y; y++ {
            if start_y + y >= level.height {
                break
            }
            
            for x := 0; x < max_tiles_x; x++ {
                if start_x + x >= level.width {
                    break
                }

                idx = ((start_y + y) * level.width) + start_x + x

                // TODO: handle secret regions?
                tile = C.vp_get(level.layer_fg, idx)
                game.tile_map.draw_tile(tile, 32 * x - rem_x, 32 * y - rem_y)
            }
        }

        if delay > 0 {
            game.fillrect(0, 0, game.sdl.screen_width, game.sdl.screen_height, 0, 0, 0, byte(delay * f64(255)))
            delay -= game._delta
        } else {
            delay = 0

            if game.player_y > level.height * 32 {
                game.sounds.scream.play()
                game.player_x = init_x
                game.player_y = init_y
                delay = 1
            }

            // process input
            game.process_input()
            game.process_physics(game._delta * 100)
        }

        C.SDL_Delay(1)
        game.flipscreen()
        game.delta()
    }

    return done
}