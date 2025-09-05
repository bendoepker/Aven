#ifndef TOKENIZER_H
#define TOKENIZER_H

#include <vector>
#include <string>

typedef enum {
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
    NumericLiteral,
    IntegerLiteral,
    FloatLiteral,
    HexLiteral,
    BinaryLiteral,
    InvalidLiteral,

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
    Symbol,
    EndOfFile,
} TokenType;

typedef struct _Token {
    TokenType type;
    std::string data;
    size_t line;
    size_t column;
} Token;

std::vector<Token> tokenize(const std::string path);
std::string token_type_name(const TokenType type);

#endif //TOKENIZER_H
