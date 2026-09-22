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
