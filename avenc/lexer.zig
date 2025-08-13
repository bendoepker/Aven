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
    True,
    False,
    Void,
    Voidptr,
    Bool,

    // Keywords
    If,
    Else,
    ElseIf,
    For,
    While,
    Enum,
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
    CharacterLiteral,
    StringLiteral,
    IntegerLiteral,
    FloatLiteral,

    // Symbols
    OpenCurly,
    CloseCurly,
    OpenBracket,
    CloseBracket,
    OpenTraitDecorator,
    CloseTraitDecorator,
    OpenParen,
    CloseParen,
    Colon,
    Semicolon,
    Comma,
    Period,
    TargetSymbol,

    // Operators
    Plus,
    Minus,
    Asterisk, // Could be a pointer, a multiplication sign, or part of a multiline comment
    Divide,  // Could be a division sign, part of a single line comment, or part of a multiline comment
    Modulo,
    Equal,

    PlusEqual,
    MinusEqual,
    MultiplyEqual,
    DivideEqual,
    ModuloEqual,

    Increment,
    Decrement,

    Ampersand, // Could be a pointer or bitwise and
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
    var in_char = false;
    var in_word = false;
    var in_sl_comment = false;
    var in_ml_comment = false;
    var ml_comment_beginning: usize = 0;
    var string_car_ret: usize = 0;
    var string_newline: usize = 0;
    var skip: usize = 0;

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
                    try tokens.append(.{.type = .StringLiteral, .data = data[start+1..pos]});
                    in_string = false;
                    start = pos + 1;
                    continue;
                },
                else => continue
            }
        } else if(in_char) {
            switch(char) {
                '\'' => {
                    try tokens.append(.{ .type = .CharacterLiteral, .data = data[start+1..pos]});
                    in_char = false;
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
                '+' => {
                    if(in_word) {
                        in_word = false;
                        try tokens.append(tokenize_word(data[start..pos]));
                    }
                    try tokens.append(Token { .type = .Plus, .data = null });
                    // Check for another plus sign
                    if(data.len - 1 > pos) {
                        if(data[pos + 1] == '+') {
                            tokens.items.ptr[tokens.items.len - 1].type = .Increment;
                            skip = 1;
                            start = pos + 2;
                        } else if(data[pos + 1] == '=') {
                            tokens.items.ptr[tokens.items.len - 1].type = .PlusEqual;
                            skip = 1;
                            start = pos + 2;
                        } else {
                            start = pos + 1;
                        }
                    }
                    continue;
                },
                '-' => {
                    if(in_word) {
                        in_word = false;
                        try tokens.append(tokenize_word(data[start..pos]));
                    }
                    try tokens.append(Token { .type = .Minus, .data = null });
                    // Check for another minus sign
                    if(data.len - 1 > pos) {
                        if(data[pos + 1] == '-') {
                            tokens.items.ptr[tokens.items.len - 1].type = .Decrement;
                            skip = 1;
                            start = pos + 2;
                        } else if(data[pos + 1] == '=') {
                            tokens.items.ptr[tokens.items.len - 1].type = .MinusEqual;
                            skip = 1;
                            start = pos + 2;
                        } else {
                            start = pos + 1;
                        }
                    }
                    continue;
                },
                '%' => {
                    if(in_word) {
                        in_word = false;
                        try tokens.append(tokenize_word(data[start..pos]));
                    }
                    try tokens.append(Token { .type = .Modulo, .data = null });
                    // Check for another minus sign
                    if(data.len - 1 > pos) {
                        if(data[pos + 1] == '=') {
                            tokens.items.ptr[tokens.items.len - 1].type = .ModuloEqual;
                            skip = 1;
                            start = pos + 2;
                        } else {
                            start = pos + 1;
                        }
                    }
                    continue;
                },
                '/' => {
                    if(in_word) {
                        in_word = false;
                        try tokens.append(tokenize_word(data[start..pos]));
                    }
                    try tokens.append(Token { .type = .Divide, .data = null });
                    // Check for an asterisk or another forward slash
                    if(data.len - 1 > pos) {
                        if(data[pos + 1] == '*') {
                            _ = tokens.pop();
                            skip = 1;
                            start = pos + 2;
                            in_ml_comment = true;
                            ml_comment_beginning = tokens.items.len;
                        } else if(data[pos + 1] == '/') {
                            _ = tokens.pop();
                            skip = 1;
                            start = pos + 2;
                            in_sl_comment = true;
                        } else {
                            start = pos + 1;
                        }
                    }
                    continue;
                },
                '*' => {
                    if(in_word) {
                        in_word = false;
                        try tokens.append(tokenize_word(data[start..pos]));
                    }
                    try tokens.append(Token { .type = .Divide, .data = null });
                    // Check for an equal sign or forward slash
                    if(data.len - 1 > pos) {
                        if(data[pos + 1] == '=') {
                            tokens.items.ptr[tokens.items.len - 1].type = .MultiplyEqual;
                            skip = 1;
                            start = pos + 2;
                        } else if(data[pos + 1] == '/') {
                            _ = tokens.pop();
                            skip = 1;
                            start = pos + 2;
                            for(ml_comment_beginning..tokens.items.len) |_| {
                                _ = tokens.pop();
                            }
                        } else {
                            start = pos + 1;
                        }
                    }
                    continue;
                },
                '&' => {
                    if(in_word) {
                        in_word = false;
                        try tokens.append(tokenize_word(data[start..pos]));
                    }
                    try tokens.append(Token { .type = .Ampersand, .data = null });
                    // Check for an equal sign after the ampersand
                    if(data.len - 1 > pos) {
                        if(data[pos + 1] == '=') {
                            tokens.items.ptr[tokens.items.len - 1].type = .BitwiseAndEqual;
                            skip = 1;
                            start = pos + 2;
                        } else {
                            start = pos + 1;
                        }
                    }
                    continue;
                },
                '|' => {
                    if(in_word) {
                        in_word = false;
                        try tokens.append(tokenize_word(data[start..pos]));
                    }
                    try tokens.append(Token { .type = .BitwiseOr, .data = null });
                    // Check for an equal sign after the pipe
                    if(data.len - 1 > pos) {
                        if(data[pos + 1] == '=') {
                            tokens.items.ptr[tokens.items.len - 1].type = .BitwiseOrEqual;
                            skip = 1;
                            start = pos + 2;
                        } else {
                            start = pos + 1;
                        }
                    }
                    continue;
                },
                '^' => {
                    if(in_word) {
                        in_word = false;
                        try tokens.append(tokenize_word(data[start..pos]));
                    }
                    try tokens.append(Token { .type = .BitwiseXor, .data = null });
                    // Check for an equal sign after the carrot
                    if(data.len - 1 > pos) {
                        if(data[pos + 1] == '=') {
                            tokens.items.ptr[tokens.items.len - 1].type = .BitwiseXorEqual;
                            skip = 1;
                            start = pos + 2;
                        } else {
                            start = pos + 1;
                        }
                    }
                    continue;
                },
                '=' => {
                    if(in_word) {
                        in_word = false;
                        try tokens.append(tokenize_word(data[start..pos]));
                    }
                    try tokens.append(Token { .type = .Equal, .data = null });
                    // Check for another equal sign
                    if(data.len - 1 > pos) {
                        if(data[pos + 1] == '=') {
                            tokens.items.ptr[tokens.items.len - 1].type = .LogicalEqualTo;
                            skip = 1;
                            start = pos + 2;
                        } else {
                            start = pos + 1;
                        }
                    }
                    continue;
                },
                '~' => {
                    if(in_word) {
                        in_word = false;
                        try tokens.append(tokenize_word(data[start..pos]));
                    }
                    try tokens.append(Token { .type = .BitwiseNot, .data = null });
                    start = pos + 1;
                    continue;
                },
                '<' => {
                    // Could be: <, <=, <<, <<=
                    if(in_word) {
                        in_word = false;
                        try tokens.append(tokenize_word(data[start..pos]));
                    }
                    try tokens.append(Token { .type = .LogicalLessThan, .data = null });
                    // Check for another left carrot or equal sign
                    if(data.len - 1 > pos) {
                        if(data[pos + 1] == '=') {
                            tokens.items.ptr[tokens.items.len - 1].type = .LogicalLessThanEqualTo;
                            skip = 1;
                            start = pos + 2;
                        } else if(data[pos + 1] == '<') {
                            tokens.items.ptr[tokens.items.len - 1].type = .BitwiseLeftShift;
                            if(data.len - 1 > pos + 1) {
                                if(data[pos + 2] == '=') {
                                    tokens.items.ptr[tokens.items.len - 1].type = .BitwiseLeftShiftEqual;
                                    skip = 2;
                                    start = pos + 3;
                                } else {
                                    skip = 1;
                                    start = pos + 2;
                                }
                            } else {
                                start = pos + 1;
                            }
                        } else {
                            start = pos + 1;
                        }
                    }
                    continue;
                },
                '>' => {
                    // Could be: >, >=, >>, >>=
                    if(in_word) {
                        in_word = false;
                        try tokens.append(tokenize_word(data[start..pos]));
                    }
                    try tokens.append(Token { .type = .LogicalGreaterThan, .data = null });
                    // Check for another left carrot or equal sign
                    if(data.len - 1 > pos) {
                        if(data[pos + 1] == '=') {
                            tokens.items.ptr[tokens.items.len - 1].type = .LogicalGreaterThanEqualTo;
                            skip = 1;
                            start = pos + 2;
                        } else if(data[pos + 1] == '>') {
                            tokens.items.ptr[tokens.items.len - 1].type = .BitwiseRightShift;
                            if(data.len - 1 > pos + 1) {
                                if(data[pos + 2] == '=') {
                                    tokens.items.ptr[tokens.items.len - 1].type = .BitwiseRightShiftEqual;
                                    skip = 2;
                                    start = pos + 3;
                                } else {
                                    skip = 1;
                                    start = pos + 2;
                                }
                            } else {
                                start = pos + 1;
                            }
                        } else {
                            start = pos + 1;
                        }
                    }
                    continue;
                },
                '!' => {
                    if(in_word) {
                        in_word = false;
                        try tokens.append(tokenize_word(data[start..pos]));
                    }
                    try tokens.append(Token { .type = .LogicalNot, .data = null });
                    start = pos + 1;
                    continue;
                },
                '(' => {
                    if(in_word) {
                        in_word = false;
                        try tokens.append(tokenize_word(data[start..pos]));
                    }
                    try tokens.append(Token { .type = .OpenParen, .data = null });
                    start = pos + 1;
                    continue;
                },
                ')' => {
                    if(in_word) {
                        in_word = false;
                        try tokens.append(tokenize_word(data[start..pos]));
                    }
                    try tokens.append(Token { .type = .CloseParen, .data = null });
                    start = pos + 1;
                    continue;
                },
                '{' => {
                    if(in_word) {
                        in_word = false;
                        try tokens.append(tokenize_word(data[start..pos]));
                    }
                    try tokens.append(Token { .type = .OpenCurly, .data = null });
                    start = pos + 1;
                    continue;
                },
                '}' => {
                    if(in_word) {
                        in_word = false;
                        try tokens.append(tokenize_word(data[start..pos]));
                    }
                    try tokens.append(Token { .type = .CloseCurly, .data = null });
                    start = pos + 1;
                    continue;
                },
                '[' => {
                    if(in_word) {
                        in_word = false;
                        try tokens.append(tokenize_word(data[start..pos]));
                    }
                    try tokens.append(Token { .type = .OpenBracket, .data = null });
                    // Check for another plus sign
                    if(data.len - 1 > pos) {
                        if(data[pos + 1] == '[') {
                            tokens.items.ptr[tokens.items.len - 1].type = .OpenTraitDecorator;
                            skip = 1;
                            start = pos + 2;
                        } else {
                            start = pos + 1;
                        }
                    }
                    continue;
                },
                ']' => {
                    if(in_word) {
                        in_word = false;
                        try tokens.append(tokenize_word(data[start..pos]));
                    }
                    try tokens.append(Token { .type = .CloseBracket, .data = null });
                    // Check for another plus sign
                    if(data.len - 1 > pos) {
                        if(data[pos + 1] == ']') {
                            tokens.items.ptr[tokens.items.len - 1].type = .CloseTraitDecorator;
                            skip = 1;
                            start = pos + 2;
                        } else {
                            start = pos + 1;
                        }
                    }
                    continue;
                },
                ':' => {
                    if(in_word) {
                        in_word = false;
                        try tokens.append(tokenize_word(data[start..pos]));
                    }
                    try tokens.append(Token { .type = .Colon, .data = null });
                    start = pos + 1;
                    continue;
                },
                ';' => {
                    if(in_word) {
                        in_word = false;
                        try tokens.append(tokenize_word(data[start..pos]));
                    }
                    try tokens.append(Token { .type =.Semicolon, .data = null });
                    start = pos + 1;
                    continue;
                },
                ',' => {
                    if(in_word) {
                        in_word = false;
                        try tokens.append(tokenize_word(data[start..pos]));
                    }
                    try tokens.append(Token { .type =.Comma, .data = null });
                    start = pos + 1;
                    continue;
                },
                '@' => {
                    if(in_word) {
                        in_word = false;
                        try tokens.append(tokenize_word(data[start..pos]));
                    }
                    try tokens.append(Token { .type =.TargetSymbol, .data = null });
                    start = pos + 1;
                    continue;
                },
                '\'' => {
                    if(in_word) {
                        in_word = false;
                        try tokens.append(tokenize_word(data[start..pos]));
                    }
                    in_char = true;
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
                        try tokens.append(Token {.type = .Period, .data = null });
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

fn tokenize_word(word: [] u8) Token {
    // Integer types
    if(streql(word, "i8")) {
        return Token { .type = .Int8, .data = null };
    } else if(streql(word, "i16")) {
        return Token { .type = .Int16, .data = null };
    } else if(streql(word, "i32")) {
        return Token { .type = .Int32, .data = null };
    } else if(streql(word, "i64")) {
        return Token { .type = .Int64, .data = null };
    } else if(streql(word, "u8")) {
        return Token { .type = .UInt8, .data = null };
    } else if(streql(word, "u16")) {
        return Token { .type = .UInt16, .data = null };
    } else if(streql(word, "u32")) {
        return Token { .type = .UInt32, .data = null };
    } else if(streql(word, "u64")) {
        return Token { .type = .UInt64, .data = null };
    }
    // Floating point types
    else if(streql(word, "f32")) {
        return Token { .type = .Float32, .data = null };
    } else if(streql(word, "f64")) {
        return Token { .type = .Float64, .data = null };
    }
    // Booleans
    else if(streql(word, "bool")) {
        return Token { .type = .Bool, .data = null };
    } else if(streql(word, "true")) {
        return Token { .type = .True, .data = null };
    } else if(streql(word, "false")) {
        return Token { .type = .False, .data = null };
    }

    else if(streql(word, "if")) {
        return Token { .type = .If, .data = null };
    } else if(streql(word, "else")) {
        return Token { .type = .Else, .data = null };
    }

    else if(streql(word, "for")) {
        return Token { .type = .For, .data = null };
    } else if(streql(word, "while")) {
        return Token { .type = .While, .data = null };
    } else if(streql(word, "enum")) {
        return Token { .type = .Enum, .data = null };
    } else if(streql(word, "struct")) {
        return Token { .type = .Struct, .data = null };
    } else if(streql(word, "typealias")) {
        return Token { .type = .Typealias, .data = null };
    } else if(streql(word, "fn")) {
        return Token { .type = .Fn, .data = null };
    } else if(streql(word, "fnptr")) {
        return Token { .type = .Fnptr, .data = null };
    } else if(streql(word, "let")) {
        return Token { .type = .Let, .data = null };
    } else if(streql(word, "import")) {
        return Token { .type = .Import, .data = null };
    } else if(streql(word, "enable")) {
        return Token { .type = .Enable, .data = null };
    } else if(streql(word, "disable")) {
        return Token { .type = .Disable, .data = null };
    } else if(streql(word, "trait")) {
        return Token { .type = .Trait, .data = null };
    } else if(streql(word, "self")) {
        return Token { .type = .Self, .data = null };
    }
    // Void types
    else if(streql(word, "voidptr")) {
        return Token { .type = .Voidptr, .data = null };
    } else if(streql(word, "void")) {
        return Token { .type = .Void, .data = null };
    }

    // Logical Operators
    else if(streql(word, "or")) {
        return Token { .type = .LogicalOr, .data = null };
    } else if(streql(word, "and")) {
        return Token { .type = .LogicalAnd, .data = null };
    }

    // Base return type
    else {
        return Token { .type = .Unknown, .data = word };
    }
}
