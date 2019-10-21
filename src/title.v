module main

struct TitleState {
pub:
mut:
    initialized bool
    had_intro bool

    angle int
    timer u32
    menu_background &TextureType
    default_subset &TextureType
    valex_head &TextureType
    menu &Menu
}

fn (game mut Game) title_init() {
    mut title := &game.title_state
    title.initialized = true
    
    title.menu_background = game.load_texture('images/title/title.png')
    title.default_subset = game.load_texture('images/title/default-subset.png')
    title.valex_head = game.load_texture('images/valex.png')
    title.menu = game.new_menu()
    title.menu.add_action('New Game')
    title.menu.add_action('Options')
    title.menu.add_action('Credits')
    title.menu.add_action('Quit')
}

fn (game mut Game) title_bg() {
    mut title := &game.title_state

    title.angle = (title.angle + int(title.timer - C.get_ticks())) % 3600
    title.timer = C.get_ticks()

    game.clearscreen(0, 0, 0)
    game.texture_draw_bg(title.menu_background)
    game.texture_draw_rotated(title.valex_head, int(f32(game.sdl.screen_width) * 0.8), 120, title.angle / 10)
}

fn (game mut Game) title_load_failed(_error string) bool {
    mut done := false
    mut frame := 0
    mut alpha := 0
    ef_x := 500
    mut ef_y := game.sdl.screen_height

    for {
        if done || game.quit {
            break
        }


        for {
            if C.st_poll_event() {
                if C.st_event_type() == C.SDL_QUIT {
                    game.quit = true
                    break
                } else if C.st_event_type() == C.SDL_KEYDOWN {
                    key := C.st_event_sym()
                    if key == C.SDLK_ESCAPE || key == C.SDLK_RETURN {
                        done = true
                    }
                }
            } else {
                break
            }
        }

        game.title_bg()

        game.fillrect((game.sdl.screen_width - ef_x) / 2, (game.sdl.screen_height - ef_y) / 2, ef_x, ef_y, 0, 0, 0, 100)
        if alpha == 255 {
            game.font_red.draw_align('Failed to load level', game.sdl.screen_width / 2, game.sdl.screen_height / 2 - 20, ALIGN_CENTER | ALIGN_MIDDLE, 255)
            game.font_white.draw_align(_error, game.sdl.screen_width / 2, game.sdl.screen_height / 2 + 20, ALIGN_CENTER | ALIGN_MIDDLE, 255)
        }

        if ef_y > 150 { ef_y-- }
        if alpha < 255 { alpha++ }

        C.SDL_Delay(1)
        game.draw_cursor()
        game.flipscreen()
        frame++
    }
    
    return done
}

fn (game mut Game) prepare_game(subset &LevelSubset) bool {
    level := subset.load_level('level2.lisp') or {
        println(err)
        return game.title_load_failed(err)
    }

    println('enter game from level $level.name')
    
    game.level = 1
    game.lives = 3
    game.score = 0
    game.current_level = &level
    game.current_subset = subset
    game.physics.set_gravity(10)
    
    return game.game_loop()
}

fn (game mut Game) title_level_select() bool {
    mut title := &game.title_state
    mut done := false
    mut current := 0
    mut frame := 0
    mut alpha := 0
    mut ef_x := title.menu.width()
    mut ef_y := title.menu.height()

    for !(done || game.quit) {
        for C.st_poll_event() {
            if C.st_event_type() == C.SDL_QUIT {
                game.quit = true
                break
            } else if C.st_event_type() == C.SDL_KEYDOWN {
                key := C.st_event_sym()
                match key {
                    C.SDLK_ESCAPE => {
                        done = true
                    }
                    C.SDLK_LEFT => {
                        if current > 0 {
                            current--
                        }
                    }
                    C.SDLK_RIGHT => {
                        if current < game.level_subsets.len {
                            current++
                        }
                    }
                    C.SDLK_RETURN => {
                        if current != game.level_subsets.len {
                            subset := &LevelSubset(C.array_get(game.level_subsets, current))
                            return game.prepare_game(subset)
                        }
                    }
                }
            }
        }

        game.title_bg()
        game.fillrect((game.sdl.screen_width - ef_x) / 2, (game.sdl.screen_height - ef_y) / 2, ef_x, ef_y, 0, 0, 0, 100)
        if alpha == 255 {
            if current == game.level_subsets.len {
                game.font_red.draw_align('Chapter ? - ???', game.sdl.screen_width / 2, 30, ALIGN_CENTER | ALIGN_TOP, 255)
                game.font_white.draw_align('Coming soon!', game.sdl.screen_width / 2, game.sdl.screen_height / 2, ALIGN_CENTER | ALIGN_MIDDLE, 255)
            } else {
                subset := &LevelSubset(C.array_get(game.level_subsets, current))
                game.font_red.draw_align(subset.name, game.sdl.screen_width / 2, 30, ALIGN_CENTER | ALIGN_TOP, 255)
                game.font_white.draw_align(subset.description, game.sdl.screen_width / 2, game.sdl.screen_height - 30, ALIGN_CENTER | ALIGN_BOTTOM, 255)
                
                if subset.has_image {
                    game.texture_draw(subset.subset_image, (game.sdl.screen_width - subset.subset_image.w) / 2, 100)
                } else {
                    game.texture_draw(title.default_subset, (game.sdl.screen_width - title.default_subset.w) / 2, 100)
                }
            }
        }

        if ef_x < 500 { ef_x++ }
        if ef_y < game.sdl.screen_height { ef_y++ }
        if alpha < 255 { alpha++ }

        C.SDL_Delay(1)
        game.draw_cursor()
        game.flipscreen()
        frame++
    }

    return done
}

fn (game mut Game) title() bool {
    if !game.title_state.initialized {
        game.title_init()
    }

    mut done := false
    mut frame := 0
    mut title := &game.title_state
    title.timer = C.get_ticks()
    
    if game.get_current_music() != MusicType.MENU_MUSIC {
        game.set_current_music(MusicType.MENU_MUSIC)
        game.play_current_music()
    }

    game.current_subset = NULL
    game.current_level = NULL
    //game.clearscreen(0, 0, 0)
    //game.flipscreen()
    game.menu_set_current(title.menu)

    for {
        if C.st_poll_event() {
            if C.st_event_type() == C.SDL_QUIT {
                game.quit = true
                break
            }
        } else {
            break
        }
    }

    for {
        if done || game.quit {
            break
        }

        for {
            if C.st_poll_event() {
                if C.st_event_type() == C.SDL_QUIT {
                    game.quit = true
                    break
                } else if title.had_intro {
                    game.menu_sdl_event()
                }
            } else {
                break
            }
        }

        game.title_bg()

        if title.had_intro && game.show_menu {
            game.menu_process_current()
        }

        if game.current_menu == title.menu {
            match title.menu.check() {
                0 => {
                    done = game.title_level_select()
                }
                1 => {
                    done = true
                }
                3 => {
                    game.quit = true
                }
            }
        }

        if !title.had_intro && frame < 255 {
            game.fillrect(0, 0, game.sdl.screen_width, game.sdl.screen_height, 0, 0, 0, 255 - frame)
            C.SDL_Delay(10)
        } else {
            game.show_menu = true
            title.had_intro = true
        }

        C.SDL_Delay(1)
        game.draw_cursor()
        game.flipscreen()
        frame++
    }

    return game.quit
}