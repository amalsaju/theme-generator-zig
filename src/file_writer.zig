const std = @import("std");
const shared_state = @import("shared_state.zig").state;
const log = std.log.scoped(.server);
const types = @import("types.zig");
const html_parsed_data = @import("data.zig").html_elements;
const css_property_names = @import("types.zig").css_property_names;

pub fn write_css_declaration(writer: *std.Io.Writer, declaration: types.css_declaration) !void {
    const name = css_property_names[@backingInt(declaration.css_property)];

    try writer.print("      {s}: ", .{name});

    switch (declaration.css_property_value) {
        .color_value => |color| {
            try writer.print("#{x:0>2}{x:0>2}{x:0>2}", .{ color.r, color.g, color.b });
        },
        .edge_value => |edge| {
            try writer.print("{d}px {d}px {d}px {d}px ", .{ edge.top, edge.right, edge.bottom, edge.left });
        },
        .size_value => |size| {
            try writer.print("{d}px ", .{size});
        },
    }

    try writer.writeAll(";\n");
}

pub fn write_rule(writer: *std.Io.Writer, selector: []const u8, declarations: []const types.css_declaration) !void {
    try writer.print("{s} {{\n", .{selector});
    for (declarations) |declaration| {
        try write_css_declaration(writer, declaration);
    }

    try writer.writeAll("}\n\n");
}

pub fn save_css(io: std.Io, state: *const shared_state) !void {
    const dir = try std.Io.Dir.openDirAbsolute(io, state.working_directory[0..], .{});
    defer dir.close(io);

    var path_buf: [255]u8 = undefined;
    const path = try std.fmt.bufPrint(&path_buf, "styles/{s}.css", .{state.theme_name.value[0..state.theme_name.length]});
    const file = try dir.createFile(io, path, .{});
    defer file.close(io);

    var buffer: [4096]u8 = undefined;
    var file_writer = file.writer(io, &buffer);
    const writer = &file_writer.interface;

    try writer.print("/* Theme: {s} | Author: {s} */\n\n", .{
        state.theme_name.value[0..state.theme_name.length],
        state.author_name.value[0..state.author_name.length],
    });

    // goes through all 50 styles
    for (state.css_style_list[0..state.css_style_list_count]) |style| {
        // all the ids
        if (style.id_css_declarations_count > 0) {
            var selector_buffer: [100]u8 = undefined;

            // add the hash in front of the id
            const selector = try std.mem.print(&selector_buffer, "#{s}", .{style.html_id.value[0..style.html_id.length]});
            try write_rule(writer, selector, style.id_css_declarations[0..style.id_css_declarations_count]);
        }

        // all the path selectors
        if (style.selector_css_declarations_count > 0) {
            const selector = std.mem.sliceTo(html_parsed_data[style.id].selector, 0); // the selector should be 0 terminated here I think
            try write_rule(writer, selector, style.selector_css_declarations[0..style.selector_css_declarations_count]);
        }
        // all the tag selectors
        if (style.tag_css_declarations_count > 0) {
            try write_rule(
                writer,
                @tagName(html_parsed_data[style.id].html_tag),
                style.selector_css_declarations[0..style.selector_css_declarations_count],
            );
        }
    }
    try writer.flush();
}

pub fn update_index_html(io: std.Io, state: *const shared_state) !void {
    const dir = try std.Io.Dir.openDirAbsolute(io, state.working_directory[0..], .{});
    defer dir.close(io);

    var index_html: [10 * 1024]u8 = undefined;
    const file = dir.readFile(io, "index.html", &index_html) catch unreachable;

    const pos = std.mem.lastIndexOf(u8, file, "</select>") orelse 0;
    var modified_html: [20 * 1024]u8 = undefined;
    var new_theme_buf: [255]u8 = undefined;
    const new_theme = try std.fmt.bufPrint(&new_theme_buf, "<option value=\"{s}.css\">{s} by {s}</option>\n", .{
        state.theme_name.value[0..state.theme_name.length],
        state.theme_name.value[0..state.theme_name.length],
        state.author_name.value[0..state.author_name.length],
    });

    const result_index_html = std.mem.print(modified_html[0..], "{s}{s}{s}", .{ file[0..pos], new_theme, file[pos..file.len] }) catch unreachable;

    try dir.writeFile(io, .{ .sub_path = "index.html", .data = result_index_html });
}
