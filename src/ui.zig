const std = @import("std");
const log = std.log.scoped(.server);
const rl = @import("raylib");
const rg = @import("raygui");
const data = @import("data.zig");
const shared_state = @import("shared_state.zig").state;
const event = @import("types.zig").event;
const Theme = @import("theme.zig").Theme;
const types = @import("types.zig");
const file_writer = @import("file_writer.zig");

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
    var scroll: rl.Vector2 = .{ .x = 0, .y = 0 };
    const bounds: rl.Rectangle = .{ .x = 0, .y = 0, .width = screenWidth, .height = screenHeight };

    var element_checkbox = true;
    var selector_checkbox = false;
    var id_checkbox = false;
    //var class_checkbox = false;

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

    // var theme_name_btn_active: i32 = 0;
    // var theme_name_secret_view_active: bool = false;
    // var author_name_btn_active: i32 = 0;
    // var author_name_secret_view_active: bool = false;

    var theme_name: [255]u8 = @splat(0);
    @memcpy(theme_name[0..state.theme_name.length], state.theme_name.value[0..state.theme_name.length]);
    var theme_name_editable: bool = false;
    var author_name: [256]u8 = @splat(0);
    @memcpy(author_name[0..state.author_name.length], state.author_name.value[0..state.author_name.length]);
    var author_name_editable: bool = false;

    var dependency_checked = false;

    // Main game loop
    while (!rl.windowShouldClose()) {
        if (rl.isKeyDown(rl.KeyboardKey.left_control) and rl.isKeyPressed(rl.KeyboardKey.t)) {
            if (theme_style == .light) {
                theme_style = .dark;
            } else {
                theme_style = .light;
            }
        }

        const theme: *const Theme = if (theme_style == .light) &Theme.Light else &Theme.Dark;

        rl.beginDrawing();

        rl.clearBackground(theme.background);

        if (state.app_state == .start_section) {
            rg.setStyle(.default, .text_color_normal, @intCast(rl.colorToInt(theme.foreground)));

            rg.setStyle(.default, .background_color, @intCast(rl.colorToInt(theme.background)));

            rg.setStyle(.button, .text_color_normal, @intCast(rl.colorToInt(theme.secondary_foreground)));
            rg.setStyle(.button, .base_color_normal, @intCast(rl.colorToInt(theme.secondary)));
            rg.setStyle(.button, .border_color_normal, @intCast(rl.colorToInt(theme.secondary)));

            rg.setStyle(.default, .text_size, 30);

            _ = rg.textBox(.{ .x = @floatFromInt(50), .y = @floatFromInt(50), .width = @floatFromInt(rg.getTextWidth(state.working_directory[0..]) + 100), .height = 50 }, state.*.working_directory[0..], false);
            if (rg.button(.{ .x = @floatFromInt(rg.getTextWidth(state.working_directory[0..]) + 50 + 130), .y = 50, .width = @floatFromInt(rg.getTextWidth("Check") + 20), .height = 40 }, "Check")) {
                dependency_checked = file_writer.check_dependencies(io, state);
            }

            rg.setStyle(.default, .text_size, 20);
            if (dependency_checked) {
                rg.setStyle(.default, .text_color_normal, @intCast(rl.colorToInt(theme.secondary)));
                _ = rg.label(
                    .{ .x = 50, .y = screenHeight - 30, .width = @floatFromInt(rg.getTextWidth("Dependencies Checked") + 20), .height = 20 },
                    "Dependencies Checked",
                );
            } else {
                rg.setStyle(.default, .text_color_normal, @intCast(rl.colorToInt(Theme.Light.destructive)));
                _ = rg.label(
                    .{ .x = 50, .y = screenHeight - 30, .width = @floatFromInt(rg.getTextWidth("Dependencies Unchecked") + 20), .height = 20 },
                    "Dependencies Unchecked",
                );
            }

            rl.drawLine(
                50,
                110,
                screenWidth - 50,
                110,
                theme.muted,
            );

            rg.setStyle(.default, .text_size, 20);
            rg.setStyle(.default, .text_color_normal, @intCast(rl.colorToInt(theme.foreground)));
            // Theme Name (no spaces, separate using _)
            _ = rg.label(.{ .x = 50, .y = 110, .width = @floatFromInt(rg.getTextWidth("Theme Name") + 20), .height = 40 }, "Theme Name");
            if (rg.textBox(.{ .x = 50, .y = 150, .width = 600, .height = 40 }, theme_name[0..254 :0], theme_name_editable) != false) {
                theme_name_editable = !theme_name_editable;
            }

            rg.setStyle(.button, .base_color_normal, @intCast(rl.colorToInt(theme.secondary)));
            rg.setStyle(.button, .text_color_normal, @intCast(rl.colorToInt(theme.secondary_foreground)));
            rg.setStyle(.button, .border_color_normal, @intCast(rl.colorToInt(theme.secondary)));

            if (rg.button(.{ .x = 670, .y = 150, .width = @floatFromInt(rg.getTextWidth("Save") + 20), .height = 40 }, "Save")) {
                const length: u8 = @intCast(std.mem.indexOfScalar(u8, &theme_name, 0) orelse 255);
                @memcpy(state.theme_name.value[0..length], theme_name[0..length]);

                state.theme_name.length = length;
            }

            // Author Name (no spaces, separate using _)
            _ = rg.label(.{ .x = 50, .y = 200, .width = @floatFromInt(rg.getTextWidth("Author Name") + 20), .height = 40 }, "Author Name");
            if (rg.textBox(.{ .x = 50, .y = 240, .width = 600, .height = 40 }, author_name[0..254 :0], author_name_editable) != false) {
                author_name_editable = !author_name_editable;
            }

            rg.setStyle(.button, .base_color_normal, @intCast(rl.colorToInt(theme.secondary)));
            rg.setStyle(.button, .text_color_normal, @intCast(rl.colorToInt(theme.secondary_foreground)));
            rg.setStyle(.button, .border_color_normal, @intCast(rl.colorToInt(theme.secondary)));

            if (rg.button(.{ .x = 670, .y = 240, .width = @floatFromInt(rg.getTextWidth("Save") + 20), .height = 40 }, "Save")) {
                const length: u8 = @intCast(std.mem.indexOfScalar(u8, &author_name, 0) orelse 255);
                @memcpy(state.author_name.value[0..length], author_name[0..length]);

                state.author_name.length = length;
            }

            rg.setStyle(.button, .base_color_normal, @intCast(rl.colorToInt(theme.primary)));
            rg.setStyle(.button, .text_color_normal, @intCast(rl.colorToInt(theme.primary_foreground)));
            rg.setStyle(.button, .border_color_normal, @intCast(rl.colorToInt(theme.primary)));
            if (rg.button(.{ .x = 50, .y = 300, .width = @floatFromInt(rg.getTextWidth("Start") + 20), .height = 40 }, "Start")) {
                std.log.info("Theme Name: {s}", .{state.theme_name.value[0..state.theme_name.length]});
                std.log.info("Author Name: {s}", .{state.author_name.value[0..state.author_name.length]});

                state.app_state = .main_section;
                std.log.info("Switching to UI State 2", .{});
                file_writer.create_css_file(io, state) catch |err| {
                    std.log.err("Unable to create css file : {any}", .{err});
                };
                file_writer.update_index_html(io, state) catch |err| {
                    std.log.err("Unable to update index html file : {any}", .{err});
                };
            }

            // _ = rg.textInputBox(
            //     .{ .x = 50, .y = 150, .width = 500, .height = 30 },
            //     "author_name",
            //     "Enter the author_name, no spaces",
            //     &state.*.author_name,
            //     20,
            //     "ok",
            //     &author_name_btn_active,
            //     &author_name_secret_view_active,
            // );

        } else if (state.app_state == .main_section) {
            rg.setStyle(.default, .text_color_normal, @intCast(rl.colorToInt(theme.foreground)));

            rg.setStyle(.default, .background_color, @intCast(rl.colorToInt(theme.background)));

            _ = rg.scrollPanel(
                .{ .x = 0, .y = 0, .width = 250, .height = screenHeight },
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
                    const added = state.event_queue.put(
                        io,
                        &.{event_to_sent},
                        0,
                    ) catch |err| blk: {
                        log.err("Error putting into event queue: {}", .{err});
                        break :blk 0;
                    };

                    if (added == 1) {
                        send_data_id_previous = selected_id;
                    } else {
                        log.warn("Highlight event dropped: queue full or unavailable", .{});
                    }

                    send_data_id_previous = hover_id + @abs(start_position_element);
                }

                if (rl.isMouseButtonDown(rl.MouseButton.left)) {
                    state_mouse_button = .pressed;
                }
                if (state_mouse_button == .pressed and rl.isMouseButtonUp(rl.MouseButton.left)) {
                    state_mouse_button = .normal;
                }

                //log.info("hover id: {}", .{hover_id});
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
                log.info("selected id: {}", .{selected_id});
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

            const text_width = rg.getTextWidth("Preview");
            if (rg.button(
                .{ .x = @floatFromInt(screenWidth - text_width - 100), .y = 100, .width = @floatFromInt(rg.getTextWidth("Preview") + 50), .height = 30 },
                "Preview",
            )) {
                state.app_state = .css_preview_section;
            }

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
            _ = rg.checkBox(.{ .x = content_right.x + 50, .y = content_right.y + 120, .width = 20, .height = 20 }, "element", &element_checkbox);
            _ = rg.checkBox(.{ .x = content_right.x + 175, .y = content_right.y + 120, .width = 20, .height = 20 }, "selector", &selector_checkbox);
            _ = rg.checkBox(.{ .x = content_right.x + 300, .y = content_right.y + 120, .width = 20, .height = 20 }, "id", &id_checkbox);
            // _ = rg.checkBox(.{ .x = content_right.x + 375, .y = content_right.y + 120, .width = 20, .height = 20 }, "class", &class_checkbox);

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
                rl.textFormat("font size: %dpx ", .{buf_font_size}),
                content_right.x + 50,
                content_right.y + 230,
                20,
                theme.secondary,
            );
            rl.drawRectangleLines(content_right.x + 400, content_right.y + 230, 20, 20, theme.accent);
            rl.drawRectangle(content_right.x + 402, content_right.y + 232, 16, 16, theme.secondary);

            // padding
            rl.drawText(
                rl.textFormat("padding: %dpx %dpx %dpx %dpx", .{ buf_padding.top, buf_padding.right, buf_padding.bottom, buf_padding.left }),
                content_right.x + 50,
                content_right.y + 260,
                20,
                theme.secondary,
            );
            rl.drawRectangleLines(content_right.x + 400, content_right.y + 260, 20, 20, theme.accent);
            rl.drawRectangle(content_right.x + 402, content_right.y + 262, 16, 16, theme.primary);

            // margin
            rl.drawText(
                rl.textFormat("margin: %dpx %dpx %dpx %dpx", .{ buf_margin.top, buf_margin.right, buf_margin.bottom, buf_margin.left }),
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

                // save the values into the styles
                if (element_checkbox) {
                    state.css_style_list[selected_id].tag_css_declarations[0] = .{
                        .css_property = .background_color,
                        .css_property_value = .{
                            .color_value = buf_background_color,
                        },
                    };
                    const event_to_sent: event = .{ .change_property = .{
                        .target = .{ .tag = data.html_elements[selected_id].html_tag },
                        .css_property = .background_color,
                        .css_property_value = .{
                            .color_value = buf_background_color,
                        },
                    } };
                    const added = state.event_queue.put(
                        io,
                        &.{event_to_sent},
                        0,
                    ) catch |err| blk: {
                        log.err("Error putting into event queue: {}", .{err});
                        break :blk 0;
                    };

                    if (added == 1) {
                        log.info("Change event added", .{});
                    } else {
                        log.warn("Change event dropped: queue full or unavailable", .{});
                    }

                    state.css_style_list[selected_id].tag_css_declarations[1] = .{
                        .css_property = .color,
                        .css_property_value = .{
                            .color_value = buf_text_color,
                        },
                    };

                    state.css_style_list[selected_id].tag_css_declarations[2] = .{
                        .css_property = .font_size,
                        .css_property_value = .{
                            .size_value = buf_font_size,
                        },
                    };
                    state.css_style_list[selected_id].tag_css_declarations[3] = .{
                        .css_property = .padding,
                        .css_property_value = .{
                            .edge_value = buf_padding,
                        },
                    };

                    state.css_style_list[selected_id].tag_css_declarations[4] = .{
                        .css_property = .margin,
                        .css_property_value = .{
                            .edge_value = buf_margin,
                        },
                    };

                    state.css_style_list[selected_id].tag_css_declarations_count = 5;
                }
                if (id_checkbox) {
                    state.css_style_list[selected_id].id_css_declarations[0] = .{
                        .css_property = .background_color,
                        .css_property_value = .{
                            .color_value = buf_background_color,
                        },
                    };
                    state.css_style_list[selected_id].id_css_declarations[1] = .{
                        .css_property = .color,
                        .css_property_value = .{
                            .color_value = buf_text_color,
                        },
                    };

                    state.css_style_list[selected_id].id_css_declarations[2] = .{
                        .css_property = .font_size,
                        .css_property_value = .{
                            .size_value = buf_font_size,
                        },
                    };
                    state.css_style_list[selected_id].id_css_declarations[3] = .{
                        .css_property = .padding,
                        .css_property_value = .{
                            .edge_value = buf_padding,
                        },
                    };

                    state.css_style_list[selected_id].id_css_declarations[4] = .{
                        .css_property = .margin,
                        .css_property_value = .{
                            .edge_value = buf_margin,
                        },
                    };

                    state.css_style_list[selected_id].id_css_declarations_count = 5;
                }
                if (selector_checkbox) {
                    state.css_style_list[selected_id].selector_css_declarations[0] = .{
                        .css_property = .background_color,
                        .css_property_value = .{
                            .color_value = buf_background_color,
                        },
                    };
                    state.css_style_list[selected_id].selector_css_declarations[1] = .{
                        .css_property = .color,
                        .css_property_value = .{
                            .color_value = buf_text_color,
                        },
                    };

                    state.css_style_list[selected_id].selector_css_declarations[2] = .{
                        .css_property = .font_size,
                        .css_property_value = .{
                            .size_value = buf_font_size,
                        },
                    };
                    state.css_style_list[selected_id].selector_css_declarations[3] = .{
                        .css_property = .padding,
                        .css_property_value = .{
                            .edge_value = buf_padding,
                        },
                    };

                    state.css_style_list[selected_id].selector_css_declarations[4] = .{
                        .css_property = .margin,
                        .css_property_value = .{
                            .edge_value = buf_margin,
                        },
                    };

                    state.css_style_list[selected_id].selector_css_declarations_count = 5;
                }

                file_writer.save_css(io, state) catch |err| {
                    std.log.err("Error preview file: {any}", .{err});
                };
            }
        } else if (state.app_state == .css_preview_section) {
            rg.setStyle(.default, .text_color_normal, @intCast(rl.colorToInt(theme.secondary)));

            var css_buffer: [20 * 1024]u8 = undefined;
            const dir = std.Io.Dir.openDirAbsolute(io, state.working_directory[0..], .{}) catch unreachable;
            defer dir.close(io);

            var path_buf: [255]u8 = undefined;
            const path = try std.fmt.bufPrint(&path_buf, "styles/{s}.css", .{state.theme_name.value[0..state.theme_name.length]});

            const css = try dir.readFile(io, path, &css_buffer);

            // if (css == error.BadPathName) {
            //     std.log.err("File not found {s}", .{path});
            //     state.app_state = .main_section;
            // }
            // const font_size = 16;
            const line_height = 24;

            std.log.info("CSS : {s}\n", .{css[0..css.len]});
            const line_count = std.mem.count(u8, css, "\n");
            std.log.info("CSS Line count : {d}", .{line_count});

            var view: rl.Rectangle = .{
                .x = 0,
                .y = 0,
                .width = @floatFromInt(screenWidth),
                .height = @floatFromInt(screenHeight),
            };
            const content: rl.Rectangle = .{
                .x = 20,
                .y = 20,
                .width = @floatFromInt(screenWidth - 30),
                .height = @floatFromInt(line_height * 100),
            };
            _ = rg.scrollPanel(bounds, null, content, &scroll, &view);

            var lines = std.mem.splitScalar(u8, css, '\n');
            var line_number: usize = 1;
            while (lines.next()) |line| : (line_number += 1) {
                const text_line_number = rl.textFormat("%d", .{line_number});
                const text_width_line_number = rl.measureText(text_line_number, 20);
                const position_y: i32 = ((@as(i32, @intCast(line_number))) * 20) + @as(i32, @intFromFloat(scroll.y));
                const position_x: i32 = 50 - text_width_line_number;
                rl.drawText(text_line_number, position_x, position_y, 20, theme.primary);

                var line_buffer: [4096]u8 = undefined;
                const line_text = std.mem.printSentinel(&line_buffer, "{s}", .{line}, 0) catch continue;
                rl.drawText(line_text, 50 + 20, position_y, 20, theme.primary);
            }

            const text_width = rg.getTextWidth("Back");
            if (rg.button(
                .{ .x = @floatFromInt(screenWidth - text_width - 100), .y = 100, .width = @floatFromInt(rg.getTextWidth("Back") + 50), .height = 30 },
                "Back",
            )) {
                state.app_state = .main_section;
            }
        }

        rl.endDrawing();
    }
    state.*.app_state = .closing;
}
