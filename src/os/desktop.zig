const std = @import("std");
const builtin = @import("builtin");
const build_config = @import("../build_config.zig");

const c = @cImport({
    @cInclude("unistd.h");
});

/// Returns true if the program was launched from a desktop environment.
///
/// On macOS, this returns true if the program was launched from Finder.
///
/// On Linux GTK, this returns true if the program was launched using the
/// desktop file. This also includes when `gtk-launch` is used because I
/// can't find a way to distinguish the two scenarios.
///
/// For other platforms and app runtimes, this returns false.
pub fn launchedFromDesktop() bool {
    return switch (builtin.os.tag) {
        // macOS apps launched from finder or `open` always have the init
        // process as their parent.
        .macos => c.getppid() == 1,

        // On Linux, GTK sets GIO_LAUNCHED_DESKTOP_FILE and
        // GIO_LAUNCHED_DESKTOP_FILE_PID. We only check the latter to see if
        // we match the PID and assume that if we do, we were launched from
        // the desktop file. Pid comparing catches the scenario where
        // another terminal was launched from a desktop file and then launches
        // Ghostty and Ghostty inherits the env.
        .linux => linux: {
            const gio_pid_str = std.os.getenv("GIO_LAUNCHED_DESKTOP_FILE_PID") orelse
                break :linux false;

            const pid = c.getpid();
            const gio_pid = std.fmt.parseInt(
                @TypeOf(pid),
                gio_pid_str,
                10,
            ) catch break :linux false;

            break :linux gio_pid == pid;
        },

        else => @compileError("unsupported platform"),
    };
}