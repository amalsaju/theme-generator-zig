// Generated from https://github.com/melbcssmeetup/website/blob/main/index.html
// HTML elements in document order. Array index == html_element.id.
// Only the page structure is included: <head> and <script> are omitted.
// CSS selectors uniquely match one element in the static source.

const html_element = @import("types.zig").html_element;
const html_element_id = @import("types.zig").html_element_group_id;
const html_element_class = @import("types.zig").html_element_group_class_names;
const css_declaration = @import("types.zig").css_declaration;

pub fn get_element_selector_from_id(id: u8) [:0]const u8 {
    if (id >= html_elements.len) return html_elements[html_elements.len - 1].selector;
    return html_elements[id].selector;
}

pub const html_elements = [_]html_element{
    .{ .id = 0, .html_tag = .html, .level = 0, .selector = "html" },
    .{ .id = 1, .html_tag = .body, .level = 1, .selector = "body" },
    .{ .id = 2, .html_tag = .header, .level = 2, .selector = "body > header" },
    .{ .id = 3, .html_tag = .hgroup, .level = 3, .selector = "body > header > hgroup" },
    .{ .id = 4, .html_tag = .h1, .level = 4, .selector = "body > header > hgroup > h1" },
    .{ .id = 5, .html_tag = .img, .level = 5, .selector = "body > header > hgroup > h1 > img" },
    .{ .id = 6, .html_tag = .p, .level = 4, .selector = "body > header > hgroup > p" },
    .{ .id = 7, .html_tag = .main, .level = 2, .selector = "body > main" },
    .{ .id = 8, .html_tag = .p, .level = 3, .selector = "body > main > p" },
    .{ .id = 9, .html_tag = .nav, .level = 3, .selector = "body > main > nav" },
    .{ .id = 10, .html_tag = .ul, .level = 4, .selector = "body > main > nav > ul" },
    .{ .id = 11, .html_tag = .li, .level = 5, .selector = "body > main > nav > ul > li:nth-of-type(1)" },
    .{ .id = 12, .html_tag = .a, .level = 6, .selector = "body > main > nav > ul > li:nth-of-type(1) > a" },
    .{ .id = 13, .html_tag = .span, .level = 7, .selector = "body > main > nav > ul > li:nth-of-type(1) > a > span" },
    .{ .id = 14, .html_tag = .li, .level = 5, .selector = "body > main > nav > ul > li:nth-of-type(2)" },
    .{ .id = 15, .html_tag = .a, .level = 6, .selector = "body > main > nav > ul > li:nth-of-type(2) > a" },
    .{ .id = 16, .html_tag = .span, .level = 7, .selector = "body > main > nav > ul > li:nth-of-type(2) > a > span" },
    .{ .id = 17, .html_tag = .li, .level = 5, .selector = "body > main > nav > ul > li:nth-of-type(3)" },
    .{ .id = 18, .html_tag = .a, .level = 6, .selector = "body > main > nav > ul > li:nth-of-type(3) > a" },
    .{ .id = 19, .html_tag = .span, .level = 7, .selector = "body > main > nav > ul > li:nth-of-type(3) > a > span" },
    .{ .id = 20, .html_tag = .li, .level = 5, .selector = "body > main > nav > ul > li:nth-of-type(4)" },
    .{ .id = 21, .html_tag = .a, .level = 6, .selector = "body > main > nav > ul > li:nth-of-type(4) > a" },
    .{ .id = 22, .html_tag = .span, .level = 7, .selector = "body > main > nav > ul > li:nth-of-type(4) > a > span" },
    .{ .id = 23, .html_tag = .li, .level = 5, .selector = "body > main > nav > ul > li:nth-of-type(5)" },
    .{ .id = 24, .html_tag = .a, .level = 6, .selector = "body > main > nav > ul > li:nth-of-type(5) > a" },
    .{ .id = 25, .html_tag = .span, .level = 7, .selector = "body > main > nav > ul > li:nth-of-type(5) > a > span" },
    .{ .id = 26, .html_tag = .section, .level = 3, .selector = "body > main > section:nth-of-type(1)" },
    .{ .id = 27, .html_tag = .h2, .level = 4, .selector = "body > main > section:nth-of-type(1) > h2" },
    .{ .id = 28, .html_tag = .article, .level = 4, .selector = "body > main > section:nth-of-type(1) > article" },
    .{ .id = 29, .html_tag = .h3, .level = 5, .selector = "body > main > section:nth-of-type(1) > article > h3" },
    .{ .id = 30, .html_tag = .time, .level = 5, .selector = "body > main > section:nth-of-type(1) > article > time" },
    .{ .id = 31, .html_tag = .a, .level = 5, .selector = "body > main > section:nth-of-type(1) > article > a" },
    .{ .id = 32, .html_tag = .address, .level = 6, .selector = "body > main > section:nth-of-type(1) > article > a > address" },
    .{ .id = 33, .html_tag = .section, .level = 3, .selector = "body > main > section:nth-of-type(2)" },
    .{ .id = 34, .html_tag = .button, .level = 4, .selector = "body > main > section:nth-of-type(2) > button" },
    .{ .id = 35, .html_tag = .label, .level = 4, .selector = "body > main > section:nth-of-type(2) > label" },
    .{ .id = 36, .html_tag = .select, .level = 4, .selector = "body > main > section:nth-of-type(2) > select" },
    .{ .id = 37, .html_tag = .option, .level = 5, .selector = "body > main > section:nth-of-type(2) > select > option:nth-of-type(1)" },
    .{ .id = 38, .html_tag = .option, .level = 5, .selector = "body > main > section:nth-of-type(2) > select > option:nth-of-type(2)" },
    .{ .id = 39, .html_tag = .option, .level = 5, .selector = "body > main > section:nth-of-type(2) > select > option:nth-of-type(3)" },
    .{ .id = 40, .html_tag = .option, .level = 5, .selector = "body > main > section:nth-of-type(2) > select > option:nth-of-type(4)" },
    .{ .id = 41, .html_tag = .option, .level = 5, .selector = "body > main > section:nth-of-type(2) > select > option:nth-of-type(5)" },
    .{ .id = 42, .html_tag = .option, .level = 5, .selector = "body > main > section:nth-of-type(2) > select > option:nth-of-type(6)" },
    .{ .id = 43, .html_tag = .option, .level = 5, .selector = "body > main > section:nth-of-type(2) > select > option:nth-of-type(7)" },
    .{ .id = 44, .html_tag = .a, .level = 4, .selector = "body > main > section:nth-of-type(2) > a" },
};

pub const html_element_ids = [_]html_element_id{
    .{ .html_id = "events-title", .element_id = 27 },
    .{ .html_id = "mode-toggle", .element_id = 34 },
    .{ .html_id = "style-select", .element_id = 36 },
};

pub const html_element_classes = [_]html_element_class{
    .{
        .class_name = "link-button",
        .elements_id = .{ 12, 15, 18, 21, 24, 34 },
        .count_elements = 6,
    },
    .{
        .class_name = "icon",
        .elements_id = .{ 13, 16, 19, 22, 25 },
        .count_elements = 5,
    },
    .{
        .class_name = "discord-icon",
        .elements_id = .{13},
        .count_elements = 1,
    },
    .{
        .class_name = "youtube-icon",
        .elements_id = .{16},
        .count_elements = 1,
    },
    .{
        .class_name = "github-icon",
        .elements_id = .{19},
        .count_elements = 1,
    },
    .{
        .class_name = "mic-icon",
        .elements_id = .{22},
        .count_elements = 1,
    },
    .{
        .class_name = "linkedin-icon",
        .elements_id = .{25},
        .count_elements = 1,
    },
    .{
        .class_name = "controls",
        .elements_id = .{33},
        .count_elements = 1,
    },
};
