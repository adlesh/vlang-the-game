module main

const (
    EOF = -1
    S_TYPE_ERR = -2
    S_TYPE_NIL = 0
    S_TYPE_LIST = 1
    S_TYPE_SYMBOL = 2
    S_TYPE_INTEGER = 3
    S_TYPE_STRING = 4
    S_TYPE_BOOL = 5
)

struct SExpression {
pub:
mut:
    _type int
    _name string
    _value int
    _bool_value bool
    _list []SExpression
}

struct SExpressionParser {
mut:
    pointer int
    data string
}

fn parse_sexp(_data string) SExpression {
    mut exp := SExpression{}
    mut parser := &SExpressionParser{
        pointer: 0
        data: _data
    }

    if !parser.parse(mut exp)  {
        exp.make_err('Unknown parsing error!')
    }

    free(parser.data.str)
    free(parser)

    return exp
}

fn (exp &SExpression) is(t int) bool {
    if t == S_TYPE_BOOL {
        return exp._type == S_TYPE_SYMBOL && exp._name.len == 2 && exp._name.str[0] == `#` && (exp._name.str[1] == `t` || exp._name.str[1] == `f`)
    } else {
        return exp._type == t
    }
}

fn (exp &SExpression) get_list() []SExpression {
    if exp._type != S_TYPE_LIST {
        panic('s-exp is not a list!')
    }

    return exp._list
}

fn (exp &SExpression) get_int() int {
    if exp._type != S_TYPE_INTEGER {
        panic('s-exp is not an integer!')
    }

    return exp._value
}

fn (exp &SExpression) get_string() string {
    if exp._type != S_TYPE_STRING {
        panic('s-exp is not a string!')
    }

    return exp._name
}

fn (exp &SExpression) get_symbol() string {
    if exp._type != S_TYPE_SYMBOL {
        panic('s-exp is not a symbol!')
    }

    return exp._name
}

fn (exp &SExpression) get_bool() bool {
    if !exp.is(S_TYPE_BOOL) {
        panic('s-exp is not a boolean!')
    }

    return exp._name == '#t'
}

fn (exp mut SExpression) make_err(err string) {
    if exp._type != S_TYPE_ERR {
        exp._type = S_TYPE_ERR
        exp._name = err
    }
}

fn (exp mut SExpression) copy_err(err string, nexp &SExpression) {
    if nexp._type == S_TYPE_ERR {
        exp._type = S_TYPE_ERR
        exp._name = nexp._name
    } else {
        exp._type = S_TYPE_ERR
        exp._name = err
    }
}

const (
    SC_TAB = 0x09 // \t
    SC_NEWLINE = 0x0a // \n
    SC_CARRIAGE = 0x0d // \r
    SC_WHITESPACE = ` `
    SC_LEFT_PAREN = `(`
    SC_RIGHT_PAREN = `)`
    SC_SEMICOLON = `;`
    SC_MINUS = `-`
    SC_QUOTE = `"`
    SC_BACKSLASH = 0x5c // \\
)

fn (parser mut SExpressionParser) next_char() byte {
    if parser.data.len == parser.pointer {
        return -1
    } else {
        parser.pointer += 1
        return parser.data.str[parser.pointer - 1]
    }
}

fn (parser mut SExpressionParser) skip_comment() {
    mut c := byte(0)
    for {
        c = parser.next_char()
        if c == SC_NEWLINE || c == SC_CARRIAGE || c == EOF {
            break
        }
    }
}

[inline]
fn is_end(c byte) bool {
    return c == SC_NEWLINE || c == SC_CARRIAGE || c == SC_TAB || c == SC_WHITESPACE || c == SC_SEMICOLON || c == SC_RIGHT_PAREN
}

[inline]
fn is_sym_num(c byte) bool {
    return c == `-` || c == `_` || c == `$` || c == `#` || c.is_digit() || c.is_letter()
}

fn (parser mut SExpressionParser) read_number_or_symbol(exp mut SExpression) bool {
    parser.pointer -= 1
    start := parser.pointer
    mut sign := false
    mut is_number := true
    mut c := parser.next_char()
    mut bytes := []byte
    
    for {
        if is_number {
            if c == SC_MINUS {
                sign = true
            } else if c.is_digit() {
                exp._value = (exp._value * 10) + int(c - `0`)
            } else {
                if is_end(c) {
                    exp._type = S_TYPE_INTEGER
                    parser.pointer -= 1
                    if sign {
                        exp._value *= -1
                    }
                    return true
                } else {
                    exp._type = S_TYPE_NIL
                    exp._value = 0
                    parser.pointer = start
                    is_number = false
                }
            }
        } else {
            if is_end(c) {
                exp._type = S_TYPE_SYMBOL
                exp._name = from_bytes(bytes)
                parser.pointer -= 1
                return true
            } else if is_sym_num(c) {
                bytes << c
            } else {
                exp.make_err('invalid character: $c')
                return false
            }
        }

        c = parser.next_char()
    }

    return false
}

fn (parser mut SExpressionParser) read_list(exp mut SExpression) bool {
    mut c := parser.next_char()

    for {
        mut nexp := SExpression{}

        if c == EOF {
            exp.make_err('unexpected EOF')
            return false
        } else if c == SC_RIGHT_PAREN {
            exp._type = S_TYPE_LIST
            return true
        } else if c == SC_LEFT_PAREN {
            if !parser.read_list(mut nexp) {
                exp.copy_err('cannot parse list', nexp)
                return false
            } else {
                exp._list << nexp
            }
        } else if c == SC_QUOTE {
            if !parser.read_string(mut nexp) {
                exp.copy_err('cannot parse string', nexp)
                return false
            } else {
                exp._list << nexp
            }
        } else if is_sym_num(c) {
            if !parser.read_number_or_symbol(mut nexp) {
                exp.copy_err('cannot parse number or symbol', nexp)
                return false
            } else {
                exp._list << nexp
            }
        } else if c == SC_TAB || c == SC_CARRIAGE || c == SC_NEWLINE || c == SC_WHITESPACE {
            // skip
        } else {
            exp.make_err('unexpected token: $c')
            return false
        }

        c = parser.next_char()
    }
    return true
}

fn (parser mut SExpressionParser) read_string(exp mut SExpression) bool {
    mut c := parser.next_char()
    mut bytes := []byte

    for {
        if c == EOF {
            exp.make_err('unexpected EOF')
            return false
        } else if c == SC_BACKSLASH {
            c = parser.next_char()

            match c {
                EOF => {
                    exp.make_err('unexpected EOF')
                    return false
                }
                `n` => {
                    bytes << SC_NEWLINE
                }
                `r` => {
                    bytes << SC_CARRIAGE
                }
                `t` => {
                    bytes << SC_TAB
                }
                SC_QUOTE => {
                    bytes << SC_QUOTE
                }
                else => {
                    exp.make_err('invalid escape')
                    return false
                }
            }
        } else if c == SC_QUOTE {
            exp._type = S_TYPE_STRING
            exp._name = from_bytes(bytes)
            return true
        } else {
            bytes << c
        }

        c = parser.next_char()
    }

    return false
}

fn (parser mut SExpressionParser) parse(exp mut SExpression) bool {
    mut parsed := false
    mut c := parser.next_char()

    for {
        parsed = false
        match c {
            SC_SEMICOLON => {
                parsed = true
                parser.skip_comment()
            }
            SC_QUOTE => {
                return parser.read_string(mut exp)
            }
            SC_LEFT_PAREN => {
                return parser.read_list(mut exp)
            }
            EOF => {
                return true
            }
        }

        if is_sym_num(c) { 
            return parser.read_number_or_symbol(mut exp)
        } else if c == SC_TAB || c == SC_CARRIAGE || c == SC_NEWLINE || c == SC_WHITESPACE { // no-ops
            parsed = true
        } 

        if !parsed {
            exp._type = S_TYPE_ERR
            exp._name = 'Invalid token: $c'
            return false
        }

        c = parser.next_char()
    }

    return parsed
}