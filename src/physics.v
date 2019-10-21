module main

struct Physics {
mut:
    accel_x f64
    accel_y f64
    vel_x f64
    vel_y f64
    gravity f64
    handle_gravity bool
}

struct Vec2 {
    x f64
    y f64
}

fn (physics mut Physics) reset() {
    physics.accel_x = 0
    physics.accel_y = 0
    physics.vel_x = 0
    physics.vel_y = 0
    physics.handle_gravity = true
}

fn (physics mut Physics) set_gravity(gravity int) {
    physics.gravity = f64(gravity) / 100
}

fn (physics mut Physics) set_velocity(vel_x, vel_y f64) {
    physics.vel_x = vel_x
    physics.vel_y = vel_y
}

fn (physics mut Physics) bounce_x() {
    physics.vel_x = -physics.vel_x
}

fn (physics mut Physics) bounce_y() {
    physics.vel_y = -physics.vel_y
}

fn (physics mut Physics) handle(delta, _x, _y f64) Vec2 {
    mut res_x := f64(_x)
    mut res_y := f64(_y)

    if physics.handle_gravity {
        res_x += physics.vel_x * delta + physics.accel_x * delta * delta
        res_y += physics.vel_y * delta + (physics.accel_y + physics.gravity) * delta * delta
        
        physics.vel_x = physics.vel_x + (physics.accel_x * delta)
        physics.vel_y = physics.vel_y + ((physics.accel_y + physics.gravity) * delta)
    } else {
        res_x += physics.vel_x * delta + physics.accel_x * delta * delta
        res_y += physics.vel_y * delta + physics.accel_y * delta * delta
        
        physics.vel_x = physics.vel_x + (physics.accel_x * delta)
        physics.vel_y = physics.vel_y + (physics.accel_y * delta)
    }
    
    return Vec2{
        x: res_x
        y: res_y
    }
}