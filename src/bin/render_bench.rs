// Copyright (C) 2026 Martin Brozkeff Malec
// Licensed under the EUPL, Version 1.2.

#[path = "../markdown.rs"]
mod markdown;

use std::env;
use std::fs;
use std::hint::black_box;
use std::time::Instant;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let mut args = env::args_os().skip(1);
    let input = args.next().ok_or("usage: render-bench FILE ITERATIONS")?;
    let iterations: usize = args
        .next()
        .ok_or("usage: render-bench FILE ITERATIONS")?
        .to_string_lossy()
        .parse()?;
    if iterations == 0 {
        return Err("iterations must be greater than zero".into());
    }

    let bytes = fs::read(input)?;
    let source = String::from_utf8_lossy(&bytes);
    let start = Instant::now();
    let mut output_bytes = 0usize;
    for _ in 0..iterations {
        output_bytes += black_box(markdown::render_to_html(black_box(&source))).len();
    }
    let elapsed = start.elapsed();
    println!(
        "rust iterations={iterations} total_ms={} per_render_us={} output_bytes={}",
        elapsed.as_millis(),
        elapsed.as_micros() / iterations as u128,
        output_bytes / iterations
    );
    Ok(())
}
