const std = @import("std");
const fmt = std.fmt;

const Build = std.Build;
const Module = std.Build.Module;
const LazyPath = std.Build.LazyPath;
const ResolvedTarget = std.Build.ResolvedTarget;
const Compile = std.Build.Step.Compile;
const OptimizeMode = std.builtin.OptimizeMode;

const default_cflags = .{ "-g", "-Wall", "-Wextra", "-std=c99" };

const RubyConfigDirs = struct {
    // RbConfig::CONFIG['libdir'] for libruby.so library file
    lib_dir: LazyPath,
    // RbConfig::CONFIG['archdir'] for ruby's friends
    arch_dir: LazyPath,
    // RbConfig::CONFIG['rubyhdrdir'] for ruby.h header file
    ruby_header_dir: LazyPath,
    // RbConfig::CONFIG['rubyarchhdrdir'] for ruby/config.h header file
    ruby_arch_header_dir: LazyPath,
};

fn findRubyConfigDirs(b: *Build) RubyConfigDirs {
    const fetch_lib_dir_code = "print RbConfig::CONFIG.fetch(\"libdir\")";
    const fetch_arch_dir_code = "print RbConfig::CONFIG.fetch(\"archdir\")";
    const fetch_ruby_header_dir_code = "print RbConfig::CONFIG.fetch(\"rubyhdrdir\")";
    const fetch_ruby_arch_header_dir_code = "print RbConfig::CONFIG.fetch(\"rubyarchhdrdir\")";

    const cmd_lib = [_][]const u8{ "ruby", "-r", "rbconfig", "-e", fetch_lib_dir_code };
    const cmd_arch = [_][]const u8{ "ruby", "-r", "rbconfig", "-e", fetch_arch_dir_code };
    const cmd_ruby_header = [_][]const u8{ "ruby", "-r", "rbconfig", "-e", fetch_ruby_header_dir_code };
    const cmd_ruby_arch_header = [_][]const u8{ "ruby", "-r", "rbconfig", "-e", fetch_ruby_arch_header_dir_code };

    const lib_dir = LazyPath{ .cwd_relative = b.run(&cmd_lib) };
    const arch_dir = LazyPath{ .cwd_relative = b.run(&cmd_arch) };
    const ruby_header_dir = LazyPath{ .cwd_relative = b.run(&cmd_ruby_header) };
    const ruby_arch_header_dir = LazyPath{ .cwd_relative = b.run(&cmd_ruby_arch_header) };

    return .{
        .lib_dir = lib_dir,
        .arch_dir = arch_dir,
        .ruby_header_dir = ruby_header_dir,
        .ruby_arch_header_dir = ruby_arch_header_dir,
    };
}

fn addPrimesLibrary(b: *Build, target: ResolvedTarget, optimize: OptimizeMode) *Compile {
    const primes = b.addLibrary(.{
        .name = "primes",
        .linkage = .dynamic,
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });

    primes.root_module.addIncludePath(b.path("include"));
    primes.root_module.addCSourceFiles(.{
        .files = &.{"src/primes.c"},
        .flags = &default_cflags,
    });

    primes.linkSystemLibrary("m");

    return primes;
}

fn addPrimesRubyLibrary(b: *Build, target: ResolvedTarget, optimize: OptimizeMode) *Compile {
    const primes_ruby = b.addLibrary(.{
        .name = "primes_ruby",
        .linkage = .dynamic,
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
            .root_source_file = b.path("src/primes_ruby.zig"),
        }),
    });

    primes_ruby.root_module.addIncludePath(b.path("include"));

    const ruby_config_dirs = findRubyConfigDirs(b);
    primes_ruby.root_module.addSystemIncludePath(ruby_config_dirs.ruby_arch_header_dir);
    primes_ruby.root_module.addSystemIncludePath(ruby_config_dirs.ruby_header_dir);
    primes_ruby.root_module.addLibraryPath(ruby_config_dirs.arch_dir);
    primes_ruby.root_module.addLibraryPath(ruby_config_dirs.lib_dir);

    primes_ruby.root_module.linkSystemLibrary("ruby", .{ .needed = true });

    return primes_ruby;
}

pub fn build(b: *Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // primes library
    const primes = addPrimesLibrary(b, target, optimize);
    b.installArtifact(primes);

    // primes_ruby library
    const primes_ruby = addPrimesRubyLibrary(b, target, optimize);
    primes_ruby.root_module.linkLibrary(primes);
    b.installArtifact(primes_ruby);
}
