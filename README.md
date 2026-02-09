# Embedded GDB MCP

> **Debug embedded systems with AI. Find bugs in seconds, not hours.**

[![Release](https://img.shields.io/github/v/release/ezulabs/embeddedgdbmcp?style=flat-square)](https://github.com/ezulabs/embeddedgdbmcp/releases)
[![License](https://img.shields.io/badge/license-Proprietary-red?style=flat-square)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux%20%7C%20Windows-blue?style=flat-square)]()

---

## The Problem

You've been staring at your embedded code for 3 hours. The LED won't blink. Or worse - it blinks for 30 seconds then the whole system crashes. No error message. No stack trace. Just... nothing.

## The Solution

```
You: My Pico crashed. Both LEDs stopped. I'm using spinlocks between cores.

Claude: Let me check both cores. [Connecting via SWD...]

        DEADLOCK DETECTED.

        Core 0: Holds SPINLOCK0 (sensors), waiting for SPINLOCK1 (display)
        Core 1: Holds SPINLOCK1 (display), waiting for SPINLOCK0 (sensors)

        Your lock ordering is inconsistent. Fix: acquire locks in the same
        order on both cores.
```

**That analysis took 10 seconds.** Manually? Days.

---

## Quick Start

### 1. Download

| Platform | Download |
|----------|----------|
| **macOS (Apple Silicon)** | [embedded-gdb-mcp-macos-arm64.tar.gz](https://github.com/ezulabs/embeddedgdbmcp/releases/latest/download/embedded-gdb-mcp-macos-arm64.tar.gz) |
| **macOS (Intel)** | [embedded-gdb-mcp-macos-x64.tar.gz](https://github.com/ezulabs/embeddedgdbmcp/releases/latest/download/embedded-gdb-mcp-macos-x64.tar.gz) |
| **Linux (x64)** | [embedded-gdb-mcp-linux-x64.tar.gz](https://github.com/ezulabs/embeddedgdbmcp/releases/latest/download/embedded-gdb-mcp-linux-x64.tar.gz) |
| **Linux (ARM64)** | [embedded-gdb-mcp-linux-arm64.tar.gz](https://github.com/ezulabs/embeddedgdbmcp/releases/latest/download/embedded-gdb-mcp-linux-arm64.tar.gz) |
| **Windows (x64)** | [embedded-gdb-mcp-windows-x64.zip](https://github.com/ezulabs/embeddedgdbmcp/releases/latest/download/embedded-gdb-mcp-windows-x64.zip) |

**Or install via script:**

```bash
# macOS / Linux
curl -sSfL https://raw.githubusercontent.com/ezulabs/embeddedgdbmcp/main/install.sh | sh

# Windows (PowerShell)
irm https://raw.githubusercontent.com/ezulabs/embeddedgdbmcp/main/install.ps1 | iex
```

### 2. Configure Claude Desktop / Cursor

Add to your MCP config:

**Claude Desktop** (`~/.config/claude/claude_desktop_config.json` on Linux, `~/Library/Application Support/Claude/claude_desktop_config.json` on macOS):

```json
{
  "mcpServers": {
    "embedded-gdb": {
      "command": "/usr/local/bin/embedded-gdb-mcp",
      "args": []
    }
  }
}
```

**Cursor** (`~/.cursor/mcp.json`):

```json
{
  "mcpServers": {
    "embedded-gdb": {
      "command": "/usr/local/bin/embedded-gdb-mcp",
      "args": []
    }
  }
}
```

### 3. Start Your Debug Server

```bash
# OpenOCD (ST-Link, J-Link, CMSIS-DAP)
openocd -f interface/stlink.cfg -f target/stm32f1x.cfg

# Or for Raspberry Pi Pico
openocd -f interface/cmsis-dap.cfg -f target/rp2040.cfg
```

### 4. Ask Claude to Debug

```
You: Connect to my STM32 on localhost:3333 and tell me why it's crashing
```

That's it. Claude now has direct access to your hardware.

---

## What Can It Do?

### Real Debugging Session

```
You: My LED on GPIO 25 should blink but it doesn't. Code looks right.

Claude: Let me check the GPIO configuration.
        [Reading SIO registers at 0xd0000000...]

        Found the issue: GPIO 25 is configured as INPUT, not OUTPUT.

        GPIO_OE register: 0x00000000 (bit 25 not set)
        GPIO_OUT register: 0x02000000 (bit 25 IS set - you're writing to it)

        Your code calls gpio_init(25) but never gpio_set_dir(25, GPIO_OUT).
        The output latch toggles, but the pin can't drive the LED.

You: That's what took me 3 hours yesterday.
```

### Automatic Fault Decoding

```
You: My Cortex-M4 crashed with a HardFault. What happened?

Claude: [Reading fault registers...]

        FAULT TYPE: UsageFault (escalated to HardFault)
        CAUSE: DIVBYZERO - Division by zero

        CFSR: 0x02000000
          └── DIVBYZERO bit set

        Faulting instruction: PC = 0x08001a34
        This is in calculate_average() at main.c:142

        The variable 'count' is 0 when you divide 'sum / count'.
```

### Peripheral Register Access

```
You: Why is my UART printing garbage?

Claude: [Loading STM32F103 SVD, reading USART1 registers...]

        USART1_BRR = 0x0044

        With your 72MHz clock, this gives: 72000000 / (16 × 68) = 66,176 baud

        You're running at 66,176 baud but your terminal expects 115,200.
        That's a 42% error - every byte will be corrupted.

        BRR should be 0x0271 for 115200 baud at 72MHz.
```

---

## 29 Tools for Complete Debug Control

| Category | Tools |
|----------|-------|
| **Connection** | `connect`, `disconnect`, `status` |
| **Execution** | `halt`, `continue`, `step`, `step_over`, `step_out`, `run`, `reset` |
| **Breakpoints** | `set`, `delete`, `list`, `set_watchpoint` |
| **Inspection** | `read_memory`, `write_memory`, `read_registers`, `backtrace`, `locals`, `evaluate`, `disassemble`, `source` |
| **Peripherals** | `load_svd`, `list`, `read_register`, `write_register` |
| **Flash** | `write`, `erase`, `verify` |
| **Analysis** | `decode_fault`, `system_state` |

---

## Supported Hardware

### Debug Probes
- ✅ **OpenOCD** - ST-Link, J-Link, CMSIS-DAP, and 50+ other probes
- ✅ **Raspberry Pi Debug Probe** - For Pico debugging
- ✅ **QEMU** - For simulation and testing
- 🔜 J-Link GDB Server (direct)
- 🔜 pyOCD

### Microcontrollers
Any ARM Cortex-M (M0/M0+/M3/M4/M7/M23/M33):
- STM32 (all families)
- Raspberry Pi Pico (RP2040)
- Nordic nRF52/nRF53
- NXP LPC/i.MX RT
- Microchip SAM
- And many more...

### Built-in SVD Files
- STM32F103 (free tier)
- LM3S6965 (free tier)
- RP2040 (coming soon)
- 10,000+ SVDs (Pro tier)

---

## Build from Source

```bash
# Prerequisites: Rust 1.75+
git clone https://github.com/ezulabs/embeddedgdbmcp
cd embedded-gdb-mcp
cargo build --release

# Binary at: target/release/embedded-gdb-mcp
```

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      AI ASSISTANT                           │
│                   (Claude, Cursor, etc.)                    │
└─────────────────────────────┬───────────────────────────────┘
                              │ MCP Protocol (JSON-RPC over stdio)
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                  EMBEDDED GDB MCP SERVER                    │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  29 TOOLS: connection | execution | breakpoints |      │ │
│  │            inspection | peripherals | flash | analysis │ │
│  └────────────────────────────┬───────────────────────────┘ │
│  ┌────────────────────────────┼───────────────────────────┐ │
│  │              GDB/MI PROTOCOL LAYER                     │ │
│  └────────────────────────────┬───────────────────────────┘ │
│  ┌────────────────────────────┼───────────────────────────┐ │
│  │           SVD PARSER  |  FAULT DECODER                 │ │
│  └────────────────────────────┬───────────────────────────┘ │
└───────────────────────────────┼─────────────────────────────┘
                                │ GDB Remote Serial Protocol
              ┌─────────────────┼─────────────────┐
              ▼                 ▼                 ▼
          OpenOCD           J-Link             QEMU
              │                 │                 │
              ▼                 ▼                 ▼
          Hardware          Hardware          Virtual
```

---

## Pricing

| Tier | Price | What You Get |
|------|-------|--------------|
| **Free** | $0 | 50 debug sessions/month, 10 SVD files |
| **Pro** | $29/mo | Unlimited sessions, 10,000+ SVDs, priority support |
| **Team** | $99/mo | Pro features + team management, shared licenses |
| **Enterprise** | Custom | SSO, audit logs, dedicated support |

[Get Started Free →](https://ezulabs.com/products/embedded-gdb-mcp)

---

## Links

- 📖 **Documentation**: [ezulabs.com/docs](https://ezulabs.com/products/embedded-gdb-mcp/docs)
- 🐛 **Issues**: [GitHub Issues](https://github.com/ezulabs/embeddedgdbmcp/issues)
- 💬 **Discord**: [Join Community](https://discord.gg/embedded-gdb-mcp)
- 📧 **Email**: contact@ezulabs.com

---

## License

Proprietary software. Free tier available for personal and evaluation use.

Copyright © 2024 Ezulabs. All rights reserved.
