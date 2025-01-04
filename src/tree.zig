const std = @import("std");

const AutoHashMap = std.AutoHashMap;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const Node = @import("squarify.zig").Node;

pub fn Tree(DataType: type) type {
    return struct {
        const Self = @This();

        allocator: Allocator,
        child_map: AutoHashMap(*Node(DataType), ArrayList(*Node(DataType))),
        root: *Node(DataType),

        pub fn init(allocator: Allocator, root: *Node(DataType)) Self {
            return Self{
                .allocator = allocator,
                .child_map = AutoHashMap(*Node(DataType), ArrayList(*Node(DataType))).init(allocator),
                .root = root,
            };
        }

        pub fn deinit(self: *Self) void {
            var iter = self.child_map.valueIterator();
            while (iter.next()) |list| {
                for (list.items) |node| {
                    self.allocator.destroy(node);
                }
                list.deinit();
            }

            self.child_map.deinit();
        }

        pub fn addNode(self: *Self, parent: *Node(DataType), value: f32, data: DataType) !*Node(DataType) {
            const node = try self.allocator.create(Node(DataType));
            node.* = Node(DataType){
                .data = data,
                .value = value,
            };

            const get_children_result = try self.child_map.getOrPut(parent);
            if (!get_children_result.found_existing) {
                get_children_result.value_ptr.* = ArrayList(*Node(DataType)).init(self.allocator);
            }

            var child_list = get_children_result.value_ptr;
            try child_list.append(node);

            parent.children = child_list.items;

            return node;
        }
    };
}
