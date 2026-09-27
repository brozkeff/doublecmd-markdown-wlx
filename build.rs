// Copyright (C) 2026 Martin Brozkeff Malec
// Licensed under the EUPL, Version 1.2.

fn main() {
    let target_os = std::env::var("CARGO_CFG_TARGET_OS").expect("Cargo target OS");
    let mut build = cc::Build::new();
    build
        .cpp(true)
        .flag_if_supported("-std=c++17")
        .flag_if_supported("-fPIC")
        .flag_if_supported("-fvisibility=hidden");
    match target_os.as_str() {
        "linux" => {
            println!("cargo:rerun-if-changed=src/qt5_shim.cpp");
            let qt = pkg_config::Config::new()
                .atleast_version("5.15")
                .probe("Qt5Widgets")
                .expect("Qt 5.15 Widgets development files are required");
            build.file("src/qt5_shim.cpp").define("QT_NO_DEBUG", None);
            for include in qt.include_paths {
                build.include(include);
            }
        }
        "macos" => {
            assert_eq!(
                std::env::var("CARGO_CFG_TARGET_ARCH").as_deref(),
                Ok("aarch64"),
                "The Cocoa backend currently supports Apple Silicon only"
            );
            println!("cargo:rerun-if-changed=src/cocoa_shim.mm");
            build.file("src/cocoa_shim.mm").flag("-fobjc-arc");
            println!("cargo:rustc-link-lib=framework=AppKit");
            println!("cargo:rustc-link-lib=framework=WebKit");
        }
        other => panic!("Unsupported plugin target OS: {other}"),
    }
    build.compile("markdown_wlx_shim");
}
