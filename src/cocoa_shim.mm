// Copyright (C) 2026 Martin Brozkeff Malec
// Licensed under the EUPL, Version 1.2. This is the complete Cocoa unsafe shim.

#import <AppKit/AppKit.h>
#import <WebKit/WebKit.h>

#include <climits>
#include <cstddef>

// Keep classes plugin-specific: Objective-C class names share the host namespace.
@interface MarkdownWlxWebView : WKWebView
@end

@implementation MarkdownWlxWebView
- (void)keyDown:(NSEvent *)event {
  if (event.keyCode == 53) {
    // Let the host close the Lister and invoke ListCloseWindow normally.
    [self.window performClose:nil];
    return;
  }
  [super keyDown:event];
}
- (void)cancelOperation:(id)sender {
  [self.window performClose:sender];
}
@end

@interface MarkdownWlxCocoaView : NSView <WKNavigationDelegate, WKUIDelegate>
@property(nonatomic, strong) MarkdownWlxWebView *browser;
@property(nonatomic) BOOL allowInitialNavigation;
- (instancetype)initWithFrame:(NSRect)frame html:(NSString *)html;
- (void)tearDown;
@end

@implementation MarkdownWlxCocoaView
- (instancetype)initWithFrame:(NSRect)frame html:(NSString *)html {
  self = [super initWithFrame:frame];
  if (self) {
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    configuration.websiteDataStore = [WKWebsiteDataStore nonPersistentDataStore];
    configuration.defaultWebpagePreferences.allowsContentJavaScript = NO;
    _browser = [[MarkdownWlxWebView alloc] initWithFrame:self.bounds
                                        configuration:configuration];
    _browser.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    _browser.navigationDelegate = self;
    _browser.UIDelegate = self;
    _browser.allowsLinkPreview = NO;
    _allowInitialNavigation = YES;
    [self addSubview:_browser];
    [_browser loadHTMLString:html baseURL:nil];
  }
  return self;
}
- (BOOL)isFlipped {
  return YES;
}
- (void)viewDidMoveToWindow {
  [super viewDidMoveToWindow];
  if (self.window != nil) {
    [self.window makeFirstResponder:self.browser];
  }
}
- (void)webView:(WKWebView *)webView
    decidePolicyForNavigationAction:(WKNavigationAction *)action
                   decisionHandler:(void (^)(WKNavigationActionPolicy))handler {
  // Only the initial in-memory document may navigate. No links, files, remote
  // URLs, downloads, or subsequent document loads are permitted.
  BOOL initial = self.allowInitialNavigation && action.targetFrame.isMainFrame &&
                 action.navigationType == WKNavigationTypeOther &&
                 [action.request.URL.absoluteString isEqualToString:@"about:blank"];
  if (initial) {
    self.allowInitialNavigation = NO;
  }
  handler(initial ? WKNavigationActionPolicyAllow : WKNavigationActionPolicyCancel);
}
- (WKWebView *)webView:(WKWebView *)webView
    createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration
              forNavigationAction:(WKNavigationAction *)action
                   windowFeatures:(WKWindowFeatures *)features {
  return nil;
}
- (void)tearDown {
  self.allowInitialNavigation = NO;
  self.browser.navigationDelegate = nil;
  self.browser.UIDelegate = nil;
  [self.browser stopLoading];
  [self.browser removeFromSuperview];
  self.browser = nil;
  [self removeFromSuperview];
}
@end

extern "C" void *markdown_wlx_create(void *parent_handle, const char *html,
                                      std::size_t html_length) noexcept {
  if (parent_handle == nullptr || html == nullptr || html_length > INT_MAX ||
      ![NSThread isMainThread]) {
    return nullptr;
  }
  try {
    @autoreleasepool {
      @try {
        NSView *parent = (__bridge NSView *)parent_handle;
        NSString *document = [[NSString alloc] initWithBytes:html
                                                    length:html_length
                                                  encoding:NSUTF8StringEncoding];
        if (document == nil) {
          return nullptr;
        }
        // Defense in depth beyond Rust's event filter: deny every resource,
        // script, frame, object, form, and base URL. Only our inline CSS is used.
        NSString *policy = @"<head><meta http-equiv=\"Content-Security-Policy\" "
                            "content=\"default-src 'none'; style-src 'unsafe-inline'; "
                            "base-uri 'none'; form-action 'none'\">";
        document = [document stringByReplacingOccurrencesOfString:@"<head>"
                                                       withString:policy];
        MarkdownWlxCocoaView *view = [[MarkdownWlxCocoaView alloc]
            initWithFrame:parent.bounds html:document];
        view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        [parent addSubview:view];
        // One explicit ownership reference belongs to the returned WLX handle.
        // Parent ownership is independent and removed during teardown.
        return (__bridge_retained void *)view;
      } @catch (NSException *exception) {
        return nullptr;
      }
    }
  } catch (...) {
    return nullptr;
  }
}

extern "C" void markdown_wlx_destroy(void *window_handle) noexcept {
  if (window_handle == nullptr || ![NSThread isMainThread]) {
    return;
  }
  try {
    @autoreleasepool {
      @try {
        // Transfer the WLX ownership reference back to ARC, released on exit.
        MarkdownWlxCocoaView *view = (__bridge_transfer MarkdownWlxCocoaView *)window_handle;
        [view tearDown];
      } @catch (NSException *exception) {
        // No Objective-C exception may cross the C ABI boundary.
      }
    }
  } catch (...) {
    // No C++ exception may cross the C ABI boundary.
  }
}
