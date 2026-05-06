// Set the Apple SMC `BCLM` key (Battery Charge Limit Maximum) on
// Intel Macs that expose it. Talks to the SMC LPC ports directly
// (0x300/0x304) using the same protocol as drivers/hwmon/applesmc.c.
//
// Race note: the kernel applesmc module also drives these ports. Unload
// it before invoking this binary, then reload it afterwards.

use std::arch::asm;
use std::env;
use std::process::ExitCode;
use std::thread;
use std::time::Duration;

const DATA_PORT: u16 = 0x300;
const CMD_PORT: u16 = 0x304;

const STATUS_AWAITING_DATA: u8 = 0x01;
const STATUS_IB_CLOSED: u8 = 0x02;
const STATUS_BUSY: u8 = 0x04;

const READ_CMD: u8 = 0x10;
const WRITE_CMD: u8 = 0x11;

const MIN_WAIT_US: u64 = 8;

unsafe fn outb(port: u16, val: u8) {
    unsafe {
        asm!(
            "out dx, al",
            in("dx") port,
            in("al") val,
            options(nomem, nostack, preserves_flags)
        );
    }
}

unsafe fn inb(port: u16) -> u8 {
    let val: u8;
    unsafe {
        asm!(
            "in al, dx",
            out("al") val,
            in("dx") port,
            options(nomem, nostack, preserves_flags)
        );
    }
    val
}

extern "C" {
    fn iopl(level: i32) -> i32;
}

fn wait_status(val: u8, mask: u8) -> Result<(), &'static str> {
    let mut us = MIN_WAIT_US;
    for i in 0..24 {
        let status = unsafe { inb(CMD_PORT) };
        if (status & mask) == val {
            return Ok(());
        }
        thread::sleep(Duration::from_micros(us));
        if i > 9 {
            us <<= 1;
        }
    }
    Err("smc: wait_status timeout")
}

fn send_command(cmd: u8) -> Result<(), &'static str> {
    wait_status(0, STATUS_IB_CLOSED)?;
    unsafe { outb(CMD_PORT, cmd) };
    Ok(())
}

fn send_byte(b: u8, port: u16) -> Result<(), &'static str> {
    wait_status(0, STATUS_IB_CLOSED)?;
    wait_status(STATUS_BUSY, STATUS_BUSY)?;
    unsafe { outb(port, b) };
    Ok(())
}

fn send_argument(key: &[u8; 4]) -> Result<(), &'static str> {
    for &b in key {
        send_byte(b, DATA_PORT)?;
    }
    Ok(())
}

// Mirrors kernel smc_sane(): if BUSY is stuck, kick the SMC with a READ
// command then re-check BUSY.
fn smc_sane() -> Result<(), &'static str> {
    if wait_status(0, STATUS_BUSY).is_ok() {
        return Ok(());
    }
    send_command(READ_CMD)?;
    wait_status(0, STATUS_BUSY)
}

fn write_smc(key: &[u8; 4], data: &[u8]) -> Result<(), &'static str> {
    smc_sane()?;
    send_command(WRITE_CMD)?;
    send_argument(key)?;
    send_byte(data.len() as u8, DATA_PORT)?;
    for &b in data {
        send_byte(b, DATA_PORT)?;
    }
    wait_status(0, STATUS_BUSY)
}

fn read_smc(key: &[u8; 4], buf: &mut [u8]) -> Result<(), &'static str> {
    smc_sane()?;
    send_command(READ_CMD)?;
    send_argument(key)?;
    send_byte(buf.len() as u8, DATA_PORT)?;
    for byte in buf.iter_mut() {
        wait_status(
            STATUS_AWAITING_DATA | STATUS_BUSY,
            STATUS_AWAITING_DATA | STATUS_BUSY,
        )?;
        *byte = unsafe { inb(DATA_PORT) };
    }
    wait_status(0, STATUS_BUSY)
}

fn print_usage() {
    eprintln!("usage:");
    eprintln!("  bclm get          read current BCLM value");
    eprintln!("  bclm set <20-100> set BCLM value");
}

fn main() -> ExitCode {
    let args: Vec<String> = env::args().collect();

    if unsafe { iopl(3) } != 0 {
        eprintln!("iopl(3) failed: needs root / CAP_SYS_RAWIO");
        return ExitCode::from(1);
    }

    match args.get(1).map(String::as_str) {
        Some("get") => {
            let mut buf = [0u8; 1];
            match read_smc(b"BCLM", &mut buf) {
                Ok(()) => {
                    println!("{}", buf[0]);
                    ExitCode::SUCCESS
                }
                Err(e) => {
                    eprintln!("read failed: {e}");
                    ExitCode::from(1)
                }
            }
        }
        Some("set") => {
            let pct: u8 = match args.get(2).and_then(|s| s.parse().ok()) {
                Some(v) if (20..=100).contains(&v) => v,
                _ => {
                    print_usage();
                    return ExitCode::from(1);
                }
            };
            match write_smc(b"BCLM", &[pct]) {
                Ok(()) => {
                    println!("BCLM set to {pct}");
                    ExitCode::SUCCESS
                }
                Err(e) => {
                    eprintln!("write failed: {e}");
                    ExitCode::from(1)
                }
            }
        }
        _ => {
            print_usage();
            ExitCode::from(1)
        }
    }
}
