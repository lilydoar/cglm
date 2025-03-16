# Building the library

cglm can be built using the Zig build system:

## Zig Build System (All platforms)

```bash
$ zig build
$ zig build -Dtests=true test # Run tests
```

### Options with defaults

```zig
shared: bool = true    // Build shared library
static: bool = true    // Build static library
tests: bool = false    // Build and run tests
```

### Using cglm in a Zig project

#### Header only

This requires no building or installation of cglm.

* Example:

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "my-app",
        .target = target,
        .optimize = optimize,
    });
    
    // Add cglm include path
    exe.addIncludePath(b.path("path/to/cglm/include"));
    exe.linkLibC();
    
    b.installArtifact(exe);
}
```

#### Linked

* Example using Zig as a build system:

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Import cglm as a dependency
    const cglm_dep = b.dependency("cglm", .{
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "my-app",
        .target = target,
        .optimize = optimize,
    });
    
    // Link against cglm library
    exe.linkLibrary(cglm_dep.artifact("cglm"));
    exe.addIncludePath(cglm_dep.path("include"));
    exe.linkLibC();
    
    b.installArtifact(exe);
}
```

# Building the documentation
First you need install Sphinx: http://www.sphinx-doc.org/en/master/usage/installation.html
then:
```bash
$ cd docs
$ sphinx-build source build
```
it will compile docs into build folder, you can run index.html inside that function.
