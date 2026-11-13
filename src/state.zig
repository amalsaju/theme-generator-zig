const std = @import("std");

var State = struct {};

var has_changed = std.atomic.Value(bool).init(false);
