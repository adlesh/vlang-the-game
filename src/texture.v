module main

struct TextureType {
pub:
mut:
    sdl_texture voidptr
    w int
    h int
}

fn (game &Game) load_texture(file string) &TextureType {
    mut ptexture := &TextureType{}

    filename := game.datadir + file
    println('loading image: ' + filename)
    surface := &SdlSurface(C.IMG_Load(filename.str))
    ptexture.sdl_texture = C.SDL_CreateTextureFromSurface(game.sdl.renderer, surface)

    if ptexture.sdl_texture == 0 {
        panic('Error loading texture!')
    }

    ptexture.w = surface.w
    ptexture.h = surface.h

    C.SDL_SetTextureBlendMode(ptexture.sdl_texture, C.SDL_BLENDMODE_BLEND)
    C.SDL_FreeSurface(surface)

    return ptexture
}

fn (tex &TextureType) free() {

}

fn (game &Game) texture_draw(ptexture &TextureType, _x, _y int) {
    src := C.SDL_Rect{
        x: 0 
        y: 0
        w: ptexture.w
        h: ptexture.h
    }

    dest := C.SDL_Rect{
        x: _x
        y: _y
        w: ptexture.w
        h: ptexture.h
    }

    C.SDL_RenderCopy(game.sdl.renderer, ptexture.sdl_texture, &src, &dest)
}

fn (game &Game) texture_draw_flip(ptexture &TextureType, _x, _y, flip int) {
    src := C.SDL_Rect{
        x: 0 
        y: 0
        w: ptexture.w
        h: ptexture.h
    }

    dest := C.SDL_Rect{
        x: _x
        y: _y
        w: ptexture.w
        h: ptexture.h
    }

    C.SDL_RenderCopyEx(game.sdl.renderer, ptexture.sdl_texture, &src, &dest, 0, 0, flip)
}

fn (game &Game) texture_draw_rotated(ptexture &TextureType, _x, _y, angle int) {
    src := C.SDL_Rect{
        x: 0 
        y: 0
        w: ptexture.w
        h: ptexture.h
    }

    dest := C.SDL_Rect{
        x: _x
        y: _y
        w: ptexture.w
        h: ptexture.h
    }

    C.SDL_RenderCopyEx(game.sdl.renderer, ptexture.sdl_texture, &src, &dest, f64(angle), 0, C.SDL_FLIP_NONE)
}

fn (game &Game) texture_draw_part(ptexture &TextureType, _tx, _ty, _x, _y, _w, _h int, alpha byte) {
    src := C.SDL_Rect{
        x: _tx
        y: _ty
        w: _w
        h: _h
    }

    dest := C.SDL_Rect{
        x: _x
        y: _y
        w: _w
        h: _h
    }

    C.SDL_RenderCopy(game.sdl.renderer, ptexture.sdl_texture, &src, &dest)
}

fn (game &Game) texture_draw_bg(ptexture &TextureType) {
    src := C.SDL_Rect{
        x: 0 
        y: 0
        w: ptexture.w
        h: ptexture.h
    }

    dest := C.SDL_Rect{
        x: 0
        y: 0
        w: game.sdl.screen_width
        h: game.sdl.screen_height
    }

    C.SDL_RenderCopy(game.sdl.renderer, ptexture.sdl_texture, &src, &dest)
}