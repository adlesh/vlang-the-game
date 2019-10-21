module main

struct MenuItem {
pub:
mut:
    item_type int
    text string
    toggled bool
}

struct Menu {
pub:
mut:
    game &Game
    pos_x int
    pos_y int 
    alpha byte 

    items []MenuItem
    last_menu &Menu

    arrange_left int
    active_item int
}

const (
    OPT_INACTIVE = 0
    OPT_ACTION = 1
    OPT_GOTO = 2
    OPT_TOGGLE = 3
    OPT_BACK = 4
)

const (
    MENU_ACTION_NONE = -1
    MENU_ACTION_UP = 0
    MENU_ACTION_DOWN = 1
    MENU_ACTION_LEFT = 2
    MENU_ACTION_RIGHT = 3
    MENU_ACTION_HIT = 4
    MENU_ACTION_INPUT = 5
    MENU_ACTION_REMOVE = 6
)

fn (_game &Game) new_menu() &Menu {
    mut menu := &Menu{}
    menu.game = _game
    menu.pos_x = _game.sdl.screen_width / 2
    menu.pos_y = _game.sdl.screen_height / 2

    return menu
}

fn (game mut Game) menu_set_current(menu &Menu) {
    if game.current_menu != menu {
        last_menu := game.current_menu
        game.current_menu = menu
        game.current_menu.last_menu = last_menu
    }
}

fn (game mut Game) menu_process_current() {
    if game.current_menu != 0 {
        game.current_menu.action()
        game.current_menu.draw()
    }

    game.menu_action = MENU_ACTION_NONE
}

fn (game mut Game) menu_sdl_event() {
    _type := C.st_event_type()
    match _type {
        C.SDL_KEYDOWN => {
            key := C.st_event_sym()
            match key {
                C.SDLK_UP => {
                    game.menu_action = MENU_ACTION_UP
                }
                C.SDLK_DOWN => {
                    game.menu_action = MENU_ACTION_DOWN
                }
                C.SDLK_LEFT => {
                    game.menu_action = MENU_ACTION_LEFT
                }
                C.SDLK_RIGHT => {
                    game.menu_action = MENU_ACTION_RIGHT
                }
                C.SDLK_RETURN => {
                    game.menu_action = MENU_ACTION_HIT
                }
            }
        }
        C.SDL_MOUSEBUTTONDOWN => {
            game.menu_sdl_event_mouse(true)
        }
        C.SDL_MOUSEMOTION => {
            game.menu_sdl_event_mouse(false)
        }
    }
}

fn (game mut Game) menu_sdl_event_mouse(click bool) {
    x := int(C.st_event_motion(0) / game.sdl.scale_x)
    y := int(C.st_event_motion(1) / game.sdl.scale_y)
    mut current_menu := game.current_menu

    if (x > current_menu.pos_x - current_menu.width() / 2 &&
        x < current_menu.pos_x + current_menu.width() / 2 &&
        y > current_menu.pos_y - current_menu.height() / 2 &&
        y < current_menu.pos_y + current_menu.height() / 2) {
        current_menu.active_item = (y - (current_menu.pos_y - current_menu.height() / 2)) / 36
        if click {
            game.menu_action = MENU_ACTION_HIT
        }
    }
}

fn (menu mut Menu) add_action(_text string) {
    menu.items << MenuItem{
        text: _text
        item_type: OPT_ACTION
    }
}

fn (menu mut Menu) draw_item(index int, item MenuItem) {
    x_pos := menu.pos_x
    y_pos := menu.pos_y + 36 * index - menu.height() / 2 + 18
    mut font := menu.game.font_white

    if index == menu.active_item {
        font = menu.game.font_gold
    }

    match item.item_type {
        OPT_INACTIVE => {
            menu.game.font_black.draw_align(item.text, x_pos, y_pos, ALIGN_CENTER | ALIGN_MIDDLE, 255)
        }
        OPT_ACTION => {
            font.draw_align(item.text, x_pos, y_pos, ALIGN_CENTER | ALIGN_MIDDLE, 255)
        }
    }
}

fn (menu &Menu) width() int {
    mut menu_width := 0
    mut w := 0

    for val in menu.items {
        w = val.text.len

        if w > menu_width {
            menu_width = w
        }
    }

    return menu_width * 16 + 64
}

fn (menu &Menu) height() int {
    return menu.items.len * 36
}

fn (menu mut Menu) action() {
    if menu.items.len == 0 {
        return
    }

    match menu.game.menu_action {
        MENU_ACTION_UP => {
            if menu.active_item > 0 {
                menu.active_item -= 1
            } else {
                menu.active_item = menu.items.len - 1
            }
        }
        MENU_ACTION_DOWN => {
            if menu.active_item < menu.items.len - 1 {
                menu.active_item += 1
            } else {
                menu.active_item = 0
            }
        }
        MENU_ACTION_HIT => {
            mut item := &menu.items[menu.active_item]
            if item.item_type == OPT_ACTION {
                item.toggled = true
            }
        }
    }
}

fn (menu mut Menu) check() int {
    if menu.items.len != 0 {
        mut item := &menu.items[menu.active_item]
        if (item.item_type == OPT_ACTION) && item.toggled {
            item.toggled = false
            menu.game.show_menu = false
            return menu.active_item
        }
    }

    return -1
}

fn (menu mut Menu) draw() {
    menu_width := menu.width()
    menu_height := menu.height()
    alpha := 255

    menu.game.fillrect(menu.pos_x - menu_width / 2,
             menu.pos_y - menu_height / 2 - 10,
             menu_width, menu_height + 20, 0, 0, 0, alpha * 100 / 255)

    for idx, item in menu.items {
        menu.draw_item(idx, item)
    }
}