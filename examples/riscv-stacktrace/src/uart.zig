const std = @import("std");

const BASE_ADDRESS: usize = 0x10000000;

const IER_RX_ENABLE: u8 = 0x1;

const IER_TX_ENABLE: u8 = 0x2;

const FCR_FIFO_ENABLE: u8 = 0x1;

// clear the content of the two FIFOs
const FCR_FIFO_CLEAR: u8 = 0x6;

const LCR_EIGHT_BITS: u8 = 0x3;

// special mode to set baud rate
const LCR_BAUD_LATCH: u8 = 0x80;

// input is waiting to be read from RHR
const LSR_RX_READY: u8 = 0x1;

// THR can accept another character to send
const LSR_TX_IDLE: u8 = 0x20;

// receive buffer register (for input bytes)
const RHR: u3 = 0;

// transmit holding register (for output bytes)
const THR: u3 = 0;

// interrupt enable register
const IER: u3 = 1;

// FIFO control register
const FCR: u3 = 2;

// interrupt status register
const ISR: u3 = 2;

// line control register
const LCR: u3 = 3;

// line status register
const LSR: u3 = 5;

// divisor latch (MS)
const DLMS: u3 = 0;

// divisor latch (LS)
const DLLS: u3 = 1;

const mmio = struct {
    pub fn write(T: type, reg: usize, data: T) void {
        std.debug.assert(@sizeOf(T) <= @sizeOf(usize));
        std.debug.assert(@typeInfo(T).int.signedness == .unsigned);

        @atomicStore(T, @as(*T, @ptrFromInt(reg)), data, .release);
    }

    pub fn read(T: type, reg: usize) T {
        std.debug.assert(@sizeOf(T) <= @sizeOf(usize));
        std.debug.assert(@typeInfo(T).int.signedness == .unsigned);

        return @atomicLoad(T, @as(*T, @ptrFromInt(reg)), .acquire);
    }
};

base_address: usize = BASE_ADDRESS,

pub fn init(self: @This()) !void {
    // disable interrupts.
    mmio.write(u8, self.base_address + IER, 0x00);

    // special mode to set baud rate.
    mmio.write(u8, self.base_address + LCR, LCR_BAUD_LATCH);

    // LSB for baud rate of 38.4K.
    mmio.write(u8, self.base_address + DLLS, 0x03);

    // MSB for baud rate of 38.4K.
    mmio.write(u8, self.base_address + DLMS, 0x00);

    // leave set-baud mode,
    // and set word length to 8 bits, no parity.
    mmio.write(u8, self.base_address + LCR, LCR_EIGHT_BITS);

    // reset and enable FIFOs.
    mmio.write(u8, self.base_address + FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);

    // enable transmit and receive interrupts.
    mmio.write(u8, self.base_address + IER, IER_TX_ENABLE | IER_RX_ENABLE);
}

pub fn writeByte(self: @This(), byte: u8) WriteError!void {
    // Wait for UART to become ready to transmit.
    while ((mmio.read(u8, self.base_address + LSR) & LSR_TX_IDLE) == 0) {}

    mmio.write(u8, self.base_address + THR, byte);
}

pub fn write(self: @This(), buffer: []const u8) WriteError!usize {
    for (buffer) |c|
        try self.writeByte(c);
    return buffer.len;
}

pub fn writer(self: @This()) Writer {
    return Writer{ .context = self };
}

pub const Writer = std.io.Writer(@This(), WriteError, write);

pub const WriteError = error{};
