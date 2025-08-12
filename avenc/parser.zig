const std = @import("std");
const print = std.debug.print;
const alc = std.heap.page_allocator;
const alloc = alc.alloc;

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

const ExpressionAST = struct {

};

const VariableDeclarationAST = struct {

};
