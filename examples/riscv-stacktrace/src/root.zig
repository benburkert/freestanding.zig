const std = @import("std");

const freestanding = @import("freestanding");

const Uart = @import("Uart.zig");

pub var stack linksection(".stack") = [_]u8{0} ** 0x4000; // 16KB
//
comptime {
    @export(&stack, .{ .name = "stack", .linkage = .weak });
}

export fn _start() callconv(.Naked) noreturn {
    const entry_asm =
        \\ la sp, {s}       // setup stack pointer to base
        \\ call {s}         // jump to start()
    ;

    asm volatile (std.fmt.comptimePrint(entry_asm, .{ ".stack", "start" }));

    // unreachable
    while (true) asm volatile ("wfi");
}

var uart: Uart = .{};

export fn start() callconv(.C) void {
    uart.init() catch exit(1);

    main();
}

fn main() void {
    foo();
}

fn foo() void {
    bar();
}

fn bar() void {
    bang();
}

fn bang() void {
    // TODO: @panic shows the wrong address/symbol ?
    std.debug.panic("kaboom!", .{});
}

var panic_buffer: [0x1000000]u8 = undefined; // 16MB
//
pub fn panic(msg: []const u8, _: ?*std.builtin.StackTrace, first_trace_addr: ?usize) noreturn {
    const w = uart.writer();

    w.print("panic: {s}\n", .{msg}) catch exit(2);

    var fba = std.heap.FixedBufferAllocator.init(&panic_buffer);

    var debug_info = freestanding.DebugInfo.init(fba.allocator(), .{}) catch |err| {
        w.print("panic: debug info err = {any}\n", .{err}) catch {};
        exit(3);
    };
    defer debug_info.deinit();

    debug_info.printStackTrace(w, first_trace_addr orelse @returnAddress(), @frameAddress()) catch |err| {
        w.print("panic: stacktrace err = {any}\n", .{err}) catch {};
        exit(4);
    };

    exit(0);
}

fn exit(code: u16) noreturn {
    const BASE_ADDRESS = 0x100000;
    const FINISHER_FAIL = 0x3333;

    const ptr: *volatile u32 = @ptrFromInt(BASE_ADDRESS);
    ptr.* = (@as(u32, code) << 16) | FINISHER_FAIL;

    // unreachable
    while (true) asm volatile ("wfi");
}
