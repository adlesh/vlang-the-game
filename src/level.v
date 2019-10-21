module main

import os

struct LevelSubset {
pub:
mut:
    has_image bool
    name string
    description string
    directory string
    subset_image &TextureType
    game &Game
}

struct Level {
pub:
mut:
    width int
    height int
    name string
    background &TextureType
    music voidptr
    game &Game

    // V memory management sucks, this needs to be allocated/freed manually.
    layer_ic voidptr // interactive
    layer_fg voidptr // foreground
    layer_bg voidptr // background
}

fn (subset &LevelSubset) load_level(file string) ?Level {
    mut level := Level{}
    level.game = subset.game

    path := subset.directory + '/' + file
    
    if !os.file_exists(path) {
        return error('Cannot find level file!')
    }

    data := os.read_file(path) or {
        return error('Error loading level!')
    }

    sexp := parse_sexp(data)
    if !sexp.is(S_TYPE_LIST) || sexp._list.len <= 1 {
        return error('Invalid level file!')
    }

    list := sexp.get_list()
    if !list[0].is(S_TYPE_SYMBOL) || list[0].get_symbol() != 'level' {
        return error('Invalid level file!')
    }

    mut music := ''
    mut background := ''
    mut interactive_tiles := []SExpression
    mut foreground_tiles := []SExpression
    mut background_tiles := []SExpression

    for i := 1; i < list.len; i++ {
        if !list[i].is(S_TYPE_LIST) {
            continue
        }

        el := list[i].get_list()
        if el.len > 1 && el[0].is(S_TYPE_SYMBOL) {
            sym := el[0].get_symbol()

            match sym {
                'name' => {
                    if !el[1].is(S_TYPE_STRING) {
                        return error('"name" key should be a string!')
                    }
                    level.name = el[1].get_string()
                }
                'music' => {
                    if !el[1].is(S_TYPE_STRING) {
                        return error('"music" key should be a string!')
                    }
                    music = el[1].get_string()
                }
                'background' => {
                    if !el[1].is(S_TYPE_STRING) {
                        return error('"background" key should be a string!')
                    }
                    background = el[1].get_string()
                }
                'width' => {
                    if !el[1].is(S_TYPE_INTEGER) {
                        return error('"width" key should be an integer!')
                    }
                    level.width = el[1].get_int()
                }
                'height' => {
                    if !el[1].is(S_TYPE_INTEGER) {
                        return error('"height" key should be an integer!')
                    }
                    level.height = el[1].get_int()
                }
                'interactive-tm' => {
                    interactive_tiles = el
                }
                'foreground-tm' => {
                    foreground_tiles = el
                }
                'background-tm' => {
                    background_tiles = el
                }
            }
        }
    }

    expected_tiles := level.width * level.height
    if level.width < 1 || level.height < 1 {
        return error('Invalid level size: $level.width x $level.height')
    }

    mut tm_size := interactive_tiles.len - 1
    if tm_size != expected_tiles {
        println('warning: interactive tilemap size doesn\'t match level size ($expected_tiles != $tm_size)')
    }

    tm_size = foreground_tiles.len - 1
    if tm_size != expected_tiles {
        println('warning: foreground tilemap size doesn\'t match level size ($expected_tiles != $tm_size)')
    }

    tm_size = background_tiles.len - 1
    if tm_size != expected_tiles {
        println('warning: background tilemap size doesn\'t match level size ($expected_tiles != $tm_size)')
    }

    level.layer_ic = C.vp_malloc(u32(expected_tiles))
    if level.layer_ic == NULL {
        level.free()
        return error('failed to allocate memory for interactive layer!')
    }

    level.layer_fg = C.vp_malloc(u32(expected_tiles))
    if level.layer_fg == NULL {
        level.free()
        return error('failed to allocate memory for foreground layer!')
    }

    level.layer_bg = C.vp_malloc(u32(expected_tiles))
    if level.layer_bg == NULL {
        level.free()
        return error('failed to allocate memory for background layer!')
    }

    for i := 1; i < interactive_tiles.len; i++ {
        if i - 1 == expected_tiles {
            println('warning: hit memory bound in interactive tile map, not enough tiles specified?')
            break
        }

        if !interactive_tiles[i].is(S_TYPE_INTEGER) {
            println('warning: a non-int value found in interactive tile map, skipping it and trying to continue')
            continue
        }

        C.vp_put(level.layer_ic, i - 1, interactive_tiles[i].get_int())
    }

    for i := 1; i < foreground_tiles.len; i++ {
        if i - 1 == expected_tiles {
            println('warning: hit memory bound in foreground tile map, not enough tiles specified?')
            break
        }

        if !foreground_tiles[i].is(S_TYPE_INTEGER) {
            println('warning: a non-int value found in foreground tile map, skipping it and trying to continue')
            continue
        }

        C.vp_put(level.layer_fg, i - 1, foreground_tiles[i].get_int())
    }

    for i := 1; i < background_tiles.len; i++ {
        if i - 1 == expected_tiles {
            println('warning: hit memory bound in background tile map, not enough tiles specified?')
            break
        }

        if !background_tiles[i].is(S_TYPE_INTEGER) {
            println('warning: a non-int value found in foreground tile map, skipping it and trying to continue')
            continue
        }

        C.vp_put(level.layer_bg, i - 1, background_tiles[i].get_int())
    }

    if music != '' {
        if os.file_exists(subset.game.datadir + 'music/' + music) {
            music_ptr := subset.game.load_music(music)
            if music_ptr != NULL {
                level.music = music_ptr
            } else {
                println('warning: failed to load song: $music')
            }
        } else {
            println('warning: cannot find specified music in game resources: $music')
        }
    }

    if background != '' {
        if os.file_exists(subset.game.datadir + 'images/background/' + background) {
            bg_tex := subset.game.load_texture('images/background/' + background)
            level.background = bg_tex
        } else {
            println('warning: cannot find background image in game resources: $background')
        }
    }

    return level
}

fn (game mut Game) load_subsets() {
    files := os.ls(game.datadir + 'levels') or {
        println('No subsets present?')
        return
    }

    for dir in files {
        subset := game.load_subset(dir) or {
            println('cannot load $dir subset: $err')
            continue
        }

        println('Loaded subset $subset.name')

        game.level_subsets << subset
    }
}

fn (game mut Game) load_subset(name string) ?LevelSubset {
    mut subset := LevelSubset{}
    subset.game = game
    
    path := game.datadir + 'levels/' + name
    info_path := path + '/info.lisp'
    img_path := path + '/info.png'
    
    subset.directory = path

    if os.file_exists(path) && os.file_exists(info_path) {
        data := os.read_file(info_path) or {
            return error('error reading info file')
        }

        if os.file_exists(img_path) {
            subset.subset_image = game.load_texture('levels/' + name + '/info.png')
            subset.has_image = true
        }

        sexp := parse_sexp(data)
        if !sexp.is(S_TYPE_LIST) || sexp._list.len <= 1 {
            return error('invalid subset description file')
        }
        
        list := sexp.get_list()
        for idx, val in list {
            if idx == 0 && val.is(S_TYPE_SYMBOL) && val.get_symbol() == 'level-subset' {
                // lol
            } else if idx > 0 && val.is(S_TYPE_LIST) {
                if val._list.len > 1 && val._list[0].is(S_TYPE_SYMBOL) {
                    sym := val._list[0].get_symbol()
                    //println('s: $sym')

                    match sym {
                        'title' => {
                            if val._list[1].is(S_TYPE_STRING) {
                                subset.name = val._list[1].get_string()
                            }
                        }
                        'description' => {
                            if val._list[1].is(S_TYPE_STRING) {
                                subset.description = val._list[1].get_string()
                            }
                        }
                    }
                }
            } else {
                return error('invalid subset description file')
            }
        }
    } else {
        return error('no such file or directory?')
    }

    return subset
}

fn (level &Level) is_solid(x, y int) bool {
    if x < 0 || y < 0 || x > level.width || y > level.height {
        return false
    }

    id := int(C.vp_get(level.layer_ic, y * level.width + x))

    if id == 0 {
        return false
    } else if level.game.tile_map.tiles.has(id) {
        tile := &Tile(level.game.tile_map.tiles.get(id))
        return tile.solid()
    }

    return false
}

fn (subset mut LevelSubset) free() {
    if subset.has_image {
        subset.subset_image.free()
    }
}

fn (level mut Level) free() {
    if level.background != NULL {
        level.background.free()
        level.background = NULL
    }

    if level.layer_ic != NULL {
        C.vp_free(level.layer_ic)
        level.layer_ic = NULL
    }

    if level.layer_fg != NULL {
        C.vp_free(level.layer_fg)
        level.layer_fg = NULL
    }

    if level.layer_bg != NULL {
        C.vp_free(level.layer_bg)
        level.layer_bg = NULL
    }
}