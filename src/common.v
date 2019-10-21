module main

const (
    NULL = 0
)

[inline]
fn from_bytes(arr []byte) string {
    return tos(arr.data, arr.len)
}

fn (game mut Game) poll_quits() bool {
    for {
        if C.st_poll_event() {
            if C.st_event_type() == C.SDL_QUIT {
                game.quit = true
                return false
            } else if C.st_event_type() == C.SDL_KEYDOWN {
                key := C.st_event_sym()
                match key {
                    C.SDLK_ESCAPE => {
                        return true
                    }
                    C.SDLK_RETURN => {
                        return true
                    }
                }
            }
        } else {
            break
        }
    }
    return false
}

fn C.st_event_type() int

fn C.st_event_sym() int

fn C.vp_get(array voidptr, offset int) byte

fn C.fabs(num f64) f64