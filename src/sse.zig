const std = @import("std");
const log = std.log.scoped(.server);
const Event = @import("types.zig").Event;
const Data = @import("data.zig");
const shared_state = @import("shared_state.zig").state;

const LISTEN_ADDR = "127.0.0.1";
const LISTEN_PORT = 8000;

fn handleEvents(io: std.Io, req: *std.http.Server.Request, state: *shared_state) !void {
    // An empty buffer sends each write through
    // the streaming writer immediately.
    var event_buffer: [0]u8 = .{};

    var body = try req.respondStreaming(
        &event_buffer,
        .{
            .respond_options = .{
                .status = .ok,
                .keep_alive = false,
                .extra_headers = &.{
                    .{
                        .name = "Content-Type",
                        .value = "text/event-stream",
                    },
                    .{
                        .name = "Cache-Control",
                        .value = "no-cache",
                    },
                },
            },
        },
    );

    // use the std.io.queue
    // Ui will add events to it
    // for now, it will be highlight events and property change events
    // could test it out just with the color
    //

    while (true) {

        // TODO: Create a message queue
        // from the UI add in requests for sse
        // consume the requests here

        const ui_event = state.*.event_queue.getOne(io) catch |err| switch (err) {
            error.Closed, error.Canceled => {
                log.err("Error getting event: {}", .{err});
                return;
            },
        };

        switch (ui_event) {
            .highlight => |id| {
                if (id) |value| {
                    //log.info("highlight event received: {any}", .{id});
                    const selector = Data.get_element_selector_from_id(value);
                    try body.writer.print(
                        "event: highlight\ndata: {s} \n\n",
                        .{selector},
                    );
                    try body.flush();
                } else {
                    //log.info("highlight event received:", .{});
                    // remove highlight
                    const event = "event: highlight\ndata: \n\n";
                    try body.writer.writeAll(event);
                    try body.flush();
                }
            },
            else => |value| {
                log.info("other event received: {any}", .{value});
            },
        }
    }
}

fn handleStream(io: std.Io, stream: std.Io.net.Stream, state: *shared_state) void {
    defer stream.close(io);

    var read_buffer: [4096]u8 = undefined;
    var write_buffer: [4096]u8 = undefined;

    var reader = stream.reader(io, &read_buffer);
    var writer = stream.writer(io, &write_buffer);

    var http_server = std.http.Server.init(&reader.interface, &writer.interface);
    const cwd: std.Io.Dir = std.Io.Dir.openDirAbsolute(io, state.*.working_directory[0..], .{ .iterate = true }) catch unreachable;

    cwd.access(io, "index.html", .{}) catch |err| {
        log.err("index.html access error: {}", .{err});
        return;
    };
    cwd.access(io, "styles/default.css", .{}) catch |err| {
        log.err("default.css access error: {}", .{err});
        return;
    };

    // TODO: allocation for larger size
    // because MelbCSS index.html itself is 9KB
    var index_html: [10 * 1024]u8 = undefined;
    const html = cwd.readFile(io, "index.html", &index_html) catch unreachable;

    const pos = std.mem.lastIndexOf(u8, html, "</html>") orelse 0;
    var modified_html: [20 * 1024]u8 = undefined;
    const injected_js =
        \\<script>
        \\(() => {
        \\    const events = new EventSource("/__events");
        \\    let previousElement = null;
        \\
        \\    events.addEventListener("theme", (event) => {
        \\        document.documentElement.style.setProperty("--bg", event.data);
        \\    });
        \\
        \\    events.addEventListener("highlight", (event) => {
        \\        const selector = event.data.trim();
        \\        const element = selector
        \\            ? document.querySelector(selector)
        \\            : null;
        \\
        \\        if (element === previousElement) return;
        \\
        \\        if (previousElement) {
        \\            previousElement.style.removeProperty("outline");
        \\        }
        \\
        \\        if (element) {
        \\            element.style.outline = "thick solid #0000FF";
        \\        }
        \\
        \\        previousElement = element;
        \\        console.log("Element: ", element);
        \\    });
        \\
        \\    events.onerror = () => {
        \\        console.warn("SSE connection lost");
        \\    };
        \\})();
        \\</script>
    ;

    const result = std.mem.print(modified_html[0..], "{s}{s}{s}", .{ html[0..pos], injected_js, html[pos..html.len] }) catch unreachable;
    //std.debug.print("\nModified Html:{s} ", .{result[0..result.len]});

    while (state.*.app_state != .closing) {
        var req = http_server.receiveHead() catch |err| switch (err) {
            error.HttpConnectionClosing => return,
            else => return,
        };
        log.info("Req {s} \n Content Type: {any}", .{ req.head.target[0..], req.head });

        if (std.mem.eql(u8, req.head.target[0..], "/")) {
            req.respond(result[0..result.len], .{ .status = .ok }) catch unreachable;
        } else if (std.mem.eql(u8, req.head.target[0..], "/__events")) {
            handleEvents(io, &req, state) catch |err| {
                log.info("SSE connection ended: {}", .{err});
                return;
            };
        } else if ((std.mem.startsWith(u8, req.head.target[0..], "/img")) or (std.mem.startsWith(u8, req.head.target[0..], "/styles"))) {

            // Remove the first '/' from the request
            const file = cwd.openFile(io, req.head.target[1..], .{}) catch |err| switch (err) {
                error.BadPathName => {
                    std.log.err("path: {s}\n err: {any}", .{ req.head.target[1..], err });
                    return;
                },
                else => return,
            };

            defer file.close(io);

            // 10kb size
            var file_buf: [10 * 1024]u8 = undefined;
            var file_reader = file.reader(io, &file_buf);
            const reader_interface = &file_reader.interface;

            const bytes_read = reader_interface.readSliceShort(&file_buf) catch unreachable;

            if (std.mem.startsWith(u8, req.head.target[0..], "/img")) {
                req.respond(file_buf[0..bytes_read], .{
                    .status = .ok,
                    .extra_headers = &.{
                        .{
                            .name = "Content-Type",
                            .value = "image/svg+xml",
                        },
                    },
                }) catch unreachable;
            } else {
                req.respond(file_buf[0..bytes_read], .{
                    .status = .ok,
                    .extra_headers = &.{
                        .{
                            .name = "Content-Type",
                            .value = "text/css",
                        },
                    },
                }) catch unreachable;
            }
        } else {
            req.respond("", .{ .status = .not_found }) catch unreachable;
        }
    }
}

fn startServerAsync(io: std.Io, state: *shared_state) !void {
    log.info("Listening on http://{s}:{d}", .{ LISTEN_ADDR, LISTEN_PORT });

    const addr = std.Io.net.IpAddress.parseIp4(LISTEN_ADDR, LISTEN_PORT) catch unreachable;
    var server = try addr.listen(io, .{ .reuse_address = true });

    defer server.deinit(io);

    var group: std.Io.Group = .init;
    defer group.cancel(io);

    while (state.*.app_state != .closing) {
        const stream = try server.accept(io);
        group.concurrent(io, handleStream, .{ io, stream, state }) catch |err| {
            log.err("Failed to handle connection: {}", .{err});
            stream.close(io);
        };
    }
}

pub fn handle_server(io: std.Io, state: *shared_state) void {
    log.info("Starting server", .{});
    const server_thread = std.Thread.spawn(.{}, startServerAsync, .{ io, state }) catch |err| switch (err) {
        else => {
            log.err("Failed to start server: {}", .{err});
            return;
        },
    };
    server_thread.detach();
}
