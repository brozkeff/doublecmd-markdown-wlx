// Copyright (C) 2026 Martin Brozkeff Malec
// Licensed under the EUPL, Version 1.2.

//! Standalone Rust Linux WLX plugin for safe Markdown previews in Qt5 Double Commander.
//!
//! Rust owns WLX validation, bounded file reading, Markdown rendering, and
//! panic containment. A narrow C++ shim owns QWidget creation and destruction
//! because Qt does not expose a stable C ABI.

mod markdown;

#[cfg(test)]
#[path = "../tests/unit/plugin.rs"]
mod tests;

use std::ffi::{c_char, c_void, CStr, OsStr};
use std::fs::OpenOptions;
use std::io::Read;
use std::panic::{catch_unwind, AssertUnwindSafe};
use std::path::{Path, PathBuf};

const MAX_PREVIEW_BYTES: usize = 4 * 1024 * 1024;
const DETECT_STRING: &[u8] = b"EXT=\"MD\" | EXT=\"MARKDOWN\" | EXT=\"MDOWN\"";
const LICENSE: &[u8] = b"Copyright (C) 2026 Martin Brozkeff Malec; licensed under the EUPL 1.2\0";
const VERSION: &[u8] = b"0.2.1\0";

unsafe extern "C" {
    fn markdown_wlx_qt5_create(
        parent_handle: *mut c_void,
        html: *const c_char,
        html_length: usize,
    ) -> *mut c_void;
    fn markdown_wlx_qt5_destroy(window_handle: *mut c_void);
}

fn guarded<T>(operation: impl FnOnce() -> T) -> Option<T> {
    catch_unwind(AssertUnwindSafe(operation)).ok()
}

fn path_from_c_string(file_to_load: *const c_char) -> Option<PathBuf> {
    if file_to_load.is_null() {
        return None;
    }

    // SAFETY: WLX supplies a valid NUL-terminated path for the duration of ListLoad.
    let bytes = unsafe { CStr::from_ptr(file_to_load) }.to_bytes();
    #[cfg(unix)]
    {
        use std::os::unix::ffi::OsStrExt;
        Some(PathBuf::from(OsStr::from_bytes(bytes)))
    }
    #[cfg(not(unix))]
    {
        Some(PathBuf::from(String::from_utf8_lossy(bytes).into_owned()))
    }
}

fn source_from_bytes(mut bytes: Vec<u8>) -> Result<String, ()> {
    if bytes.len() > MAX_PREVIEW_BYTES {
        return Err(());
    }
    if bytes.starts_with(&[0xef, 0xbb, 0xbf]) {
        bytes.drain(..3);
    }
    Ok(String::from_utf8_lossy(&bytes).into_owned())
}

fn read_source(path: &Path) -> Result<String, ()> {
    let mut options = OpenOptions::new();
    options.read(true);
    #[cfg(target_os = "linux")]
    {
        use std::os::unix::fs::OpenOptionsExt;
        // Opening a FIFO without O_NONBLOCK could hang the host GUI thread.
        options.custom_flags(libc::O_NONBLOCK);
    }
    let file = options.open(path).map_err(|_| ())?;
    if !file.metadata().map_err(|_| ())?.is_file() {
        return Err(());
    }
    let mut bytes = Vec::with_capacity(MAX_PREVIEW_BYTES + 1);
    file.take((MAX_PREVIEW_BYTES + 1) as u64)
        .read_to_end(&mut bytes)
        .map_err(|_| ())?;
    source_from_bytes(bytes)
}

fn load_plugin(parent: *mut c_void, file_to_load: *const c_char) -> *mut c_void {
    if parent.is_null() {
        return std::ptr::null_mut();
    }
    let Some(path) = path_from_c_string(file_to_load) else {
        return std::ptr::null_mut();
    };
    let Ok(source) = read_source(&path) else {
        return std::ptr::null_mut();
    };
    let html = markdown::render_to_html(&source);
    if html.len() > i32::MAX as usize {
        return std::ptr::null_mut();
    }

    // SAFETY: WLX calls ListLoad on the Qt GUI thread with a live QWidget
    // parent. The HTML pointer stays valid for the synchronous call, and the
    // C++ shim copies it into QTextBrowser without retaining the pointer.
    unsafe { markdown_wlx_qt5_create(parent, html.as_ptr().cast(), html.len()) }
}

/// Creates the read-only Markdown preview widget, or returns a null WLX handle.
#[no_mangle]
pub extern "C" fn ListLoad(
    parent: *mut c_void,
    file_to_load: *const c_char,
    _show_flags: i32,
) -> *mut c_void {
    guarded(|| load_plugin(parent, file_to_load)).unwrap_or(std::ptr::null_mut())
}

/// Destroys the widget returned by [`ListLoad`].
///
/// # Safety
/// `list_window` must be null or a live widget returned by this plugin, and
/// this function must run on the Qt GUI thread exactly once for that widget.
#[no_mangle]
pub unsafe extern "C" fn ListCloseWindow(list_window: *mut c_void) {
    let _ = guarded(|| {
        if !list_window.is_null() {
            // SAFETY: The WLX host passes the live handle previously returned
            // by ListLoad and closes it on the Qt GUI thread.
            unsafe { markdown_wlx_qt5_destroy(list_window) };
        }
    });
}

fn write_detect_string(buffer: &mut [u8]) {
    if buffer.is_empty() {
        return;
    }
    let length = DETECT_STRING.len().min(buffer.len() - 1);
    buffer[..length].copy_from_slice(&DETECT_STRING[..length]);
    buffer[length] = 0;
}

/// Writes the WLX extension detection string into the host-provided buffer.
#[no_mangle]
pub extern "C" fn ListGetDetectString(buffer: *mut c_char, max_len: i32) {
    let _ = guarded(|| {
        if buffer.is_null() || max_len <= 0 {
            return;
        }
        // SAFETY: WLX provides a writable buffer of max_len bytes.
        let output =
            unsafe { std::slice::from_raw_parts_mut(buffer.cast::<u8>(), max_len as usize) };
        write_detect_string(output);
    });
}

/// Returns the plugin copyright and license notice.
#[no_mangle]
pub extern "C" fn MarkdownWlxLicense() -> *const c_char {
    LICENSE.as_ptr().cast()
}

/// Returns the plugin semantic version.
#[no_mangle]
pub extern "C" fn MarkdownWlxVersion() -> *const c_char {
    VERSION.as_ptr().cast()
}
