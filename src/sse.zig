const std = @import("std");
const log = std.log.scoped(.server);
const Event = @import("types.zig").Event;
const Data = @import("data.zig");
const shared_state = @import("shared_state.zig").State;

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
                log.info("Error getting event: {}", .{err});
                return;
            },
        };

        switch (ui_event) {
            .highlight => |id| {
                if (id) |value| {
                    log.info("highlight event received: {any}", .{id});
                    const selector = Data.get_element_selector_from_id(value);
                    try body.writer.print(
                        "event: highlight\ndata: {s} \n\n",
                        .{selector},
                    );
                    try body.flush();
                } else {
                    log.info("highlight event received:", .{});
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

    const cwd = std.Io.Dir.cwd();

    // TODO: allocation for larger size
    // because MelbCSS index.html itself is 9KB
    var test_html: [1024]u8 = undefined;
    const html = cwd.readFile(io, "src/test.html", &test_html) catch unreachable;

    const pos = std.mem.lastIndexOf(u8, html, "</html>") orelse 0;
    var modified_html: [64 * 1024]u8 = undefined;
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
    std.debug.print("\nModified Html:{s} ", .{result[0..result.len]});

    const file_css = cwd.openFile(io, "src/test.css", .{}) catch unreachable;
    defer file_css.close(io);

    var test_css: [1024]u8 = undefined;
    var file_reader_css = file_css.reader(io, &test_css);
    const reader_interface_css = &file_reader_css.interface;

    const bytes_read_test_css = reader_interface_css.readSliceShort(&test_css) catch unreachable;

    while (true) {
        var req = http_server.receiveHead() catch |err| switch (err) {
            error.HttpConnectionClosing => return,
            else => return,
        };
        log.info("Req {s}", .{req.head.target[0..]});

        if (std.mem.eql(u8, req.head.target[0..], "/")) {
            req.respond(result[0..result.len], .{ .status = .ok }) catch unreachable;
        }

        if (std.mem.eql(u8, req.head.target[0..], "/test.css")) {
            req.respond(test_css[0..bytes_read_test_css], .{ .status = .ok }) catch unreachable;
        }
        if (std.mem.eql(u8, req.head.target[0..], "/__events")) {
            handleEvents(io, &req, state) catch |err| {
                log.info("SSE connection ended: {}", .{err});
                return;
            };
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

    while (true) {
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
