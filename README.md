# freestanding

A zig utility module for OS-less (freestanding) stuff.

## `freestanding.DebugInfo`

Print a stacktrace in a custom `panic` handler.

```zig

pub fn panic(msg: []const u8, _: ?*std.builtin.StackTrace, _: ?usize) noreturn {
    printStackTrace(@returnAddress(), @frameAddress()) catch {};
    fatal();
}

fn printStackTrace(return_address: usize) !void {
    var debug_info = try freestanding.DebugInfo.init(allocator, .{});
    defer debug_info.deinit();

    return debug_info.printStackTrace(writer, return_address, frame_address);
}
```

see `examples/riscv-stacktrace` for more details:

```
cd examples/riscv-stacktrace && zig build run
panic: kaboom!
         /Users/benburkert/.asdf/installs/zig/master/lib/std/debug.zig:0422:000: 0x8002fbe6 in panic__anon_8140 (riscv-stacktrace)
/Users/benburkert/src/github.com/benburkert/freestanding.zig/examples/riscv-stacktrace/src/root.zig:0042:009: 0x8002fbce in bar (riscv-stacktrace)
/Users/benburkert/src/github.com/benburkert/freestanding.zig/examples/riscv-stacktrace/src/root.zig:0038:008: 0x8002fbb6 in foo (riscv-stacktrace)
/Users/benburkert/src/github.com/benburkert/freestanding.zig/examples/riscv-stacktrace/src/root.zig:0034:008: 0x8002fb9e in main (riscv-stacktrace)
/Users/benburkert/src/github.com/benburkert/freestanding.zig/examples/riscv-stacktrace/src/root.zig:0030:009: 0x8002fb86 in start (riscv-stacktrace)
/Users/benburkert/src/github.com/benburkert/freestanding.zig/examples/riscv-stacktrace/src/root.zig:0019:005: 0x80000010 in _start (riscv-stacktrace)
```

! Be sure to export the `debug_*_start` & `debug_*_end` symbols, see `examples/riscv-stacktrace/src/root.ld`.
