module main

struct TimerType {
pub:
mut:
    time u32
    period u32
    st_timer bool
}

fn create_timer(_st_timer bool) TimerType {
    mut timer := TimerType{}
    
    timer.time = u32(0)
    timer.period = u32(0)
    timer.st_timer = _st_timer

    return timer
}

fn (timer mut TimerType) start(_period u32) {
    timer.time = timer.get_ticks()
    timer.period = _period
}

fn (timer mut TimerType) stop() {
    timer.period = u32(0)
    timer.time = u32(0)
}

fn (timer &TimerType) get_ticks() u32 {
    if timer.st_timer {
        return C.st_get_ticks()
    } else {
        return C.get_ticks()
    }
}

fn (timer mut TimerType) check() bool {
    if ((timer.time != u32(0)) && (timer.time + timer.period > timer.get_ticks())) {
        return true
    } else {
        timer.time = u32(0)
        return false
    }
}

fn (game mut Game) delta() f64 {
    tick := C.get_ticks()
    game._delta = f64(tick - game.last_tick) / f64(1000)
    game.last_tick = tick
    return game._delta
}

fn C.st_get_ticks() u32

fn C.get_ticks() u32