module main

import math

[inline]
fn hm_next_power_of_two(_x i64) i64 {
    if _x == 0 {
        return 1
    }

    mut x := _x
    x--
    x |= x >> 1
    x |= x >> 2
    x |= x >> 4
    x |= x >> 8
    x |= x >> 16
    x |= x >> 32

    return x + 1
}

[inline]
fn hm_math_max(num_a, num_b int) int {
    if num_a > num_b {
        return num_a
    }

    return num_b
}

[inline]
fn hm_get_pot_array_size(expected int, factor f32) int {
    return hm_math_max(2, int(hm_next_power_of_two(i64(math.ceil(f32(expected) / factor)))))
}


[inline]
fn hm_phi_mix(x int) int {
    h := x * 0x9e3779b9
    return h ^ (h >> 16)
}

// imagine having to implement a hash map yourself just to store some tiles in an efficient way

struct IntHashMap {
mut:
    fill_factor f32
    threshold int
    size int
    mask u32

    keys []int
    values []voidptr
    used []bool
}

fn new_int_hash_map(size int, fill_factor f32) &IntHashMap {
    mut hash_map := &IntHashMap{}
    capacity := hm_get_pot_array_size(size, fill_factor)
    hash_map.mask = u32(capacity - 1)
    hash_map.fill_factor = fill_factor

    hash_map.keys = [0].repeat(capacity)
    hash_map.values = [voidptr(NULL)].repeat(capacity)
    hash_map.used = [false].repeat(capacity)   
    hash_map.threshold = int(f32(capacity) * f32(fill_factor))

    return hash_map
}

fn (hash_map IntHashMap) get(key int) voidptr {
    idx := hash_map.read_index(key)

    if idx != -1 {
        return hash_map.values[idx]
    } else {
        return NULL
    }
}

[inline]
fn (hash_map IntHashMap) has(key int) bool {
    return hash_map.read_index(key) != -1
}


fn (hash_map mut IntHashMap) put(key int, value voidptr) {
    mut idx := hash_map.put_index(key)
    if idx < 0 {
        println('no space, rehashing')
        hash_map.rehash(hash_map.keys.len * 2)
        idx = hash_map.put_index(key)
    }

    //prev := hash_map.values[idx]
    if !hash_map.used[idx] {
        hash_map.keys[idx] = key
        hash_map.values[idx] = value
        hash_map.used[idx] = true
        hash_map.size++

        if hash_map.size >= hash_map.threshold {
            println('hit hashmap threshold, rehashing')
            hash_map.rehash(hash_map.keys.len * 2)
        }
    } else {
        hash_map.values[idx] = value
    }

    //return prev
}

[inline]
fn (hash_map IntHashMap) size() int {
    return hash_map.size
}

fn (hash_map mut IntHashMap) remove(key int) voidptr {
    idx := hash_map.read_index(key)

    if idx == -1 {
        return NULL
    }

    res := hash_map.values[idx]
    hash_map.size--
    hash_map.shift_keys(idx)
    return res
}

[inline]
fn (hash_map IntHashMap) start_index(key int) int {
    return int(u32(hm_phi_mix(key)) & hash_map.mask)
}

[inline]
fn (hash_map IntHashMap) next_index(key int) int {
    return int(u32(key + 1) & hash_map.mask)
}

[inline]
fn (hash_map IntHashMap) read_index(key int) int {
    mut idx := hash_map.start_index(key)

    if !hash_map.used[idx] {
        return -1
    }

    if hash_map.keys[idx] == key && hash_map.used[idx] {
        return idx
    }

    start_idx := idx
    for {
        idx = hash_map.next_index(idx)

        if idx == start_idx || !hash_map.used[idx] {
            return -1
        }

        if hash_map.keys[idx] == key && hash_map.used[idx] {
            return idx
        }
    }
    
    return -1
}

[inline]
fn (hash_map IntHashMap) put_index(key int) int {
    read_idx := hash_map.read_index(key)
    if read_idx >= 0 {
        return read_idx
    }

    start_idx := hash_map.start_index(key)
    mut idx := start_idx

    for {
        if !hash_map.used[idx] {
            break
        }

        idx = hash_map.next_index(key)
        if idx == start_idx {
            return -1
        }
    }

    return idx
}

fn (hash_map mut IntHashMap) rehash(new_capacity int) {
    hash_map.threshold = int(f32(new_capacity) * f32(hash_map.fill_factor))
    hash_map.mask = u32(new_capacity - 1)

    old_capacity := hash_map.keys.len
    old_keys := hash_map.keys
    old_values := hash_map.values
    old_used := hash_map.used
    println('rehash $old_capacity -> $new_capacity')
    
    hash_map.keys = [0].repeat(new_capacity)
    hash_map.values = [voidptr(NULL)].repeat(new_capacity)
    hash_map.used = [false].repeat(new_capacity)   
    hash_map.size = 0

    for i := old_capacity; i > 0; i-- {
        if old_used[i] {
            hash_map.put(old_keys[i], old_values[i])
        }
    }
}

fn (hash_map mut IntHashMap) shift_keys(_pos int) int {
    mut last := 0
    mut k := 0
    mut pos := _pos

    for {
        last = pos
        pos = hash_map.next_index(pos)

        for {
            k = hash_map.keys[pos]
            if !hash_map.used[pos] {
                hash_map.keys[last] = 0
                hash_map.values[last] = voidptr(NULL)
                hash_map.used[last] = false

                return last
            }

            slot := hash_map.start_index(k)

            if last <= pos {
                if last >= slot || slot > pos {
                    break
                }
            } else {
                if last >= slot && slot > pos {
                    break
                }
            }

            pos = hash_map.next_index(pos)
        }

        hash_map.keys[last] = k
        hash_map.values[last] = hash_map.values[pos]
        hash_map.used[last] = hash_map.used[pos]
    }

    panic('should not happen!')
}