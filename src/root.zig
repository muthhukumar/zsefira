//! By convention, root.zig is the root source file when making a library.
const std = @import("std");
const AccessError = std.fs.Dir.AccessError;

const SefiraConfig = struct {
    filePath: []const u8,
    appName: []const u8,
    fileName: []const u8,
};

fn getOutputString(idx: usize) []const u8 {
    return switch (idx) {
        0 => "App Name",
        1 => "File Path",
        2 => "File name",
        else => unreachable,
    };
}

pub fn initConfig(stdout: *std.Io.Writer, allocator: *std.mem.Allocator) !void {
    if (std.fs.cwd().access("sefira.json", .{ .mode = .read_only })) |_| {
        std.debug.print("Config file already exists\n", .{});
        return;
    } else |err| if (err != AccessError.FileNotFound) {
        return err;
    }

    var stdin_buffer: [1024]u8 = undefined;
    var stdin_reader_wrapper = std.fs.File.stdin().reader(&stdin_buffer);
    const reader: *std.Io.Reader = &stdin_reader_wrapper.interface;

    var file = try std.fs.cwd().createFile("sefira.json", .{});
    defer file.close();

    var file_buffer: [1024]u8 = undefined;
    var file_writer = file.writer(&file_buffer);
    const fout: *std.Io.Writer = &file_writer.interface;

    var idx: usize = 0;
    var fields: [3][]const u8 = undefined;

    try stdout.print("Sefira Config\n", .{});

    blk: while (idx < fields.len) {
        try stdout.print("{s}: ", .{getOutputString(idx)});
        try stdout.flush();

        const line = reader.takeDelimiterExclusive('\n') catch |err| switch (err) {
            error.EndOfStream => {
                continue :blk;
            },
            error.StreamTooLong => return err,
            error.ReadFailed => return err,
        };

        if (std.mem.eql(u8, line, "")) {
            continue :blk;
        }

        const copy = try allocator.alloc(u8, line.len);
        @memcpy(copy, line);

        fields[idx] = copy;

        idx += 1;
    }

    try std.json.Stringify.value(SefiraConfig{
        .appName = fields[0],
        .filePath = fields[1],
        .fileName = fields[2],
    }, .{}, fout);

    try fout.flush();

    allocator.free(fields[0]);
    allocator.free(fields[1]);
    allocator.free(fields[2]);
}
