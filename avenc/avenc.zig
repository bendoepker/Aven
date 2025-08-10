const std = @import("std");
const lexer = @import("lexer.zig");
const print = std.debug.print;

pub fn main() !u8 {
    const allocator = std.heap.page_allocator;
    const args = try std.process.argsAlloc(allocator);
    if(args.len < 2) {
        print("Provide the name of a file to compile", .{});
        return 1;
    }
    const file = std.fs.cwd().openFile(args[1], .{}) catch {
        print("Could not open file {s}", .{args[1]});
        return 1;
    };

    for(args) |arg|
        print("{s}\n", .{arg});
    // All of the command line arguments are in args, the first argument is always the file path
    const tokens = try lexer.tokinize(file);
    for(0..tokens.items.len) |i| {
        const tk = tokens.items[i];
        print("{s}", .{@tagName(tk.type)});
        if(tk.data != null) {
            print(" {?s}", .{tk.data});
        }
        print("\n", .{});
    }

    return 0;
}
