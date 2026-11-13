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
