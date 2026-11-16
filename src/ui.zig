const std = @import("std");
const log = std.log.scoped(.server);
const rl = @import("raylib");
const rg = @import("raygui");
const data = @import("data.zig");
const shared_state = @import("shared_state.zig").State;
const Event = @import("types.zig").Event;
const Theme = @import("theme.zig").Theme;

const MouseButtonState = enum { normal, hover, pressed };
const ThemeStyle = enum { light, dark };

pub fn run(io: std.Io, state: *shared_state) !void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth = 900;
    const screenHeight = 450;

    var state_mouse_button: MouseButtonState = .normal;
    var theme_style: ThemeStyle = .dark;

    //var show_color_picker: bool = false;

    //var color_selected = rl.Color{ .r = 150, .g = 150, .b = 150, .a = 1 };

    rl.initWindow(screenWidth, screenHeight, "MelbCSS Theme Generator");
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    const row_height: u32 = 20;
    var scroll_content_offset: rl.Vector2 = .{ .x = 0, .y = 0 };
    var view: rl.Rectangle = .{ .x = 0, .y = 0, .width = 0, .height = 0 };
    const content: rl.Rectangle = .{ .x = 20, .y = 20, .width = 200, .height = data.html_elements.len * 30 };

    const indent_width_text: i32 = 10;
    var start_position_element: i32 = 0;
    var hover_id: u32 = 0;
    var selected_id: u32 = 0;

    var order_spinner: i32 = 20;
    var order_value_box: i32 = 20;
    //const indent_width_connection: i32 = 5;

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

        rg.setStyle(.default, .background_color, @intCast(rl.colorToInt(theme.background)));
        _ = rg.scrollPanel(
            .{ .x = 0, .y = 0, .width = 250, .height = 700 },
            null,
            content,
            &scroll_content_offset,
            &view,
        );
        scroll_content_offset.y = @min(0, scroll_content_offset.y);
        //log.info("Scroll: {}", .{scroll_content_offset});
        start_position_element = @divCeil(@as(i32, @intFromFloat(scroll_content_offset.y)), row_height);
        //log.info("Start position: {}", .{start_position_element});
        //log.info("Scroll content offset: {}", .{@as(i32, @intFromFloat(scroll_content_offset.y))});

        const view_list = data.html_elements[@abs(start_position_element)..];
        const mouse_position = rl.Vector2{ .x = @floatFromInt(rl.getMouseX() - 20), .y = @floatFromInt(rl.getMouseY() - 20) }; // the padding
        var send_data_id_previous: ?u32 = 0;

        if (rl.checkCollisionPointRec(mouse_position, view)) {
            state_mouse_button = .hover;
            log.info("Mouse inside view: {}", .{mouse_position});
            hover_id = @abs(@divFloor(@as(i32, @intFromFloat(mouse_position.y)), row_height));

            if (send_data_id_previous != hover_id + @abs(start_position_element)) {
                const event: Event = .{
                    .highlight = @as(u8, @intCast(hover_id + @abs(start_position_element))),
                };
                _ = state.*.event_queue.put(io, &.{event}, 0) catch |err| {
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
        } else {
            state_mouse_button = .normal;
            if (send_data_id_previous != null) {
                const event: Event = .{
                    .highlight = null,
                };
                _ = state.*.event_queue.put(io, &.{event}, 0) catch |err| {
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

        for (view_list, 0..) |value, i| {
            const level: i32 = @intCast(value.level);
            const index: i32 = @intCast(i);

            const x = @as(i32, @intFromFloat(content.x)) + (level * indent_width_text);
            const y = @as(i32, @intFromFloat(content.y)) + index * row_height;

            if (value.id == data.html_elements[selected_id].id) {
                rl.drawRectangleRounded(.{ .x = content.x - 6.0, .y = @as(f32, @floatFromInt(y)) - 6.0, .width = content.width, .height = 22 }, 0.40, 0, theme.secondary);
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
                rl.drawRectangleRounded(.{ .x = content.x - 6.0, .y = @as(f32, @floatFromInt(y)) - 6.0, .width = content.width, .height = 22 }, 0.40, 0, theme.secondary);
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
        rl.drawText(
            data.html_elements[selected_id].selector,
            400,
            400,
            20,
            .red,
        );

        _ = rg.spinner(.{ .x = 400, .y = 100, .width = 70, .height = 20 }, "Spinner", &order_spinner, 0, 100, true);
        _ = rg.valueBox(.{ .x = 400, .y = 200, .width = 70, .height = 20 }, "Value box", &order_value_box, 0, 100, true);

        rl.endDrawing();
    }
}
