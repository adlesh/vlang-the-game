module main

struct Font {
pub:
mut:
    game &Game
    texture &TextureType
    char_width int
    char_height int
}

fn (_game mut Game) load_font(name string, width int, height int) &Font {
    mut font := &Font{}
    font.game = _game
    font.char_width = width
    font.char_height = height
    font.texture = _game.load_texture('images/gui/letters-' + name + '.png')
    
    return font
}

const (
    ALIGN_LEFT = 0
    ALIGN_CENTER = 1
    ALIGN_RIGHT = 2

    ALIGN_TOP = 0
    ALIGN_MIDDLE = 4
    ALIGN_BOTTOM = 8
)

fn (font mut Font) draw_align(text string, _x int, _y int, align int, alpha byte) {
    mut x := _x
    mut y := _y

    if (align & ALIGN_CENTER) != 0 {
        x += -(text.len * font.char_width / 2)
    } else if (align & ALIGN_RIGHT) != 0 {
        x += -(text.len * font.char_width)
    }

    if (align & ALIGN_MIDDLE) != 0 {
        y -= font.char_height / 2
    } else if (align & ALIGN_BOTTOM) != 0 {
        y -= font.char_height
    }
    
    font.draw(text, x, y, alpha)
}

fn (font mut Font) draw(text string, _x int, _y int, alpha byte) {
    mut x := _x 
    mut y := _y
    
    for i := 0; i < text.len; i++ {
        c := int(text.str[i])
        //font.game.fillrect(x, y, font.char_width, font.char_height, 0, chr, 0, 128)
        if c >= 0x41 /* A */ && c <= 0x5a /* Z */ {
            font.game.texture_draw_part(font.texture, (c - 0x41) * font.char_width, 0, x, y, font.char_width, font.char_height, alpha)
            x += font.char_width
        } else if c >= 0x61 /* a */ && c <= 0x7a /* z */ {
            font.game.texture_draw_part(font.texture, (c - 0x61) * font.char_width, font.char_height, x, y, font.char_width, font.char_height, alpha)
            x += font.char_width
        } else if c >= 0x21 /* ! */ && c <= 0x39 /* 9 */ {
            font.game.texture_draw_part(font.texture, (c - 0x21) * font.char_width, font.char_height * 2, x, y, font.char_width, font.char_height, alpha)
            x += font.char_width
        } else if c == 0x3f /* ? */ {
            font.game.texture_draw_part(font.texture, 25 * font.char_width, 2 * font.char_height, x, y, font.char_width, font.char_height, alpha)
            x += font.char_width
        } else if c == 0x0a /* \n */ {
            x = _x
            y += font.char_height
        } else {
            x += font.char_width
        }
    }
}