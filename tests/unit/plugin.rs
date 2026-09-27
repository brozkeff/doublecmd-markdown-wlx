use super::{read_source, source_from_bytes, write_detect_string, MAX_PREVIEW_BYTES};

#[test]
fn strips_utf8_bom_and_replaces_invalid_sequences() {
    assert_eq!(
        source_from_bytes(b"\xef\xbb\xbfhello".to_vec()),
        Ok("hello".into())
    );
    assert_eq!(source_from_bytes(vec![b'a', 0xff]), Ok("a\u{fffd}".into()));
}

#[test]
fn enforces_the_preview_size_limit() {
    assert_eq!(
        source_from_bytes(vec![b'a'; MAX_PREVIEW_BYTES])
            .unwrap()
            .len(),
        MAX_PREVIEW_BYTES
    );
    assert!(source_from_bytes(vec![b'a'; MAX_PREVIEW_BYTES + 1]).is_err());
}

#[test]
fn rejects_non_regular_inputs() {
    assert!(read_source(std::path::Path::new("/dev/null")).is_err());
}

#[test]
fn detection_string_is_nul_terminated_and_truncated_safely() {
    let mut output = [0xff; 64];
    write_detect_string(&mut output);
    assert_eq!(
        &output[..DETECT_LEN],
        b"EXT=\"MD\" | EXT=\"MARKDOWN\" | EXT=\"MDOWN\""
    );
    assert_eq!(output[DETECT_LEN], 0);

    let mut short = [0xff; 5];
    write_detect_string(&mut short);
    assert_eq!(&short, b"EXT=\0");
}

const DETECT_LEN: usize = b"EXT=\"MD\" | EXT=\"MARKDOWN\" | EXT=\"MDOWN\"".len();

#[test]
fn reads_unicode_paths_and_rejects_missing_files_and_directories() {
    let root = test_directory("paths");
    let path = root.join("příliš-🦀.md");
    std::fs::write(&path, b"\xef\xbb\xbf# hello").unwrap();
    let source = read_source(&path);
    let missing = read_source(&root.join("missing.md"));
    let directory = read_source(&root);
    std::fs::remove_dir_all(root).unwrap();
    assert_eq!(source, Ok("# hello".into()));
    assert!(missing.is_err());
    assert!(directory.is_err());
}

#[test]
fn enforces_limit_when_reading_a_file() {
    let root = test_directory("limit");
    let path = root.join("large.md");
    std::fs::write(&path, vec![b'a'; MAX_PREVIEW_BYTES]).unwrap();
    let exact = read_source(&path);
    std::fs::write(&path, vec![b'a'; MAX_PREVIEW_BYTES + 1]).unwrap();
    let oversized = read_source(&path);
    std::fs::remove_dir_all(root).unwrap();
    assert_eq!(exact.unwrap().len(), MAX_PREVIEW_BYTES);
    assert!(oversized.is_err());
}

#[cfg(unix)]
#[test]
fn rejects_fifo_without_waiting_for_a_writer() {
    use std::ffi::CString;
    use std::os::unix::ffi::OsStrExt;
    let root = test_directory("fifo");
    let path = root.join("pipe.md");
    let name = CString::new(path.as_os_str().as_bytes()).unwrap();
    // SAFETY: name is a valid NUL-terminated path, and mkfifo retains no pointer.
    assert_eq!(unsafe { libc::mkfifo(name.as_ptr(), 0o600) }, 0);
    let result = read_source(&path);
    std::fs::remove_dir_all(root).unwrap();
    assert!(result.is_err());
}

#[test]
fn rejects_null_load_arguments_without_entering_the_widget_bridge() {
    assert!(super::ListLoad(std::ptr::null_mut(), std::ptr::null(), 0).is_null());
    let mut parent_placeholder = 0_u8;
    assert!(super::ListLoad(
        std::ptr::from_mut(&mut parent_placeholder).cast(),
        std::ptr::null(),
        0,
    )
    .is_null());
}

fn test_directory(label: &str) -> std::path::PathBuf {
    let root = std::env::temp_dir().join(format!(
        "markdown-wlx-{}-{label}-{}",
        std::process::id(),
        std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_nanos()
    ));
    std::fs::create_dir(&root).unwrap();
    root
}
