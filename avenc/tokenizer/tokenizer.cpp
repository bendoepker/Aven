#include "tokenizer.h"
#include <util/util.h>

Token make_token(TokenType type, std::string data, size_t line) {
    return Token { .type = type, .data = data, .line = line};
}

bool streql(std::string str1, const std::string&& str2) {
    if(str1.length() != str2.length())
        return false;
    for(int i = 0, imax = str1.length(); i < imax; i++) {
        if(str1[i] != str2[i])
            return false;
    }
    return true;
}

std::string sanitize_str_lit(std::string str) {
    //for(size_t pos = 0, length = str.length(); pos < length; pos++) {
    //    switch(auto c = str[pos])
    //    if(length - 1 > pos) {
    //    }
    //}
    return {};
}

std::string sanitize_char_lit(std::string chr) {
    //TODO: this may need to have a different return type (probably)
    return {};
}

void sanitize_num_lit(Token& num) {
    TokenType type = IntegerLiteral;
    int decimal = 0;
    for(char c : num.data) {
        if(c == '.') decimal++;
    }
    if(decimal > 1) {
        num.type = InvalidLiteral;
        return;
    } else if (decimal == 0) {
        num.type = IntegerLiteral;
    } else {
        num.type = FloatLiteral;
    }

    if(num.type == IntegerLiteral && num.data.length() > 2) {
        if(num.data[0] == '0') {
            if(num.data[1] == 'x' || num.data[0] == 'X') {
                num.type = HexLiteral;
            } else if(num.data[1] == 'b' || num.data[1] == 'B') {
                num.type = BinaryLiteral;
            }
        }
    }

    //TODO: Make sure that the characters conform to their literal types

    num.type = type;
    return;
}

Token tokenize_word(std::string word, size_t line) {
    if(streql(word, "i8")) {
        return make_token(Int8, {}, line);
    } else if(streql(word, "i16")) {
        return make_token(Int16, {}, line);
    } else if(streql(word, "i32")) {
        return make_token(Int32, {}, line);
    } else if(streql(word, "i64")) {
        return make_token(Int64, {}, line);
    } else if(streql(word, "u8")) {
        return make_token(UInt8, {}, line);
    } else if(streql(word, "u16")) {
        return make_token(UInt16, {}, line);
    } else if(streql(word, "u32")) {
        return make_token(UInt32, {}, line);
    } else if(streql(word, "u64")) {
        return make_token(UInt64, {}, line);
    }
    // Floating point types
    else if(streql(word, "f32")) {
        return make_token(Float32, {}, line);
    } else if(streql(word, "f64")) {
        return make_token(Float64, {}, line);
    }
    // Booleans
    else if(streql(word, "bool")) {
        return make_token(Bool, {}, line);
    } else if(streql(word, "true")) {
        return make_token(True, {}, line);
    } else if(streql(word, "false")) {
        return make_token(False, {}, line);
    }

    else if(streql(word, "if")) {
        return make_token(If, {}, line);
    } else if(streql(word, "else")) {
        return make_token(Else, {}, line);
    }

    else if(streql(word, "for")) {
        return make_token(For, {}, line);
    } else if(streql(word, "while")) {
        return make_token(While, {}, line);
    } else if(streql(word, "enum")) {
        return make_token(Enum, {}, line);
    } else if(streql(word, "struct")) {
        return make_token(Struct, {}, line);
    } else if(streql(word, "typealias")) {
        return make_token(Typealias, {}, line);
    } else if(streql(word, "fn")) {
        return make_token(Fn, {}, line);
    } else if(streql(word, "fnptr")) {
        return make_token(Fnptr, {}, line);
    } else if(streql(word, "let")) {
        return make_token(Let, {}, line);
    } else if(streql(word, "import")) {
        return make_token(Import, {}, line);
    } else if(streql(word, "enable")) {
        return make_token(Enable, {}, line);
    } else if(streql(word, "disable")) {
        return make_token(Disable, {}, line);
    } else if(streql(word, "trait")) {
        return make_token(Trait, {}, line);
    } else if(streql(word, "self")) {
        return make_token(Self, {}, line);
    }
    // Void types
    else if(streql(word, "voidptr")) {
        return make_token(Voidptr, {}, line);
    } else if(streql(word, "void")) {
        return make_token(Void, {}, line);
    }

    // Logical Operators
    else if(streql(word, "or")) {
        return make_token(LogicalOr, {}, line);
    } else if(streql(word, "and")) {
        return make_token(LogicalAnd, {}, line);
    }

    // Numeric Literals
    else if((word[0] >= '0' && word[0] <= '9') || word[0] == '.') {
        Token tmp = make_token(NumericLiteral, word, line);
        sanitize_num_lit(tmp);
        return tmp;
    }

    // Base return type
    else {
        return make_token(Symbol, word, line);
    }
}

std::vector<Token> tokenize(const std::string path) {
    std::vector<Token> tokens;
    int failed = 0;
    std::string src = read_entire_file(std::move(path), failed);
    if(failed)
        return {};

    /* Begin Tokenizing */
    size_t length = src.length();
    if(length == 0)
        return {};

    size_t start = 0;
    size_t ml_comment_beg = 0;
    size_t line = 0;
    size_t skip = 0;
    bool in_string = false;
    bool in_char = false;
    bool in_word = false;
    bool in_sl_comment = false;
    bool in_ml_comment = false;
    char c = 0;

    for(size_t pos = 0; pos < length; pos++) {
        c = src[pos];
        if(c == '\n') ++line;
        if(skip) {
            --skip;
            continue;
        } else if(in_sl_comment) {
            if(c != '\n')
                continue;
            in_sl_comment = false;
            start = pos + 1;
            continue;
        } else if(in_string) {
            if(c == '\"') {
                tokens.push_back(make_token(StringLiteral, std::string(&src[start + 1], pos - start - 1), line));
            } else {
                continue;
            }
        } else if(in_char) {
            if(c == '\'') {
                tokens.push_back(make_token(CharacterLiteral, std::string(&src[start + 1], pos - start - 1), line));
            }
        } else {
            switch(c) {
                case '\"':
                    if(in_word) {
                        in_word = false;
                        tokens.push_back(tokenize_word(std::string(&src[start], pos - start), line));
                    }
                    start = pos;
                    in_string = true;
                    continue;
                case ' ':
                case '\t':
                case '\r':
                case '\n':
                    if(in_word) {
                        in_word = false;
                        tokens.push_back(tokenize_word(std::string(&src[start], pos - start), line));
                        start = pos + 1;
                        continue;
                    }
                    if(pos == start) {
                        start = pos + 1;
                        continue;
                    }
                    continue;
                case '+':
                    if(in_word) {
                        in_word = false;
                        tokens.push_back(tokenize_word(std::string(&src[start], pos - start), line));
                    }
                    tokens.push_back(Token {.type = Plus, .line = line });
                    if(length - 1 > pos) {
                        if(src[pos + 1] == '+') {
                            tokens[tokens.size() - 1].type = Increment;
                            skip = 1;
                            start = pos + 2;
                        } else if(src[pos + 1] == '=') {
                            tokens[tokens.size() - 1].type = PlusEqual;
                            skip = 1;
                            start = pos + 2;
                        } else {
                            start = pos + 1;
                        }
                    }
                    continue;
                case '-':
                    if(in_word) {
                        in_word = false;
                        tokens.push_back(tokenize_word(std::string(&src[start], pos - start), line));
                    }
                    tokens.push_back(Token {.type = Minus, .line = line });
                    if(length - 1 > pos) {
                        if(src[pos + 1] == '-') {
                            tokens[tokens.size() - 1].type = Decrement;
                            skip = 1;
                            start = pos + 2;
                        } else if(src[pos + 1] == '=') {
                            tokens[tokens.size() - 1].type = MinusEqual;
                            skip = 1;
                            start = pos + 2;
                        } else {
                            start = pos + 1;
                        }
                    }
                    continue;
                case '%':
                    if(in_word) {
                        in_word = false;
                        tokens.push_back(tokenize_word(std::string(&src[start], pos - start), line));
                    }
                    tokens.push_back(Token {.type = Modulo, .line = line });
                    if(length - 1 > pos) {
                        if(src[pos + 1] == '=') {
                            tokens[tokens.size() - 1].type = ModuloEqual;
                            skip = 1;
                            start = pos + 2;
                        } else {
                            start = pos + 1;
                        }
                    }
                    continue;
                case '/':
                    if(in_word) {
                        in_word = false;
                        tokens.push_back(tokenize_word(std::string(&src[start], pos - start), line));
                    }
                    tokens.push_back(Token { .type = Divide, .line = line });
                    if(length -1 > pos) {
                        if(src[pos + 1] == '*') {
                            tokens.pop_back();
                            skip = 1;
                            start = pos + 2;
                            in_ml_comment = true;
                            ml_comment_beg = tokens.size();
                        } else if(src[pos + 1] == '/') {
                            tokens.pop_back();
                            skip = 1;
                            start = pos + 2;
                            in_sl_comment = true;
                        } else if(src[pos + 1] == '=') {
                            tokens[tokens.size() - 1].type = DivideEqual;
                            skip = 1;
                            start = pos + 2;
                        } else {
                            start = pos + 1;
                        }
                    }
                    continue;
                case '*':
                    if(in_word) {
                        in_word = false;
                        tokens.push_back(tokenize_word(std::string(&src[start], pos - start), line));
                    }
                    tokens.push_back(Token { .type = Asterisk, .line = line });
                    if(length - 1 > pos) {
                        if(src[pos + 1] == '=') {
                            tokens[tokens.size() - 1].type = MultiplyEqual;
                            skip = 1;
                            start = pos + 2;
                        } else if(src[pos + 1] == '/') {
                            skip = 1;
                            start = pos + 2;
                            for(auto i = ml_comment_beg; i < tokens.size(); i++) {
                                tokens.pop_back();
                            }
                        } else {
                            start = start + 1;
                        }
                    }
                    continue;
                case '&':
                    if(in_word) {
                        in_word = false;
                        tokens.push_back(tokenize_word(std::string(&src[start], pos - start), line));
                    }
                    tokens.push_back(Token {.type = Ampersand, .line = line });
                    if(length - 1 > pos) {
                        if(src[pos + 1] == '=') {
                            tokens[tokens.size() - 1].type = BitwiseAndEqual;
                            skip = 1;
                            start = pos + 2;
                        } else {
                            start = pos + 1;
                        }
                    }
                    continue;
                case '|':
                    if(in_word) {
                        in_word = false;
                        tokens.push_back(tokenize_word(std::string(&src[start], pos - start), line));
                    }
                    tokens.push_back(Token { .type = BitwiseOr, .line = line });
                    if(length - 1 > pos) {
                        if(src[pos + 1] == '=') {
                            tokens[tokens.size() - 1].type = BitwiseOrEqual;
                            skip = 1;
                            start = pos + 2;
                        } else {
                            start = pos + 1;
                        }
                    }
                    continue;
                case '^':
                    if(in_word) {
                        in_word = false;
                        tokens.push_back(tokenize_word(std::string(&src[start], pos - start), line));
                    }
                    tokens.push_back(Token { .type = BitwiseXor, .line = line });
                    if(length - 1 > pos) {
                        if(src[pos + 1] == '=') {
                            tokens[tokens.size() - 1].type = BitwiseXorEqual;
                            skip = 1;
                            start = pos + 2;
                        } else {
                            start = pos + 1;
                        }
                    }
                    continue;
                case '=':
                    if(in_word) {
                        in_word = false;
                        tokens.push_back(tokenize_word(std::string(&src[start], pos - start), line));
                    }
                    tokens.push_back(Token { .type = Equal, .line = line });
                    if(length - 1 > pos) {
                        if(src[pos + 1] == '=') {
                            tokens[tokens.size() - 1].type = LogicalEqualTo;
                            skip = 1;
                            start = pos + 2;
                        } else {
                            start = pos + 1;
                        }
                    }
                    continue;
                case '~':
                    if(in_word) {
                        in_word = false;
                        tokens.push_back(tokenize_word(std::string(&src[start], pos - start), line));
                    }
                    tokens.push_back(Token { .type = BitwiseNot, .line = line });
                    start = pos + 1;
                    continue;
                case '<':
                    if(in_word) {
                        in_word = false;
                        tokens.push_back(tokenize_word(std::string(&src[start], pos - start), line));
                    }
                    tokens.push_back(Token { .type = LogicalLessThan, .line = line });
                    if(length - 1 > pos) {
                        if(src[pos + 1] == '=') {
                            tokens[tokens.size() - 1].type = LogicalLessThanEqualTo;
                            skip = 1;
                            start = pos + 2;
                        } else if(src[pos + 1] == '<') {
                            tokens[tokens.size() - 1].type = BitwiseLeftShift;
                            if(length - 2 > pos) {
                                if(src[pos + 2] == '=') {
                                    tokens[tokens.size() - 1].type = BitwiseLeftShiftEqual;
                                    skip = 2;
                                    start = pos + 3;
                                    continue;
                                } 
                            }
                            skip = 1;
                            start = pos + 2;
                        }
                    }
                    continue;
                case '>':
                    if(in_word) {
                        in_word = false;
                        tokens.push_back(tokenize_word(std::string(&src[start], pos - start), line));
                    }
                    tokens.push_back(Token { .type = LogicalGreaterThan, .line = line });
                    if(length - 1 > pos) {
                        if(src[pos + 1] == '=') {
                            tokens[tokens.size() - 1].type = LogicalGreaterThanEqualTo;
                            skip = 1;
                            start = pos + 2;
                        } else if(src[pos + 1] == '<') {
                            tokens[tokens.size() - 1].type = BitwiseRightShift;
                            if(length - 2 > pos) {
                                if(src[pos + 2] == '=') {
                                    tokens[tokens.size() - 1].type = BitwiseRightShiftEqual;
                                    skip = 2;
                                    start = pos + 3;
                                    continue;
                                } 
                            }
                            skip = 1;
                            start = pos + 2;
                        }
                    }
                    continue;
                case '!':
                    if(in_word) {
                        in_word = false;
                        tokens.push_back(tokenize_word(std::string(&src[start], pos - start), line));
                    }
                    tokens.push_back(Token { .type = LogicalNot, .line = line });
                    start = pos + 1;
                    continue;
                case '(':
                    if(in_word) {
                        in_word = false;
                        tokens.push_back(tokenize_word(std::string(&src[start], pos - start), line));
                    }
                    tokens.push_back(Token { .type = OpenParen, .line = line });
                    start = pos + 1;
                    continue;
                case ')':
                    if(in_word) {
                        in_word = false;
                        tokens.push_back(tokenize_word(std::string(&src[start], pos - start), line));
                    }
                    tokens.push_back(Token { .type = CloseParen, .line = line });
                    start = pos + 1;
                    continue;
                case '{':
                    if(in_word) {
                        in_word = false;
                        tokens.push_back(tokenize_word(std::string(&src[start], pos - start), line));
                    }
                    tokens.push_back(Token { .type = OpenCurly, .line = line });
                    start = pos + 1;
                    continue;
                case '}':
                    if(in_word) {
                        in_word = false;
                        tokens.push_back(tokenize_word(std::string(&src[start], pos - start), line));
                    }
                    tokens.push_back(Token { .type = CloseCurly, .line = line });
                    start = pos + 1;
                    continue;
                case '[':
                    if(in_word) {
                        in_word = false;
                        tokens.push_back(tokenize_word(std::string(&src[start], pos - start), line));
                    }
                    tokens.push_back(Token { .type = OpenBracket, .line = line });
                    if(length - 1 > pos) {
                        if(src[pos + 1] == '[') {
                            tokens[tokens.size() - 1].type = OpenTraitDecorator;
                            skip = 1;
                            start = pos + 2;
                        } else {
                            start = pos + 1;
                        }
                    }
                    continue;
                case ']':
                    if(in_word) {
                        in_word = false;
                        tokens.push_back(tokenize_word(std::string(&src[start], pos - start), line));
                    }
                    tokens.push_back(Token { .type = CloseBracket, .line = line });
                    if(length - 1 > pos) {
                        if(src[pos + 1] == ']') {
                            tokens[tokens.size() - 1].type = CloseTraitDecorator;
                            skip = 1;
                            start = pos + 2;
                        } else {
                            start = pos + 1;
                        }
                    }
                    continue;
                case ':':
                    if(in_word) {
                        in_word = false;
                        tokens.push_back(tokenize_word(std::string(&src[start], pos - start), line));
                    }
                    tokens.push_back(Token { .type = Colon, .line = line });
                    start = pos + 1;
                    continue;
                case ';':
                    if(in_word) {
                        in_word = false;
                        tokens.push_back(tokenize_word(std::string(&src[start], pos - start), line));
                    }
                    tokens.push_back(Token { .type = Semicolon, .line = line });
                    start = pos + 1;
                    continue;
                case '@':
                    if(in_word) {
                        in_word = false;
                        tokens.push_back(tokenize_word(std::string(&src[start], pos - start), line));
                    }
                    tokens.push_back(Token { .type = TargetSymbol, .line = line });
                    start = pos + 1;
                    continue;
                case '\'':
                    if(in_word) {
                        in_word = false;
                        tokens.push_back(tokenize_word(std::string(&src[start], pos - start), line));
                    }
                    in_char = true;
                    start = pos;
                    continue;
                case '.':
                    if(src[start] >= 48 && src[start] <= 57) {
                        continue;
                    }
                    if(in_word) {
                        in_word = false;
                        tokens.push_back(tokenize_word(std::string(&src[start], pos - start), line));
                    }
                    tokens.push_back(Token { .type = Period, .line = line });
                    start = pos + 1;
                    continue;
                default:
                    in_word = true;
                    continue;
            }
        }
    }

    if(in_word)
        tokens.push_back(make_token(Symbol, std::string(&src[start], length - start), line));

    if(in_char)
        tokens.push_back(make_token(CharacterLiteral, std::string(&src[start + 1], length - start), line));

    if(in_string)
        tokens.push_back(make_token(CharacterLiteral, std::string(&src[start + 1], length - start), line));

    if(in_ml_comment) {
        for(size_t i = ml_comment_beg; i < tokens.size(); i++) {
            tokens.pop_back();
        }
    }

    tokens.push_back(make_token(EndOfFile, {}, line));

    return tokens;
}

std::string token_type_name(const TokenType type) {
    switch(type) {
        case Int8: return "Int8";
        case Int16: return "Int16";
        case Int32: return "Int32";
        case Int64: return "Int64";
        case UInt8: return "UInt8";
        case UInt16: return "UInt16";
        case UInt32: return "UInt32";
        case UInt64: return "UInt64";
        case Float32: return "Float32";
        case Float64: return "Float64";
        case True: return "True";
        case False: return "False";
        case Void: return "Void";
        case Voidptr: return "Voidptr";
        case Bool: return "Bool";
        case If: return "If";
        case Else: return "Else";
        case ElseIf: return "ElseIf";
        case For: return "For";
        case While: return "While";
        case Enum: return "Enum";
        case Struct: return "Struct";
        case Typealias: return "Typealias";
        case Fn: return "Fn";
        case Fnptr: return "Fnptr";
        case Let: return "Let";
        case Import: return "Import";
        case Enable: return "Enable";
        case Disable: return "Disable";
        case Trait: return "Trait";
        case Self: return "Self";
        case CharacterLiteral: return "CharacterLiteral";
        case StringLiteral: return "StringLiteral";
        case NumericLiteral: return "NumericLiteral";
        case IntegerLiteral: return "IntegerLiteral";
        case FloatLiteral: return "FloatLiteral";
        case HexLiteral: return "HexLiteral";
        case BinaryLiteral: return "BinaryLiteral";
        case InvalidLiteral: return "InvalidLiteral";
        case OpenCurly: return "OpenCurly";
        case CloseCurly: return "CloseCurly";
        case OpenBracket: return "OpenBracket";
        case CloseBracket: return "CloseBracket";
        case OpenTraitDecorator: return "OpenTraitDecorator";
        case CloseTraitDecorator: return "CloseTraitDecorator";
        case OpenParen: return "OpenParen";
        case CloseParen: return "CloseParen";
        case Colon: return "Colon";
        case Semicolon: return "Semicolon";
        case Comma: return "Comma";
        case Period: return "Period";
        case TargetSymbol: return "TargetSymbol";
        case Plus: return "Plus";
        case Minus: return "Minus";
        case Asterisk: return "Asterisk";
        case Divide: return "Divide";
        case Modulo: return "Modulo";
        case Equal: return "Equal";
        case PlusEqual: return "PlusEqual";
        case MinusEqual: return "MinusEqual";
        case MultiplyEqual: return "MultiplyEqual";
        case DivideEqual: return "DivideEqual";
        case ModuloEqual: return "ModuloEqual";
        case Increment: return "Increment";
        case Decrement: return "Decrement";
        case Ampersand: return "Ampersand";
        case BitwiseOr: return "BitwiseOr";
        case BitwiseXor: return "BitwiseXor";
        case BitwiseNot: return "BitwiseNot";
        case BitwiseLeftShift: return "BitwiseLeftShift";
        case BitwiseRightShift: return "BitwiseRightShift";
        case BitwiseAndEqual: return "BitwiseAndEqual";
        case BitwiseOrEqual: return "BitwiseOrEqual";
        case BitwiseXorEqual: return "BitwiseXorEqual";
        case BitwiseLeftShiftEqual: return "BitwiseLeftShiftEqual";
        case BitwiseRightShiftEqual: return "BitwiseRightShiftEqual";
        case LogicalLessThan: return "LogicalLessThan";
        case LogicalGreaterThan: return "LogicalGreaterThan";
        case LogicalEqualTo: return "LogicalEqualTo";
        case LogicalLessThanEqualTo: return "LogicalLessThanEqualTo";
        case LogicalGreaterThanEqualTo: return "LogicalGreaterThanEqualTo";
        case LogicalNot: return "LogicalNot";
        case LogicalAnd: return "LogicalAnd";
        case LogicalOr: return "LogicalOr";
        case Symbol: return "Symbol";
        case EndOfFile: return "EndOfFile";
        default: return "ERROR";
    }
}
