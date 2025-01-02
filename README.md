# zig-squarified

**A library for generating squarified treemap layouts in Zig.**

## Demo
```
zig build run
```
Runs a basic Raylib demo that displays a treemap.

![]("./assets/demo.png")

## Install as a Zig package
```
zig fetch git+https://github.com/deevus/zig-squarified.git --save=squarified
```
Import as a dependency in your `build.zig`:
```zig
const lib_squarified = b.dependency("squarified", {});
const module_squarified = lib_squarified.module("squarified");

exe.root_module.addImport("squarified", module_squarified);
```

## Usage
```zig
const squarify = @import("squarified");
const Squarify = squarify.Squarify(f32);

// Create your root node
const root = Node{
    .value = 100,
    .data = 0,
    .children = &[_]Node{
        Node{ .value = 50, .data = 1 },
        Node{ .value = 30, .data = 2 },
        Node{ .value = 20, .data = 3 },
    },
};

// Define your container
const container = squarify.Rect{ .x = 0, .y = 0, .width = 800, .height = 600 };

// Squarify
const treemap = try Squarify.init(allocator).squarify(container, root);
defer treemap.deinit();
```

## Contributing
Pull requests and issues are welcome.

Enjoy creating fast squarified treemaps with Zig!
