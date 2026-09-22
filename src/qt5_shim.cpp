// Copyright (C) 2026 Martin Brozkeff Malec
// Licensed under the EUPL, Version 1.2. This is the complete Qt unsafe shim.

#include <QTextBrowser>
#include <QKeyEvent>
#include <QTextOption>
#include <QEvent>
#include <QObject>
#include <QPointer>
#include <QTimer>
#include <QWidget>

#include <climits>
#include <cstddef>
#include <memory>

class MarkdownTextBrowser final : public QTextBrowser {
public:
  explicit MarkdownTextBrowser(QWidget *parent) : QTextBrowser(parent) {}

protected:
  void keyPressEvent(QKeyEvent *event) override {
    if (event->key() == Qt::Key_Escape) {
      auto *viewer_window = window();
      if (viewer_window != this) {
        // Let the host perform its normal close and WLX teardown sequence.
        event->accept();
        QTimer::singleShot(0, viewer_window, &QWidget::close);
        return;
      }
    }
    QTextBrowser::keyPressEvent(event);
  }
};

class ParentResizeFilter final : public QObject {
public:
  explicit ParentResizeFilter(QTextBrowser *browser)
      : QObject(browser), browser_(browser) {}

protected:
  bool eventFilter(QObject *watched, QEvent *event) override {
    if (event->type() == QEvent::Resize && browser_ != nullptr) {
      auto *parent = static_cast<QWidget *>(watched);
      browser_->setGeometry(parent->rect());
    }
    return QObject::eventFilter(watched, event);
  }

private:
  QPointer<QTextBrowser> browser_;
};

extern "C" void *markdown_wlx_qt5_create(void *parent_handle,
                                          const char *html,
                                          std::size_t html_length) noexcept {
  if (parent_handle == nullptr || html == nullptr || html_length > INT_MAX) {
    return nullptr;
  }

  try {
    auto *parent = static_cast<QWidget *>(parent_handle);
    auto browser = std::make_unique<MarkdownTextBrowser>(parent);
    browser->setReadOnly(true);
    browser->setOpenLinks(false);
    browser->setOpenExternalLinks(false);
    browser->setTextInteractionFlags(Qt::TextSelectableByMouse |
                                     Qt::TextSelectableByKeyboard);
    browser->setLineWrapMode(QTextEdit::WidgetWidth);
    browser->setWordWrapMode(QTextOption::WrapAtWordBoundaryOrAnywhere);
    browser->setGeometry(parent->rect());
    auto *resize_filter = new ParentResizeFilter(browser.get());
    parent->installEventFilter(resize_filter);
    browser->setHtml(QString::fromUtf8(html, static_cast<int>(html_length)));
    browser->show();
    return browser.release();
  } catch (...) {
    return nullptr;
  }
}

extern "C" void markdown_wlx_qt5_destroy(void *window_handle) noexcept {
  try {
    delete static_cast<QTextBrowser *>(window_handle);
  } catch (...) {
    // No C++ exception may cross the C ABI boundary.
  }
}
