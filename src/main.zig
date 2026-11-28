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

    if (state.is_theme_saved) {
        file_writer.save_css(init.io, &state) catch unreachable;
        file_writer.update_index_html(init.io, &state) catch unreachable;
    } else {
        if (file_writer.remove_css_file(init.io, &state)) {
            std.log.info("Removed css file {s}.css", .{state.theme_name.value[0..state.theme_name.length]});
        } else |err| {
            std.log.err("Unable to remove css file {s}.css - Err: {any}", .{ state.theme_name.value[0..state.theme_name.length], err });
        }

        if (file_writer.cleanup_index_html(init.io, &state)) {
            std.log.info("Cleaned up index.html file", .{});
        } else |err| {
            std.log.err("Unable to clean up index.html file - Err: {any}", .{err});
        }
    }

    std.log.info("Quiting...", .{});
}

// pub fn main() !void {
//     ui.run() catch |err| {
//         log.err("{}", .{err});
//     };
// }
