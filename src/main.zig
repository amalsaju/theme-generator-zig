const std = @import("std");
const log = std.log.scoped(.server);
const Io = std.Io;
const IpAddress = Io.net.IpAddress;

const rl = @import("raylib");
const rg = @import("raygui");
const font = @import("font.zig");
const gui = @import("gui_helpers.zig");
const sse = @import("sse.zig");
const ui = @import("ui.zig");
//
pub fn main(init: std.process.Init) !void {
    sse.handle_server(init.io);
    ui.run() catch |err| {
        log.err("{}", .{err});
    };
}

// pub fn main() !void {
//     ui.run() catch |err| {
//         log.info("{}", .{err});
//     };
// }
