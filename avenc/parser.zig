const std = @import("std");
const print = std.debug.print;
const alc = std.heap.page_allocator;
const alloc = alc.alloc;
const lexer = @import("lexer.zig");

const Expression = enum {
    Function,
};

const ExpressionAST = union(Expression) {
    Function: FunctionAST,
};

const AvenAST = struct {

};

const FunctionAST = struct {
    prototype: FunctionPrototypeAST,
    body: FunctionBodyAST,
};

const FunctionPrototypeAST = struct {
    name: []const u8,
    params: std.ArrayList(ParametersAST),
};

const FunctionBodyAST = struct {
    std.ArrayList(ExpressionAST),
};

const ParametersAST = struct {
    name: []const u8,
    type: []const u8, // Maybe this should be an enum WARN:
};

pub fn parse(tokens: std.ArrayList(lexer.Token)) AvenAST {
    var expected = std.ArrayList(lexer.Token).init(alc);
    expected.append(.{.type = .Unknown, .data = null });
    for(0..tokens.items.len) |i| {
        const cur = tokens.items[i];
        if(expected.items[0].type == .Unknown) {
            switch(cur.type) {
                .Fn => {
                    
                }
                else => return error.SyntaxError;
            }
        }
    }
}
