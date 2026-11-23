const std = @import("std");
const event = @import("types.zig").event;
const string = @import("types.zig").string;
const style = @import("types.zig").style;
const css_declaration = @import("types.zig").css_declaration;

const application_state = enum {
    opening,
    ui_1,
    ui_2,
    closing,
};

pub const state = struct {
    storage: [64]event = undefined,
    event_queue: std.Io.Queue(event) = undefined,
    app_state: application_state = undefined,
    working_directory: [256:0]u8 = @splat(0),
    css_style_list: [50]style = undefined, // we only have a max of like 43 elements
    css_style_list_count: u8 = 0,
    theme_name: string = .{},
    author_name: string = .{},
    update_files: bool = false,

    pub fn init(self: *state) void {
        self.event_queue = .init(&self.storage);

        const default_theme_name = "DefaultTheme";
        const default_author_name = "Unknown";
        const default_path = "C:\\Users\\bolsh\\projects\\melb_css\\website";

        // add default author and theme values
        self.theme_name = .{
            .value = undefined,
            .length = 0,
        };

        @memcpy(self.theme_name.value[0..default_theme_name.len], default_theme_name);
        self.theme_name.length = default_theme_name.len;

        self.author_name = .{
            .value = undefined,
            .length = 0,
        };
        @memcpy(self.author_name.value[0..default_author_name.len], default_author_name);
        self.author_name.length = default_author_name.len;

        @memcpy(self.working_directory[0..default_path.len], default_path);
        self.app_state = .ui_1;
    }
};
