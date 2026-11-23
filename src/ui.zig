const std = @import("std");
const log = std.log.scoped(.server);
const rl = @import("raylib");
const rg = @import("raygui");
const data = @import("data.zig");
const shared_state = @import("shared_state.zig").state;
const event = @import("types.zig").event;
const Theme = @import("theme.zig").Theme;
const types = @import("types.zig");

const MouseButtonState = enum { normal, hover, pressed };
const ThemeStyle = enum { light, dark };
var css_events_list: [256]types.css_property_change_event = .{};

// pub fn write_data_to_file(io: std.Io, state: *shared_state) void {
//     const dir = std.Io.Dir.openDirAbsolute(io, state.working_directory, .{ .iterate = true }) catch unreachable;
//     const file = try dir.createFile(io, "styles/test.css", .{});
//     defer file.close(io);
//
//     var buf: [20 * 1024]u8 = "";
//
//     // iterate through the style to get id, selector and tag
//     for (state.css_style_list, 0..) |value, i| {
//
//         // write the id, then { then the declarations
//         // when it ends write }
//
//         for (value.tag_css_declarations, 0..) |tag_values, j| {
//             buf = buf ++ tag_values.css_property
//         }
//     }
// }

pub fn run(io: std.Io, state: *shared_state) !void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth = 1280;
    const screenHeight = 720;

    var state_mouse_button: MouseButtonState = .normal;
    var theme_style: ThemeStyle = .dark;

    var prng: std.Random.DefaultPrng = .init(0);
    //var show_color_picker: bool = false;

    //var color_selected = rl.Color{ .r = 150, .g = 150, .b = 150, .a = 1 };

    rl.initWindow(screenWidth, screenHeight, "MelbCSS Theme Generator");
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    const row_height: u32 = 20;
    var scroll_content_offset_left: rl.Vector2 = .{ .x = 0, .y = 0 };
    var view_html_tree: rl.Rectangle = .{ .x = 0, .y = 0, .width = 0, .height = 0 };
    const scroll_content_left: rl.Rectangle = .{ .x = 20, .y = 20, .width = 200, .height = data.html_elements.len * 30 };
    const content_right: rl.Rectangle = .{ .x = 220, .y = 20, .width = 700, .height = screenHeight - 100 };

    var element_check_box = true;
    var selector_check_box = false;
    var id_check_box = false;
    var class_check_box = false;

    const indent_width_text: i32 = 10;
    var start_position_element: i32 = 0;
    var hover_id: u32 = 0;
    var selected_id: u32 = 0;

    // var order_spinner: i32 = 20;
    // var order_value_box: i32 = 20;
    //const indent_width_connection: i32 = 5;
    var buf_background_color: types.color_value = .{
        .r = 255,
        .g = 255,
        .b = 255,
    };
    var buf_text_color: types.color_value = .{
        .r = 255,
        .g = 255,
        .b = 255,
    };
    var buf_font_size: i32 = 20;
    var buf_margin: types.edge_value = .{
        .left = 0,
        .right = 0,
        .top = 0,
        .bottom = 0,
    };
    var buf_padding: types.edge_value = .{
        .left = 0,
        .right = 0,
        .top = 0,
        .bottom = 0,
    };

    // Main game loop
    while (!rl.windowShouldClose()) {
        if (rl.isKeyPressed(rl.KeyboardKey.t)) {
            if (theme_style == .light) {
                theme_style = .dark;
            } else {
                theme_style = .light;
            }
        }

        const theme: *const Theme = if (theme_style == .light) &Theme.Light else &Theme.Dark;

        rl.beginDrawing();

        rl.clearBackground(theme.background);

        rg.setStyle(.default, .text_color_normal, @intCast(rl.colorToInt(theme.foreground)));

        rg.setStyle(.default, .background_color, @intCast(rl.colorToInt(theme.background)));

        _ = rg.scrollPanel(
            .{ .x = 0, .y = 0, .width = 250, .height = 700 },
            null,
            scroll_content_left,
            &scroll_content_offset_left,
            &view_html_tree,
        );
        scroll_content_offset_left.y = @min(0, scroll_content_offset_left.y);
        //log.info("Scroll: {}", .{scroll_content_offset});
        start_position_element = @divCeil(@as(i32, @intFromFloat(scroll_content_offset_left.y)), row_height);
        //log.info("Start position: {}", .{start_position_element});
        //log.info("Scroll content offset: {}", .{@as(i32, @intFromFloat(scroll_content_offset.y))});

        const view_list = data.html_elements[@abs(start_position_element)..];
        const mouse_position = rl.Vector2{ .x = @floatFromInt(rl.getMouseX() - 20), .y = @floatFromInt(rl.getMouseY() - 20) }; // the padding
        //
        //log.info("Mouse position: {}", .{mouse_position});
        var send_data_id_previous: ?u32 = 0;

        if (rl.checkCollisionPointRec(mouse_position, view_html_tree)) {
            state_mouse_button = .hover;
            //log.info("Mouse inside view: {}", .{mouse_position});
            hover_id = @abs(@divFloor(@as(i32, @intFromFloat(mouse_position.y)), row_height));

            if (send_data_id_previous != hover_id + @abs(start_position_element)) {
                const event_to_sent: event = .{
                    .highlight = @as(u8, @intCast(hover_id + @abs(start_position_element))),
                };
                _ = state.*.event_queue.put(io, &.{event_to_sent}, 0) catch |err| {
                    log.err("Error putting into event queue: {}", .{err});
                };

                send_data_id_previous = hover_id + @abs(start_position_element);
            }

            if (rl.isMouseButtonDown(rl.MouseButton.left)) {
                state_mouse_button = .pressed;
            }
            if (state_mouse_button == .pressed and rl.isMouseButtonUp(rl.MouseButton.left)) {
                state_mouse_button = .normal;
            }

            log.info("Selected Id: {}", .{hover_id});
        } else if (state_mouse_button != .normal) {
            state_mouse_button = .normal;
            if (send_data_id_previous != null) {
                const event_to_sent: event = .{
                    .highlight = null,
                };
                _ = state.*.event_queue.put(io, &.{event_to_sent}, 0) catch |err| {
                    log.err("Error putting into event queue: {}", .{err});
                };
                send_data_id_previous = null;
            }
        }

        if (state_mouse_button == .pressed) {
            selected_id = @min(hover_id + @abs(start_position_element), data.html_elements.len - 1);
        }

        //TODO: implementing scroll
        // how does this work - we have the scroll area and a view
        // we know the width of the scrollable area so we know the width of the highlight box
        // we need to define a pre determined height - something based off the font size
        // then we know how many elements we can show based on that height
        // the scroll offset will define from which html element in the array we start showing the text
        // then based on that as well as the mouse position we also know which element we are hovering on to highlight
        // because we only need to update the highlight in steps of the pre determined height right ?
        // and with that predertermined height we also know the index of the html element and then we can send the event to the browser
        //

        // left side
        for (view_list, 0..) |value, i| {
            const level: i32 = @intCast(value.level);
            const index: i32 = @intCast(i);

            const x = @as(i32, @intFromFloat(scroll_content_left.x)) + (level * indent_width_text);
            const y = @as(i32, @intFromFloat(scroll_content_left.y)) + index * row_height;

            if (value.id == data.html_elements[selected_id].id) {
                rl.drawRectangleRounded(.{ .x = scroll_content_left.x - 6.0, .y = @as(f32, @floatFromInt(y)) - 6.0, .width = scroll_content_left.width, .height = 22 }, 0.40, 0, theme.secondary);
                rl.drawText(
                    @tagName(value.html_tag),
                    x,
                    y - 4,
                    20,
                    theme.secondary_foreground,
                );
            } else if (i == hover_id and state_mouse_button == .hover) {
                //rl.drawRectangleRounded(.{ .x = content.x - 6.0, .y = @as(f32, @floatFromInt(y)) - 6.0, .width = content.width, .height = 22 }, 0.40, 0, theme.chart_1);
                //rl.drawRectangle(content.x, y - 4, content.width, 20, .gray);
                rl.drawText(
                    @tagName(value.html_tag),
                    x,
                    y - 4,
                    20,
                    theme.secondary,
                );
            } else if (i == hover_id and state_mouse_button == .pressed) {
                rl.drawRectangleRounded(.{ .x = scroll_content_left.x - 6.0, .y = @as(f32, @floatFromInt(y)) - 6.0, .width = scroll_content_left.width, .height = 22 }, 0.40, 0, theme.secondary);
                //rl.drawRectangle(content.x, y - 4, content.width, 20, .gray);
                rl.drawText(
                    @tagName(value.html_tag),
                    x,
                    y - 4,
                    20,
                    theme.secondary_foreground,
                );
            } else {
                rl.drawText(
                    @tagName(value.html_tag),
                    x,
                    y - 4,
                    20,
                    theme.foreground,
                );
            }
        }

        // right side
        rl.drawText("Selected Element", content_right.x + 50, content_right.y, 20, theme.muted_foreground);
        rl.drawText(
            @tagName(data.html_elements[selected_id].html_tag),
            content_right.x + 50,
            content_right.y + 20,
            30,
            theme.secondary,
        );
        rl.drawText(
            data.html_elements[selected_id].selector,
            content_right.x + 50,
            content_right.y + 55,
            20,
            theme.muted_foreground,
        );

        rl.drawLine(
            content_right.x + 50,
            content_right.y + 80,
            content_right.x + (content_right.width - content_right.x) - 20,
            content_right.y + 80,
            theme.muted,
        );

        rl.drawText(
            "Apply Property: ",
            content_right.x + 50,
            content_right.y + 90,
            20,
            theme.muted_foreground,
        );

        rg.setStyle(.default, .text_size, 20);
        rg.setStyle(.default, .text_padding, 10);
        rg.setStyle(.default, .text_color_normal, @intCast(rl.colorToInt(theme.secondary)));
        _ = rg.checkBox(.{ .x = content_right.x + 50, .y = content_right.y + 120, .width = 20, .height = 20 }, "element", &element_check_box);
        _ = rg.checkBox(.{ .x = content_right.x + 175, .y = content_right.y + 120, .width = 20, .height = 20 }, "selector", &selector_check_box);
        _ = rg.checkBox(.{ .x = content_right.x + 300, .y = content_right.y + 120, .width = 20, .height = 20 }, "id", &id_check_box);
        _ = rg.checkBox(.{ .x = content_right.x + 375, .y = content_right.y + 120, .width = 20, .height = 20 }, "class", &class_check_box);

        rl.drawLine(
            content_right.x + 50,
            content_right.y + 150,
            content_right.x + (content_right.width - content_right.x) - 20,
            content_right.y + 150,
            theme.muted,
        );

        // background color
        rl.drawText(
            rl.textFormat("background color: #%02X%02X%02X ", .{ buf_background_color.r, buf_background_color.g, buf_background_color.b }),
            content_right.x + 50,
            content_right.y + 170,
            20,
            theme.secondary,
        );
        rl.drawRectangleLines(content_right.x + 400, content_right.y + 170, 20, 20, theme.accent);
        rl.drawRectangle(content_right.x + 402, content_right.y + 172, 16, 16, theme.primary);

        // color
        rl.drawText(
            rl.textFormat("text color: # %02X%02X%02X ", .{ buf_text_color.r, buf_text_color.g, buf_text_color.b }),
            content_right.x + 50,
            content_right.y + 200,
            20,
            theme.secondary,
        );
        rl.drawRectangleLines(content_right.x + 400, content_right.y + 200, 20, 20, theme.accent);
        rl.drawRectangle(content_right.x + 402, content_right.y + 202, 16, 16, theme.primary);

        // font size
        rl.drawText(
            rl.textFormat("font size: {d}px ", .{buf_font_size}),
            content_right.x + 280,
            content_right.y + 230,
            20,
            theme.secondary,
        );
        rl.drawRectangleLines(content_right.x + 400, content_right.y + 230, 20, 20, theme.accent);
        rl.drawRectangle(content_right.x + 402, content_right.y + 232, 16, 16, theme.secondary);

        // padding
        rl.drawText(
            rl.textFormat("padding: {d}px {d}px {d}px {d}px", .{ buf_padding.top, buf_padding.right, buf_padding.bottom, buf_padding.left }),
            content_right.x + 50,
            content_right.y + 260,
            20,
            theme.secondary,
        );
        rl.drawRectangleLines(content_right.x + 400, content_right.y + 260, 20, 20, theme.accent);
        rl.drawRectangle(content_right.x + 402, content_right.y + 262, 16, 16, theme.primary);

        // margin
        rl.drawText(
            rl.textFormat("margin: {d}px {d}px {d}px {d}px ", .{ buf_margin.top, buf_margin.right, buf_margin.bottom, buf_margin.left }),
            content_right.x + 50,
            content_right.y + 290,
            20,
            theme.secondary,
        );
        rl.drawRectangleLines(content_right.x + 400, content_right.y + 290, 20, 20, theme.accent);
        rl.drawRectangle(content_right.x + 402, content_right.y + 292, 16, 16, theme.primary);

        if (rg.button(.{ .x = content_right.x + 400, .y = content_right.y + 350, .width = 300, .height = 100 }, "randomize")) {
            const rand = prng.random();
            buf_background_color = .{
                .r = rand.intRangeAtMost(u8, 0, 255),
                .g = rand.intRangeAtMost(u8, 0, 255),
                .b = rand.intRangeAtMost(u8, 0, 255),
            };
            buf_text_color = .{
                .r = rand.intRangeAtMost(u8, 0, 255),
                .g = rand.intRangeAtMost(u8, 0, 255),
                .b = rand.intRangeAtMost(u8, 0, 255),
            };
            buf_font_size = rand.intRangeAtMost(u8, 10, 32);
            buf_padding = .{
                .top = rand.intRangeAtMost(u8, 0, 255),
                .right = rand.intRangeAtMost(u8, 0, 255),
                .bottom = rand.intRangeAtMost(u8, 0, 255),
                .left = rand.intRangeAtMost(u8, 0, 255),
            };

            buf_margin = .{
                .top = rand.intRangeAtMost(u8, 0, 255),
                .right = rand.intRangeAtMost(u8, 0, 255),
                .bottom = rand.intRangeAtMost(u8, 0, 255),
                .left = rand.intRangeAtMost(u8, 0, 255),
            };
        }

        rl.endDrawing();
    }
    state.*.app_state = .closing;
}
