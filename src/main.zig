const std = @import("std");
const squarify = @import("squarify.zig");
const rl = @import("raylib");

const Data = struct {
    name: [:0]const u8,
    color: rl.Color,
};

const Squarify = squarify.Squarify(Data);
const Node = squarify.Node(Data);

pub fn main() !void {
    const file_tree = Node{
        .value = 1000,
        .data = Data{
            .name = "root",
            .color = rl.Color{ .r = 255, .g = 255, .b = 255, .a = 255 },
        },
        .children = &.{
            Node{
                .value = 200,
                .data = Data{
                    .name = "folder1",
                    .color = rl.Color{ .r = 128, .g = 128, .b = 255, .a = 255 },
                },
                .children = &.{
                    Node{
                        .value = 50,
                        .data = Data{
                            .name = "file1",
                            .color = rl.Color{ .r = 255, .g = 128, .b = 128, .a = 255 },
                        },
                        .children = null,
                    },
                    Node{
                        .value = 150,
                        .data = Data{
                            .name = "file2",
                            .color = rl.Color{ .r = 128, .g = 255, .b = 128, .a = 255 },
                        },
                        .children = null,
                    },
                },
            },
            Node{
                .value = 800,
                .data = Data{
                    .name = "folder2",
                    .color = rl.Color{ .r = 200, .g = 150, .b = 100, .a = 255 },
                },
                .children = &.{
                    Node{
                        .value = 300,
                        .data = Data{
                            .name = "file3",
                            .color = rl.Color{ .r = 0, .g = 255, .b = 200, .a = 255 },
                        },
                        .children = null,
                    },
                    Node{
                        .value = 500,
                        .data = Data{
                            .name = "file4",
                            .color = rl.Color{ .r = 255, .g = 255, .b = 128, .a = 255 },
                        },
                        .children = null,
                    },
                },
            },
        },
    };

    const container = squarify.Rect{
        .x = 0,
        .y = 0,
        .width = 800,
        .height = 450,
    };

    const sq = Squarify.init(std.heap.page_allocator);
    const results = try sq.squarify(container, file_tree) orelse unreachable;

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
