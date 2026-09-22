// Copyright (C) 2026 Martin Brozkeff Malec
// Licensed under the EUPL, Version 1.2.

#include <QApplication>
#include <QTextBrowser>
#include <QWidget>

#include <dlfcn.h>

#include <iostream>

using ListLoadFn = void *(*)(void *, const char *, int);
using ListCloseWindowFn = void (*)(void *);

int main(int argc, char **argv) {
  QApplication application(argc, argv);
  if (argc != 3) {
    std::cerr << "usage: qt5-host-smoke PLUGIN MARKDOWN_FILE\n";
    return 2;
  }

  void *module = dlopen(argv[1], RTLD_NOW | RTLD_LOCAL);
  if (module == nullptr) {
    std::cerr << "dlopen failed: " << dlerror() << '\n';
    return 1;
  }
  auto load = reinterpret_cast<ListLoadFn>(dlsym(module, "ListLoad"));
  auto close_window =
      reinterpret_cast<ListCloseWindowFn>(dlsym(module, "ListCloseWindow"));
  if (load == nullptr || close_window == nullptr) {
    std::cerr << "missing WLX widget exports\n";
    dlclose(module);
    return 1;
  }

  QWidget parent;
  parent.resize(640, 480);
  void *window = load(&parent, argv[2], 0);
  if (window == nullptr) {
    std::cerr << "ListLoad returned an invalid handle\n";
    dlclose(module);
    return 1;
  }

  auto *browser = qobject_cast<QTextBrowser *>(static_cast<QWidget *>(window));
  if (browser == nullptr || !browser->isReadOnly() || browser->openLinks() ||
      browser->openExternalLinks() ||
      !browser->toPlainText().contains("Rust Qt5 smoke test")) {
    std::cerr << "QTextBrowser did not meet the preview contract\n";
    close_window(window);
    dlclose(module);
    return 1;
  }

  parent.resize(800, 600);
  application.processEvents();
  if (browser->geometry() != parent.rect()) {
    std::cerr << "preview widget did not track its parent resize\n";
    close_window(window);
    dlclose(module);
    return 1;
  }

  close_window(window);
  close_window(nullptr);
  if (!parent.findChildren<QTextBrowser *>().isEmpty()) {
    std::cerr << "ListCloseWindow did not destroy the preview widget\n";
    dlclose(module);
    return 1;
  }
  dlclose(module);
  std::cout << "ok: Qt5 widget creation, resize, and close lifecycle\n";
  return 0;
}
