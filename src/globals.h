#ifdef __GNUC__
#define likely(x) __builtin_expect ((x), 1)
#define unlikely(x) __builtin_expect ((x), 0)
#else
#define likely(x) x
#define unlikely(x) x
#endif

#ifdef _WIN32
//int wmain(int _argc, wchar_t* w_rgv[]) { // if u want debug
int WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nShowCmd) {
    char* argv[] = {0}; // shitty wrapper for main()
    return main(0, argv);
}
#endif

struct timer_type {
    unsigned int period;
    unsigned int time;

    bool st_timer;
};

static SDL_Event event;
static unsigned int st_pause_ticks, st_pause_count;

static inline bool st_poll_event() {
    return SDL_PollEvent(&event);
}

static unsigned int st_get_ticks() {
    if (st_pause_count != 0)
        return SDL_GetTicks() - st_pause_ticks - SDL_GetTicks() + st_pause_count;
    else
        return SDL_GetTicks() - st_pause_ticks;
}

static inline u32 get_ticks() {
    return (u32) SDL_GetTicks();
}

static inline char vp_get(voidptr array, int offset) {
    if (unlikely(array != NULL)) {
        return ((char*) array)[offset];
    } else {
        return 0;
    }
}

static inline void vp_put(voidptr array, int offset, char data) {
    if (unlikely(array != NULL)) {
        ((char*)array)[offset] = data;
    }
}

static inline char* vp_malloc(u32 size) {
    return (char*) malloc((size_t) size);
}

static inline void vp_free(voidptr array) {
    if (unlikely(array != NULL)) {
        free(array);
    }
}

static inline unsigned int st_event_type() {
    return event.type;
}

static inline unsigned int st_event_sym() {
    return event.key.keysym.sym;
}

static float st_event_motion(int axis) {
    if (axis == 0) {
        return event.motion.x;
    } else if (axis == 1) {
        return event.motion.y;
    }

    return 0.0f;
}

static void st_pause_ticks_init() {
    st_pause_ticks = 0;
    st_pause_count = 0;
}

static void st_pause_ticks_start() {
    st_pause_count = SDL_GetTicks();
}

static void st_pause_ticks_stop() {
    st_pause_ticks += SDL_GetTicks() - st_pause_count;
    st_pause_count = 0;
}

static unsigned int timer_get_ticks(struct timer_type *ptimer) {
    if (ptimer->st_timer) {
        return st_get_ticks();
    } else {
        return SDL_GetTicks();
    }
}

static int timer_started(struct timer_type *ptimer) {
    if (ptimer->time != 0)
        return true;
    else
        return false;
}

static int timer_get_left(struct timer_type *ptimer) {
    return (ptimer->period - (timer_get_ticks(ptimer) - ptimer->time));
}

static int timer_get_gone(struct timer_type *ptimer) {
    return (timer_get_ticks(ptimer) - ptimer->time);
}