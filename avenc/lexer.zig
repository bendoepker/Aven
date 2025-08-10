const std = @import("std");
const print = std.debug.print;
const alc = std.heap.page_allocator;
const alloc = alc.alloc;

fn streql(str1: [] u8, str2: [] const u8) bool {
    if(str1.len != str2.len)
        return false;
    for(0..str1.len) |i| {
        if(str1[i] != str2[i])
            return false;
    }
    return true;
}

const TokenType = enum {
    // Primitives
    Int8,
    Int16,
    Int32,
    Int64,
    UInt8,
    UInt16,
    UInt32,
    UInt64,
    Float32,
    Float64,
    Unsigned,
    UncheckedInt8,
    UncheckedInt16,
    UncheckedInt32,
    UncheckedInt64,
    True,
    False,
    Voidptr,
    Bool,

    // Keywords
    If,
    Else,
    ElseIf,
    For,
    While,
    Class,
    Struct,
    Typealias,
    Fn,
    Fnptr,
    Let,
    Import,
    Enable,
    Disable,
    Trait,
    Self,

    // Literals
    StringLiteral,
    IntegerLiteral,
    FloatLiteral,

    // Symbols
    OpenCurly,
    CloseCurly,
    OpenBracket,
    CloseBracket,
    DoubleOpenBracket,
    DoubleCloseBracket,
    OpenParen,
    CloseParen,
    Colon,
    Semicolon,
    Comma,
    Period,

    // Operators
    Plus,
    Minus,
    Asterisk, // Could be a pointer, a multiplication sign, or part of a multiline comment
    Divide,  // Could be a division sign, part of a single line comment, or part of a multiline comment
    Equal,

    PlusEqual,
    MinusEqual,
    MultiplyEqual,
    DivideEqual,

    Increment,
    Decrement,

    BitwiseAnd,
    BitwiseOr,
    BitwiseXor,
    BitwiseNot,
    BitwiseLeftShift,
    BitwiseRightShift,

    BitwiseAndEqual,
    BitwiseOrEqual,
    BitwiseXorEqual,
    BitwiseLeftShiftEqual,
    BitwiseRightShiftEqual,

    LogicalLessThan,
    LogicalGreaterThan,
    LogicalEqualTo,
    LogicalLessThanEqualTo,
    LogicalGreaterThanEqualTo,

    LogicalNot,
    LogicalAnd,
    LogicalOr,

    // Misc
    Unknown
};

const Token = struct {
    type: TokenType,
    data: ?[]u8,
};

pub fn tokinize(file: std.fs.File) !std.ArrayList(Token) {
    const data = try file.readToEndAlloc(alc, 8192);
    if(data.len == 0)  {
        file.close();
        return error.EmptyFile;
    }

    var tokens = std.ArrayList(Token).init(alc);
    var start: usize = 0;
    var in_string = false;
    var in_word = false;
    var in_sl_comment = false;
    var in_ml_comment = false;
    var ml_comment_beginning: usize = 0;
    var string_car_ret: usize = 0;
    var string_newline: usize = 0;
    var skip = 0;

    // Main loop, iterating over each character and constructing an array of tokens
    //TODO: Multi line comments, multiple character symbols
    for(data, 0..) |char, pos| {
        if(skip > 0) {
            skip -= 1;
            continue;
        } else if(in_sl_comment) {
            if(char != '\n')
                continue;
            in_sl_comment = false;
            start = pos + 1;
            continue;
        } else if(in_string) {
            switch(char) {
                '\r' => string_car_ret += 1,
                '\n' => string_newline += 1,
                '"' => {
                    try tokens.append(.{.type = TokenType.StringLiteral, .data = data[start+1..pos]});
                    in_string = false;
                    start = pos + 1;
                    continue;
                },
                else => continue
            }
        } else {
            switch(char) {
                // Begin String Literal
                '"' => {
                    if(in_word) {
                        in_word = false;
                        try tokens.append(tokenize_word(data[start..pos]));
                    }
                    start = pos; // Start will hold the position of the beginning quotation mark and pos will hold the position of the ending quotation mark
                    in_string = true;
                },
                // Divide tokens on whitespace
                ' ', '\t', '\r', '\n' => {
                    if(in_word) {
                        in_word = false;
                        try tokens.append(tokenize_word(data[start..pos]));
                        start = pos + 1;
                        continue;
                    }
                    if(pos == start) {
                        start = pos + 1;
                        continue;
                    }
                },
                // Symbols
                '+', '-', '/', '*', '&', '|', '^', '=', '~', '<', '>', '!', '(', ')', '{', '}', '[', ']', ':', ';', ',', '@' => {
                    //TODO: Separate these out and do lookahead for double / triple character symbols
                    if(in_word) {
                        in_word = false;
                        try tokens.append(tokenize_word(data[start..pos]));
                    }
                    try tokens.append(tokenize_symbol(char));
                    start = pos + 1;
                    continue;
                },
                '.' => {
                    if(data[start] >= 48 and data[start] <= 57) {
                        continue;
                    } else {
                        if(in_word) {
                            in_word = false;
                            try tokens.append(tokenize_word(data[start..pos]));
                        }
                        try tokens.append(tokenize_symbol(char));
                        start = pos + 1;
                    }
                },
                else => {
                    in_word = true;
                }
            }
        }
    }
    return tokens;
}

fn tokenize_symbol(symbol: u8) Token {
    switch(symbol) {
        // Symbols
        '{' => return Token { .type = TokenType.OpenCurly, .data = null },
        '}' => return Token { .type = TokenType.CloseCurly, .data = null },
        '[' => return Token { .type = TokenType.OpenBracket, .data = null },
        ']' => return Token { .type = TokenType.CloseBracket, .data = null },
        '(' => return Token { .type = TokenType.OpenParen, .data = null },
        ')' => return Token { .type = TokenType.CloseParen, .data = null },
        ':' => return Token { .type = TokenType.Colon, .data = null },
        ';' => return Token { .type = TokenType.Semicolon, .data = null },
        '.' => return Token { .type = TokenType.Period, .data = null },
        ',' => return Token { .type = TokenType.Comma, .data = null },

        '+' => return Token { .type = TokenType.Plus, .data = null },
        '-' => return Token { .type = TokenType.Minus, .data = null },
        '*' => return Token { .type = TokenType.Asterisk, .data = null },
        '/' => return Token { .type = TokenType.Divide, .data = null },
        '=' => return Token { .type = TokenType.Equal, .data = null },

        '&' => return Token { .type = TokenType.BitwiseAnd, .data = null },
        '|' => return Token { .type = TokenType.BitwiseOr, .data = null },
        '^' => return Token { .type = TokenType.BitwiseXor, .data = null },
        '~' => return Token { .type = TokenType.BitwiseNot, .data = null },

        '<' => return Token { .type = TokenType.LogicalLessThan, .data = null },
        '>' => return Token { .type = TokenType.LogicalGreaterThan, .data = null },
        '!' => return Token { .type = TokenType.LogicalNot, .data = null },
        else => return Token { .type = TokenType.Unknown, .data = null }
    }
}

fn tokenize_word(word: [] u8) Token {
    // Integer types
    if(streql(word, "i8")) {
        return Token { .type = TokenType.Int8, .data = null };
    } else if(streql(word, "i16")) {
        return Token { .type = TokenType.Int16, .data = null };
    } else if(streql(word, "i32")) {
        return Token { .type = TokenType.Int32, .data = null };
    } else if(streql(word, "i64")) {
        return Token { .type = TokenType.Int64, .data = null };
    } else if(streql(word, "u8")) {
        return Token { .type = TokenType.UInt8, .data = null };
    } else if(streql(word, "u16")) {
        return Token { .type = TokenType.UInt16, .data = null };
    } else if(streql(word, "u32")) {
        return Token { .type = TokenType.UInt32, .data = null };
    } else if(streql(word, "u64")) {
        return Token { .type = TokenType.UInt64, .data = null };
    }
    // Floating point types
    else if(streql(word, "f32") or streql(word, "float")) {
        return Token { .type = TokenType.Float32, .data = null };
    } else if(streql(word, "f64") or streql(word, "double")) {
        return Token { .type = TokenType.Float64, .data = null };
    }
    // C style integers
    else if(streql(word, "unsinged")) {
        return Token { .type = TokenType.Unsigned, .data = null };
    } else if(streql(word, "char")) {
        return Token { .type = TokenType.UncheckedInt8, .data = null };
    } else if(streql(word, "short")) {
        return Token { .type = TokenType.UncheckedInt16, .data = null };
    } else if(streql(word, "int")) {
        return Token { .type = TokenType.UncheckedInt32, .data = null };
    } else if(streql(word, "long")) {
        return Token { .type = TokenType.UncheckedInt64, .data = null };
    }
    // Booleans
    else if(streql(word, "bool")) {
        return Token { .type = TokenType.Bool, .data = null };
    } else if(streql(word, "true")) {
        return Token { .type = TokenType.True, .data = null };
    } else if(streql(word, "false")) {
        return Token { .type = TokenType.False, .data = null };
    }

    else if(streql(word, "if")) {
        return Token { .type = TokenType.If, .data = null };
    } else if(streql(word, "else")) {
        return Token { .type = TokenType.Else, .data = null };
    }

    else if(streql(word, "for")) {
        return Token { .type = TokenType.For, .data = null };
    } else if(streql(word, "while")) {
        return Token { .type = TokenType.While, .data = null };
    } else if(streql(word, "class")) {
        return Token { .type = TokenType.Class, .data = null };
    } else if(streql(word, "struct")) {
        return Token { .type = TokenType.Struct, .data = null };
    } else if(streql(word, "typealias")) {
        return Token { .type = TokenType.Typealias, .data = null };
    } else if(streql(word, "fn")) {
        return Token { .type = TokenType.Fn, .data = null };
    } else if(streql(word, "fnptr")) {
        return Token { .type = TokenType.Fnptr, .data = null };
    } else if(streql(word, "let")) {
        return Token { .type = TokenType.Let, .data = null };
    } else if(streql(word, "import")) {
        return Token { .type = TokenType.Import, .data = null };
    } else if(streql(word, "enable")) {
        return Token { .type = TokenType.Enable, .data = null };
    } else if(streql(word, "disable")) {
        return Token { .type = TokenType.Disable, .data = null };
    } else if(streql(word, "trait")) {
        return Token { .type = TokenType.Trait, .data = null };
    } else if(streql(word, "self")) {
        return Token { .type = TokenType.Self, .data = null };
    }
    // Void pointer
    else if(streql(word, "voidptr")) {
        return Token { .type = TokenType.Voidptr, .data = null };
    }

    // Logical Operators
    else if(streql(word, "or")) {
        return Token { .type = TokenType.LogicalOr, .data = null };
    } else if(streql(word, "and")) {
        return Token { .type = TokenType.LogicalAnd, .data = null };
    }

    // Base return type
    else {
        return Token { .type = TokenType.Unknown, .data = word };
    }
}
