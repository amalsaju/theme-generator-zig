const rl = @import("raylib");

pub fn returnRegularFont() !void {
    return rl.loadFontEx("assets/fonts/NotoSans-Regular.ttf", 32, null);
}

pub fn returnBoldFont() void {}

pub fn returnSemiBoldFont() void {}

pub fn returnItalicFont() void {}
