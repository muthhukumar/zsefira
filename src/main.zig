const std = @import("std");
const zsefira = @import("zsefira");

pub fn main() !void {
    var general_purpose_allocator: std.heap.GeneralPurposeAllocator(.{}) = .init;
    var gpa = general_purpose_allocator.allocator();

    const argsAlloc = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, argsAlloc);

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);

    if (argsAlloc.len == 0) {
        // TODO: handle this
    }

    var args = try std.ArrayList([]const u8).initCapacity(gpa, argsAlloc.len);
    defer args.deinit(gpa);

    for (argsAlloc[1..]) |arg| {
        const result: []const u8 = std.mem.sliceTo(arg, 0);
        try args.append(gpa, result);
    }

    if (std.mem.eql(u8, args.items[0], "init")) {
        try zsefira.initConfig(&stdout_writer.interface, &gpa);
    }
}

test "simple test" {
    const gpa = std.testing.allocator;
    var list: std.ArrayList(i32) = .empty;
    defer list.deinit(gpa); // Try commenting this out and see if zig detects the memory leak!
    try list.append(gpa, 42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

test "fuzz example" {
    const Context = struct {
        fn testOne(context: @This(), input: []const u8) anyerror!void {
            _ = context;
            // Try passing `--fuzz` to `zig build test` and see if it manages to fail this test case!
            try std.testing.expect(!std.mem.eql(u8, "canyoufindme", input));
        }
    };
    try std.testing.fuzz(Context{}, Context.testOne, .{});
}
