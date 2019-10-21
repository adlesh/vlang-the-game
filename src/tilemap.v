module main

import os

struct TileMap {
pub:
mut:
    _game &Game
    textures &IntHashMap
    tiles &IntHashMap
}

struct Tile {
pub:
mut:
    id u16
    x_pos u16
    y_pos u16
    texture_id byte
    tile_type byte
}

const (
    TILE_TYPE_BACKGROUND = 0
    TILE_TYPE_SOLID = 1
)

[inline]
fn (tile &Tile) solid() bool {
    return tile.id != 0 && tile.tile_type == TILE_TYPE_SOLID
}

fn (game mut Game) tile_map_init() {
    mut tile_map := &TileMap{}
    tile_map.tiles = new_int_hash_map(256, 0.9)
    tile_map.textures = new_int_hash_map(16, 0.9)
    tile_map._game = game
    game.tile_map = tile_map

    println('Loading tile map...')
    tile_map.load()
}

fn (tile_map mut TileMap) load() {
    data := os.read_file(tile_map._game.datadir + 'images/tiles/tilemap.lisp') or {
        panic('error loading tile map!')
    }

    sexp := parse_sexp(data)
    if !sexp.is(S_TYPE_LIST) || sexp._list.len <= 1 {
        panic('invalid tile map file: $sexp._name')
    }
    
    list := sexp.get_list()
    for idx, val in list {
        if idx == 0 && list[0].is(S_TYPE_SYMBOL) && list[0].get_symbol() == 'tilemap' {
            // lol
        } else if idx > 0 && val.is(S_TYPE_LIST) {
            el := val.get_list()
            if el.len > 0 && el[0].is(S_TYPE_SYMBOL) {
                sym := el[0].get_symbol()
                if sym == 'tile' {
                    tile_map.read_tile(el)
                } else if sym == 'file' {
                    tile_map.load_texture(el)
                }
            }
        }
    }
}

fn (tile_map mut TileMap) load_texture(list []SExpression) {
    if list.len != 3 || !list[1].is(S_TYPE_INTEGER) || !list[2].is(S_TYPE_STRING) {
        return
    }

    id := list[1].get_int()
    path := 'images/tiles/' + list[2].get_string()

    if !os.file_exists(tile_map._game.datadir + path) {
        println('Error loading texture $id -> $path: file not found')
        return
    }

    tex := tile_map._game.load_texture(path)
    tile_map.textures.put(id, tex)
    println('loaded tilemap texture $id -> $path')
}

fn (tile_map mut TileMap) read_tile(list []SExpression) {
    if list.len != 6 {
        return
    }

    for i := 1; i < 6; i++ {
        if !list[i].is(S_TYPE_INTEGER) {
            return
        }
    }

    mut tile := &Tile{}
    tile.id = u16(list[1].get_int())
    tile.texture_id = byte(list[2].get_int())
    tile.x_pos = u16(list[3].get_int())
    tile.y_pos = u16(list[4].get_int())
    tile.tile_type = byte(list[5].get_int())

    tile_map.tiles.put(int(tile.id), tile)
    C.printf("t addr: 0x%016x\n", tile)
    println('tile $tile.id (tex: $tile.texture_id, x: $tile.x_pos, y: $tile.y_pos, type: $tile.tile_type)')
}

fn (tile_map &TileMap) draw_tile(id byte, x, y int) {
    if x < -32 || y < -32 || x > tile_map._game.sdl.screen_width || y > tile_map._game.sdl.screen_height || !tile_map.tiles.has(int(id)) {
        return
    }

    tile := &Tile(tile_map.tiles.get(int(id))) // assert ret != 0?
    //C.printf("t2 addr: 0x%016x\n", tile)
    
    //println('draw $tile.id (tex: $tile.texture_id, x: $tile.x_pos, y: $tile.y_pos, type: $tile.tile_type)')
    
    if !tile_map.textures.has(int(tile.texture_id)) {
        return
    }

    texture := &TextureType(tile_map.textures.get(int(tile.texture_id)))
    tile_map._game.texture_draw_part(texture, int(tile.x_pos) * 32, int(tile.y_pos) * 32, x, y, 32, 32, 255)
    //tile_map._game.fillrect(x, y, 32, 32, id & 0xf0, 0, id << 4 & 0xf0, 150)
}