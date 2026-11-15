const std = @import("std");
const Event = @import("types.zig").Event;

pub const State = struct {
    storage: [64]Event = undefined,
    event_queue: std.Io.Queue(Event) = undefined,

    pub fn init(self: *State) void {
        self.event_queue = .init(&self.storage);
    }
};
