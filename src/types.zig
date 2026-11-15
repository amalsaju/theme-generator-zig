pub const Tag = enum {
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
    html_tag: Tag,
    level: u8,
    //left_node: u1 = 0,
    // raylib requires null terminated strings
    selector: [:0]const u8, // unique value to select this element
};

pub const CSSProperty = enum {
    background_color,
    color,
};

pub const ColorValue = struct {
    r: u8,
    g: u8,
    b: u8,
};

pub const EdgeValue = struct {
    left: i8,
    right: i8,
    top: i8,
    bottom: i8,
};

pub const CSSPropertyValue = union(enum) {
    color_value: ColorValue,
    edge_value: EdgeValue,
};

// TODO: Add in ids and classes
pub const CSSPropertyChangeEvent = struct {
    element: u8, // which element is being changed
    css_property: CSSProperty,
    css_property_value: CSSPropertyValue,
};

pub const Event = union(enum) {
    highlight: ?u8, // highlight event
    change_property: CSSPropertyChangeEvent,
};
