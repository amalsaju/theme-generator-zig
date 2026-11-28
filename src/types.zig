pub const string = struct {
    value: [255]u8 = undefined,
    length: u8 = 0,
};
pub const tag = enum {
    html,
    body,
    header,
    hgroup,
    h1,
    h2,
    h3,
    h4,
    h5,
    h6,
    img,
    main,
    nav,
    section,
    article,
    div,
    p,
    b,
    i,
    span,
    a,
    ol,
    ul,
    li,
    select,
    option,
    label,
    time,
    button,
    address,
};
pub const html_element_group_id = struct {
    html_id: []const u8,
    element_id: u16, // uses the same id of the html_element
};
pub const html_element_group_class_names = struct {
    class_name: []const u8,
    // max 63 elements with the same class name
    // uses the same id of the html_element
    elements_id: []const u16,
    count_elements: u6,
};

pub const html_element = struct {
    id: u16,
    html_tag: tag,
    level: u8,
    //left_node: u1 = 0,
    // raylib requires null terminated strings
    selector: [:0]const u8, // unique value to select this element
};
pub const css_property_names = [_][]const u8{
    "background-color",
    "color",
    "font-size",
    "margin",
    "padding",
};

pub const css_property = enum {
    background_color,
    color,
    font_size,
    margin,
    padding,
};

pub const color_value = struct {
    r: u8,
    g: u8,
    b: u8,
};

pub const edge_value = struct {
    left: i32,
    right: i32,
    top: i32,
    bottom: i32,
};

pub const css_property_value = union(enum) {
    color_value: color_value,
    edge_value: edge_value,
    size_value: i32,
};

pub const css_declaration = struct {
    css_property: css_property,
    css_property_value: css_property_value,
};

pub const css_target = union(enum) {
    selector: u16,
    tag: tag,
    id: u16,
    //class: u16,
};

pub const css_property_change_event = struct {
    target: css_target,
    css_property: css_property,
    css_property_value: css_property_value,
};

pub const selector_type = enum {
    id, // html id property
    selector, // the full path
    class, // which class the declaration applies to, check the class array
    tag, // html element
};

pub const style = struct {
    id: u8, // id in the data file
    id_css_declarations: [255]css_declaration,
    selector_css_declarations: [255]css_declaration,
    tag_css_declarations: [255]css_declaration,

    html_id: string,
    // you don't need the selector and tag, you can get them from the data file
    // selector: string,
    // tag: string,

    id_css_declarations_count: u8,
    selector_css_declarations_count: u8,
    tag_css_declarations_count: u8,
};

pub const event = union(enum) {
    highlight: ?u8, // highlight event
    change_property: css_property_change_event,
};
