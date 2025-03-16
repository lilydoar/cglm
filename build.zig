const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Standard version configuration
    const version = "0.9.6";

    // Build options
    const shared = b.option(
        bool, 
        "shared", 
        "Build shared library (default: true)"
    ) orelse true;
    
    const build_static = b.option(
        bool, 
        "static", 
        "Build static library (default: true)"
    ) orelse true;

    const enable_tests = b.option(
        bool, 
        "tests", 
        "Build tests (default: false)"
    ) orelse false;

    // Common source files
    const sources = [_][]const u8{
        "src/euler.c",
        "src/affine.c",
        "src/io.c",
        "src/quat.c",
        "src/cam.c",
        "src/vec2.c",
        "src/ivec2.c",
        "src/vec3.c",
        "src/ivec3.c",
        "src/vec4.c",
        "src/ivec4.c",
        "src/mat2.c",
        "src/mat2x3.c",
        "src/mat2x4.c",
        "src/mat3.c",
        "src/mat3x2.c",
        "src/mat3x4.c",
        "src/mat4.c",
        "src/mat4x2.c",
        "src/mat4x3.c",
        "src/plane.c",
        "src/noise.c",
        "src/frustum.c",
        "src/box.c",
        "src/aabb2d.c",
        "src/project.c",
        "src/sphere.c",
        "src/ease.c",
        "src/curve.c",
        "src/bezier.c",
        "src/ray.c",
        "src/affine2d.c",
        "src/clipspace/ortho_lh_no.c",
        "src/clipspace/ortho_lh_zo.c",
        "src/clipspace/ortho_rh_no.c",
        "src/clipspace/ortho_rh_zo.c",
        "src/clipspace/persp_lh_no.c",
        "src/clipspace/persp_lh_zo.c",
        "src/clipspace/persp_rh_no.c",
        "src/clipspace/persp_rh_zo.c",
        "src/clipspace/view_lh_no.c",
        "src/clipspace/view_lh_zo.c",
        "src/clipspace/view_rh_no.c",
        "src/clipspace/view_rh_zo.c",
        "src/clipspace/project_no.c",
        "src/clipspace/project_zo.c",
    };

    // Build static library if requested
    var static_lib: ?*std.Build.Step.Compile = null;
    if (build_static) {
        const lib = b.addStaticLibrary(.{
            .name = "cglm",
            .target = target,
            .optimize = optimize,
            .version = .{
                .major = 0,
                .minor = 9,
                .patch = 6,
            },
        });

        // Set C standard
        lib.linkLibC();
        lib.root_module.addCMacro("HAVE_STDINT_H", "1");
        lib.root_module.addCMacro("HAVE_STDLIB_H", "1");
        lib.root_module.addCMacro("CGLM_STATIC", "1");

        // Add include directories
        lib.addIncludePath(b.path("include"));
        lib.addIncludePath(b.path("src"));

        for (sources) |src| {
            lib.addCSourceFile(.{
                .file = b.path(src),
                .flags = &[_][]const u8{"-std=c11", "-Wall"},
            });
        }

        // Install library
        b.installArtifact(lib);
        static_lib = lib;
    }

    // Build shared library if requested
    var shared_lib_artifact: ?*std.Build.Step.Compile = null;
    if (shared) {
        const lib = b.addSharedLibrary(.{
            .name = "cglm",
            .target = target,
            .optimize = optimize,
            .version = .{
                .major = 0,
                .minor = 9,
                .patch = 6,
            },
        });

        lib.linkLibC();
        lib.addIncludePath(b.path("include"));
        lib.addIncludePath(b.path("src"));
        lib.root_module.addCMacro("CGLM_EXPORTS", "1");

        for (sources) |src| {
            lib.addCSourceFile(.{
                .file = b.path(src),
                .flags = &[_][]const u8{"-std=c11", "-Wall"},
            });
        }

        b.installArtifact(lib);
        shared_lib_artifact = lib;
    }

    // Build and run tests if requested
    if (enable_tests) {
        const test_exe = b.addExecutable(.{
            .name = "tests",
            .target = target,
            .optimize = optimize,
        });

        // Link against the static library if it exists, otherwise use the shared library
        if (static_lib) |lib| {
            test_exe.root_module.linkLibrary(lib);
        } else if (shared_lib_artifact) |lib| {
            test_exe.root_module.linkLibrary(lib);
        } else {
            std.debug.print("Error: Neither static nor shared library is available for tests\n", .{});
            return;
        }

        test_exe.linkLibC();
        test_exe.addIncludePath(b.path("include"));
        test_exe.addIncludePath(b.path("test/include"));
        test_exe.root_module.addCMacro("GLM_TESTS_NO_COLORFUL_OUTPUT", "1");

        const test_sources = [_][]const u8{
            "test/runner.c",
            "test/src/test_bezier.c",
            "test/src/test_clamp.c",
            "test/src/test_common.c",
            "test/src/test_euler.c",
            "test/src/tests.c",
            "test/src/test_struct.c",
        };

        for (test_sources) |src| {
            test_exe.addCSourceFile(.{
                .file = b.path(src),
                .flags = &[_][]const u8{"-std=c11", "-Wall"},
            });
        }

        b.installArtifact(test_exe);

        const run_tests = b.addRunArtifact(test_exe);
        const test_step = b.step("test", "Run the cglm tests");
        test_step.dependOn(&run_tests.step);
    }

    // Create pkg-config file
    const pc_file = b.addWriteFiles();
    const pc_content = std.fmt.allocPrint(
        b.allocator,
        \\prefix={s}
        \\exec_prefix=${{prefix}}
        \\includedir=${{prefix}}/include
        \\libdir=${{exec_prefix}}/lib
        \\
        \\Name: cglm
        \\Description: OpenGL Mathematics (glm) for C
        \\Version: {s}
        \\Cflags: -I${{includedir}}
        \\Libs: -L${{libdir}} -lcglm
        \\
    , 
    .{ 
        b.install_prefix, 
        version,
    }) catch unreachable;

    const pc_path = pc_file.add("cglm.pc", pc_content);

    // Install pkg-config file
    const install_pc = b.addInstallFile(pc_path, "lib/pkgconfig/cglm.pc");
    b.getInstallStep().dependOn(&install_pc.step);

    // Install header files
    const headers_step = b.addInstallDirectory(.{
        .source_dir = b.path("include/cglm"),
        .install_dir = .header,
        .install_subdir = "cglm",
    });
    
    b.getInstallStep().dependOn(&headers_step.step);
}