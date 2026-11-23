const std = @import("std");
const log = std.log.scoped(.server);
const Io = std.Io;
const IpAddress = Io.net.IpAddress;

const rl = @import("raylib");
const rg = @import("raygui");
const font = @import("font.zig");
const fui = @import("gui_helpers.zig");
const sse = @import("sse.zig");
const ui = @import("ui.zig");
const shared_state = @import("shared_state.zig").state;
const file_writer = @import("file_writer.zig");

pub fn main(init: std.process.Init) !void {
    var state: shared_state = .{};
    state.init();
    sse.handle_server(init.io, &state);
    ui.run(init.io, &state) catch |err| {
        log.err("{}", .{err});
    };

    if (state.update_files) {
        file_writer.save_css(init.io, &state) catch unreachable;
        file_writer.update_index_html(init.io, &state) catch unreachable;
    }

    std.log.info("Quiting...", .{});
}

// pub fn main() !void {
//     ui.run() catch |err| {
//         log.err("{}", .{err});
//     };
// }
