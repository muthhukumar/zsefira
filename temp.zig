const std = @import("std");

pub fn main() !void {
    var stdin_buffer: [512]u8 = undefined;
    var stdin_reader_wrapper = std.fs.File.stdin().reader(&stdin_buffer);
    const reader: *std.Io.Reader = &stdin_reader_wrapper.interface;

    var stdout_buffer: [512]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout: *std.Io.Writer = &stdout_writer.interface;

    try stdout.writeAll("Type something: ");
    try stdout.flush();

    while (reader.takeDelimiterExclusive('\n')) |line| {
        try stdout.print("You typed: {s}\n...\nType something: ", .{line});
        try stdout.flush();
    } else |err| switch (err) {
        error.EndOfStream => {},
        error.StreamTooLong => return err,
        error.ReadFailed => return err,
    }
}
