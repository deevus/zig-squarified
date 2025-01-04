const std = @import("std");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

pub const Rect = struct {
    x: f32,
    y: f32,
    width: f32,
    height: f32,

    pub fn area(self: Rect) f32 {
        return self.width * self.height;
    }

    pub fn cut(self: Rect, area_value: f32) Rect {
        if (self.width > self.height) {
            const area_width = area_value / self.height;
            const new_width = self.width - area_width;

            return Rect{
                .x = self.x + area_width,
                .y = self.y,
                .width = new_width,
                .height = self.height,
            };
        } else {
            const area_height = area_value / self.width;
            const new_height = self.height - area_height;

            return Rect{
                .x = self.x,
                .y = self.y + area_height,
                .width = self.width,
                .height = new_height,
            };
        }
    }
};

pub fn Node(DataType: type) type {
    return struct {
        value: f32,
        data: DataType,
        children: ?[]*Node(DataType) = null,
        parent: ?*Node(DataType) = null,
    };
}

fn NormalisedNode(DataType: type) type {
    return struct {
        value: f32,
        node: *Node(DataType),
    };
}

pub fn Result(DataType: type) type {
    return struct {
        rect: Rect,
        value: f32,
        node: *Node(DataType),
    };
}

pub fn Squarify(DataType: type) type {
    return struct {
        const Self = @This();

        allocator: Allocator,

        pub fn init(allocator: Allocator) Self {
            return Self{
                .allocator = allocator,
            };
        }

        pub fn squarify(self: Self, container: Rect, root: *Node(DataType)) !?ArrayList(Result(DataType)) {
            const maybe_result = try self.recurse(root, container);

            if (maybe_result) |result| {
                return result;
            }

            return null;
        }

        fn normalise(self: Self, children: []*Node(DataType), rect: Rect) !ArrayList(NormalisedNode(DataType)) {
            const area = rect.area();

            var sum: f32 = 0;
            for (children) |child| {
                sum += child.value;
            }

            var result = try ArrayList(NormalisedNode(DataType)).initCapacity(self.allocator, children.len);

            const scale: f32 = area / sum;

            for (children) |node| {
                try result.append(.{
                    .value = node.value * scale,
                    .node = node,
                });
            }

            return result;
        }

        fn getCoordinates(self: Self, row: []const NormalisedNode(DataType), rect: Rect) !ArrayList(Result(DataType)) {
            var value_sum: f32 = 0;
            for (row) |node| {
                value_sum += node.value;
            }

            const width = rect.width;
            const height = rect.height;
            const x = rect.x;
            const y = rect.y;

            const area_width = value_sum / height;
            const area_height = value_sum / width;

            var sub_x = x;
            var sub_y = y;

            var coordinates = try ArrayList(Result(DataType)).initCapacity(self.allocator, row.len);

            if (width > height) {
                for (row) |node| {
                    const new_rect = Rect{
                        .x = sub_x,
                        .y = sub_y,
                        .width = area_width,
                        .height = node.value / area_width,
                    };

                    sub_y += node.value / area_width;

                    try coordinates.append(.{
                        .rect = new_rect,
                        .value = node.node.value,
                        .node = node.node,
                    });
                }
            } else {
                for (row) |node| {
                    const new_rect = Rect{
                        .x = sub_x,
                        .y = sub_y,
                        .width = node.value / area_height,
                        .height = area_height,
                    };

                    sub_x += node.value / area_height;

                    try coordinates.append(.{
                        .rect = new_rect,
                        .value = node.node.value,
                        .node = node.node,
                    });
                }
            }

            return coordinates;
        }

        fn getShortestEdge(rect: Rect) f32 {
            return if (rect.width < rect.height) rect.width else rect.height;
        }

        fn calculateMaxAspectRatio(row: []const NormalisedNode(DataType), length: f32) f32 {
            var min_area: f32 = 0;
            var max_area: f32 = 0;
            var sum_area: f32 = 0;

            for (row) |node| {
                min_area += node.value;

                if (node.value < min_area) {
                    min_area = node.value;
                }

                if (node.value > max_area) {
                    max_area = node.value;
                }

                sum_area += node.value;
            }

            return @max(
                std.math.pow(f32, length, 2) * max_area / std.math.pow(f32, sum_area, 2),
                std.math.pow(f32, sum_area, 2) / (std.math.pow(f32, length, 2) * min_area),
            );
        }

        fn doesAddingToRowImproveAspectRatio(
            self: Self,
            current_row: []const NormalisedNode(DataType),
            next_datum: NormalisedNode(DataType),
            length: f32,
        ) !bool {
            if (current_row.len == 0) {
                return true;
            }

            var new_row = try ArrayList(NormalisedNode(DataType)).initCapacity(self.allocator, current_row.len + 1);
            defer new_row.deinit();
            try new_row.appendSlice(current_row);
            try new_row.append(next_datum);

            const current_aspect_ratio = calculateMaxAspectRatio(current_row, length);
            const new_aspect_ratio = calculateMaxAspectRatio(new_row.items, length);

            return current_aspect_ratio >= new_aspect_ratio;
        }

        fn squarifyChildren(self: Self, input_data: []const NormalisedNode(DataType), rect: Rect) !ArrayList(Result(DataType)) {
            var current_data = input_data;

            var current_row = ArrayList(NormalisedNode(DataType)).init(self.allocator);
            defer current_row.deinit();

            var current_rect = rect;

            var stack = ArrayList(Result(DataType)).init(self.allocator);

            while (true) {
                if (current_data.len == 0) {
                    const new_coordinates = try self.getCoordinates(current_row.items, current_rect);
                    defer new_coordinates.deinit();

                    try stack.appendSlice(new_coordinates.items);
                    return stack;
                }

                const width = getShortestEdge(current_rect);
                const next_datum = current_data[0];
                const rest_data = current_data[1..];
                // const rest_values = current_normalised_values.items[1..];

                if (try self.doesAddingToRowImproveAspectRatio(
                    current_row.items,
                    next_datum,
                    width,
                )) {
                    current_data = rest_data;
                    try current_row.append(next_datum);
                } else {
                    var area_sum: f32 = 0;
                    for (current_row.items) |node| {
                        area_sum += node.value;
                    }

                    const new_coordinates = try self.getCoordinates(current_row.items, current_rect);
                    defer new_coordinates.deinit();

                    current_rect = rect.cut(area_sum);
                    current_row.clearAndFree();

                    try stack.appendSlice(new_coordinates.items);
                }
            }

            unreachable;
        }

        fn recurse(self: Self, node: *Node(DataType), rect: Rect) !?ArrayList(Result(DataType)) {
            const has_children = if (node.children) |children| children.len > 0 else false;

            if (!has_children) {
                return null;
            }

            var normalised = try self.normalise(node.children.?, rect);
            defer normalised.deinit();

            var squarified = try self.squarifyChildren(normalised.items, rect);
            defer squarified.deinit();

            var contained = ArrayList(Result(DataType)).init(self.allocator);
            for (squarified.items) |result| {
                try contained.append(result);

                const inner_result = try self.recurse(result.node, result.rect);
                if (inner_result) |*inner| {
                    try contained.appendSlice(inner.items);
                    inner.deinit();
                }
            }

            return contained;
        }
    };
}

const testing = std.testing;

test "Squarify" {
    const squarify = Squarify(f32).init(testing.allocator);

    const root = Node(f32){
        .value = 100,
        .data = 0,
        .children = &.{
            .{ .value = 10, .data = 1, .children = null },
            .{ .value = 20, .data = 2, .children = null },
            .{ .value = 30, .data = 3, .children = null },
            .{ .value = 40, .data = 4, .children = null },
        },
    };

    const container = Rect{
        .x = 0,
        .y = 0,
        .width = 100,
        .height = 100,
    };

    const result = (try squarify.squarify(container, root)).?;
    defer result.deinit();

    try testing.expectEqual(4, result.items.len);
    try testing.expectEqual(10, result.items[0].value);
    try testing.expectEqual(20, result.items[1].value);
    try testing.expectEqual(30, result.items[2].value);
    try testing.expectEqual(40, result.items[3].value);
}
