const std = @import("std");
const squarify = @import("squarify.zig");
const rl = @import("raylib");

const Data = struct {
    name: [:0]const u8,
    color: rl.Color,
};

const Squarify = squarify.Squarify(Data);
const Node = squarify.Node(Data);
const Tree = @import("tree.zig").Tree(Data);

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var root = Node{
        .value = 1000,
        .data = Data{
            .name = "root",
            .color = rl.Color{ .r = 255, .g = 255, .b = 255, .a = 255 },
        },
    };

    var file_tree = Tree.init(allocator, &root);
    defer file_tree.deinit();

    const folder1 = try file_tree.addNode(&root, 200, .{
        .name = "folder1",
        .color = rl.Color{ .r = 128, .g = 128, .b = 255, .a = 255 },
    });

    _ = try file_tree.addNode(folder1, 50, .{
        .name = "file1",
        .color = rl.Color{ .r = 255, .g = 128, .b = 128, .a = 255 },
    });

    _ = try file_tree.addNode(folder1, 150, .{
        .name = "file2",
        .color = rl.Color{ .r = 128, .g = 255, .b = 128, .a = 255 },
    });

    const folder2 = try file_tree.addNode(&root, 800, .{
        .name = "folder2",
        .color = rl.Color{ .r = 200, .g = 150, .b = 100, .a = 255 },
    });

    _ = try file_tree.addNode(folder2, 300, .{
        .name = "file3",
        .color = rl.Color{ .r = 0, .g = 255, .b = 200, .a = 255 },
    });

    _ = try file_tree.addNode(folder2, 500, .{
        .name = "file4",
        .color = rl.Color{ .r = 255, .g = 255, .b = 128, .a = 255 },
    });

    const container = squarify.Rect{
        .x = 0,
        .y = 0,
        .width = 800,
        .height = 450,
    };

    const sq = Squarify.init(std.heap.page_allocator);
    const results = try sq.squarify(container, &root) orelse unreachable;

    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth = container.width;
    const screenHeight = container.height;

    rl.initWindow(screenWidth, screenHeight, "raylib-zig [core] example - basic window");
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Update
        //----------------------------------------------------------------------------------
        // TODO: Update your variables here
        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.white);

        for (results.items) |res| {
            const rect = rl.Rectangle{
                .x = res.rect.x,
                .y = res.rect.y,
                .width = res.rect.width,
                .height = res.rect.height,
            };

            rl.drawRectangleRec(rect, res.node.data.color);
            rl.drawRectangleLinesEx(rect, 1.0, rl.Color.black);
            rl.drawText(res.node.data.name.ptr, @intFromFloat(rect.x + 2), @intFromFloat(rect.y + 2), 12, rl.Color.black);
        }
        //----------------------------------------------------------------------------------
    }
}
