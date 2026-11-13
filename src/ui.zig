const std = @import("std");
const log = std.log.scoped(.server);
const rl = @import("raylib");
const rg = @import("raygui");
const data = @import("data.zig");

const MouseButtonState = enum { normal, hover, pressed };

pub fn run() !void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth = 900;
    const screenHeight = 450;

    var state_mouse_button: MouseButtonState = .normal;

    //var show_color_picker: bool = false;

    //var color_selected = rl.Color{ .r = 150, .g = 150, .b = 150, .a = 1 };

    rl.initWindow(screenWidth, screenHeight, "MelbCSS Theme Generator");
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    const row_height: u32 = 20;
    var scroll_content_offset: rl.Vector2 = .{ .x = 0, .y = 0 };
    var view: rl.Rectangle = .{ .x = 0, .y = 0, .width = 0, .height = 0 };
    const content: rl.Rectangle = .{ .x = 20, .y = 20, .width = 200, .height = 1200 };

    const indent_width_text: i32 = 10;
    var start_position_element: i32 = 0;
    var hover_id: u32 = 0;
    var selected_id: u32 = 0;
    //const indent_width_connection: i32 = 5;

    // Main game loop
    while (!rl.windowShouldClose()) {
        rl.beginDrawing();

        rl.clearBackground(.white);

        _ = rg.scrollPanel(
            .{ .x = 0, .y = 0, .width = 250, .height = 700 },
            null,
            content,
            &scroll_content_offset,
            &view,
        );
        scroll_content_offset.y = @min(0, scroll_content_offset.y);
        log.info("Scroll: {}", .{scroll_content_offset});
        start_position_element = @divCeil(@as(i32, @intFromFloat(scroll_content_offset.y)), row_height);
        log.info("Start position: {}", .{start_position_element});
        log.info("Scroll content offset: {}", .{@as(i32, @intFromFloat(scroll_content_offset.y))});

        const view_list = data.html_elements[@abs(start_position_element)..];
        const mouse_position = rl.Vector2{ .x = @floatFromInt(rl.getMouseX() - 20), .y = @floatFromInt(rl.getMouseY() - 20) }; // the padding

        if (rl.checkCollisionPointRec(mouse_position, view)) {
            state_mouse_button = .hover;
            log.info("Mouse inside view: {}", .{mouse_position});
            hover_id = @abs(@divFloor(@as(i32, @intFromFloat(mouse_position.y)), row_height));
            if (rl.isMouseButtonDown(rl.MouseButton.left)) {
                state_mouse_button = .pressed;
            }
            if (rl.isMouseButtonUp(rl.MouseButton.left)) {
                state_mouse_button = .normal;
            }

            log.info("Selected Id: {}", .{hover_id});
        } else {
            state_mouse_button = .normal;
        }

        if (state_mouse_button == .pressed) {
            selected_id = hover_id + @abs(start_position_element);
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

            if (i == hover_id) {
                rl.drawRectangle(content.x, y - 4, content.width, 20, .yellow);
                rl.drawText(
                    @tagName(value.html_tag),
                    x,
                    y - 4,
                    20,
                    .blue,
                );
            } else if (value.id == data.html_elements[selected_id].id) {
                rl.drawText(
                    @tagName(value.html_tag),
                    x,
                    y - 4,
                    20,
                    .red,
                );
            } else {
                rl.drawText(
                    @tagName(value.html_tag),
                    x,
                    y - 4,
                    20,
                    .black,
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
        rl.endDrawing();
    }
}
