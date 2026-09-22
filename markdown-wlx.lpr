library MarkdownWlx;

{ Copyright (C) 2026 Martin Brozkeff Malec
  Licensed under the EUPL, Version 1.2. }

{$mode objfpc}{$H+}
{$include sdk/calling.inc}

uses
  {$IFDEF UNIX}
  cmem,
  cthreads,
  {$ENDIF}
  Classes,
  SysUtils,
  LazUTF8,
  WlxPlugin,
  MdRender,
  {$IF DEFINED(LCLGTK2)}
  gtk2,
  gdk2,
  Pango
  {$ELSEIF DEFINED(LCLGTK3)}
  LazGtk3
  {$ELSEIF DEFINED(LCLQT5)}
  qt5, qtwidgets
  {$ELSEIF DEFINED(LCLQT6)}
  qt6, qtwidgets
  {$ENDIF}
  ;

const
  { Keep previews bounded because the WLX plugin runs inside the file manager. }
  MaxPreviewBytes = 4 * 1024 * 1024;

function ReadUtf8File(const FileName: String): String;
var
  Stream: TFileStream;
  FileSize: Int64;
begin
  if FileName = '' then
    raise EArgumentException.Create('A file name is required');

  Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
  try
    FileSize := Stream.Size;
    if FileSize > MaxPreviewBytes then
      raise EInOutError.CreateFmt('Markdown preview exceeds %d bytes', [MaxPreviewBytes]);
    SetLength(Result, NativeInt(FileSize));
    if Length(Result) > 0 then
      Stream.ReadBuffer(Result[1], Length(Result));
  finally
    Stream.Free;
  end;
  if (Length(Result) >= 3) and (Result[1] = #$EF) and
     (Result[2] = #$BB) and (Result[3] = #$BF) then
    Delete(Result, 1, 3);
end;

{$IFDEF LCLGTK2}
function ListLoad(ParentWin: HWND; FileToLoad: PAnsiChar; ShowFlags: Integer): HWND; dcpcall;
var
  Scroll: PGtkScrolledWindow;
  LabelWidget: PGtkWidget;
  Source, Markup: String;
begin
  try
    if FileToLoad = nil then
      raise EArgumentException.Create('A file name is required');
    Source := ReadUtf8File(String(FileToLoad));
    Markup := RenderMarkdownPango(Source);
    Scroll := PGtkScrolledWindow(gtk_scrolled_window_new(nil, nil));
    LabelWidget := gtk_label_new(nil);
    gtk_label_set_markup(PGtkLabel(LabelWidget), PChar(Markup));
    gtk_label_set_line_wrap(PGtkLabel(LabelWidget), True);
    gtk_label_set_selectable(PGtkLabel(LabelWidget), True);
    gtk_misc_set_alignment(PGtkMisc(LabelWidget), 0, 0);
    gtk_container_add(PGtkContainer(Scroll), LabelWidget);
    gtk_container_add(PGtkContainer(ParentWin), PGtkWidget(Scroll));
    gtk_widget_show_all(PGtkWidget(Scroll));
    Result := HWND(Scroll);
  except
    Result := wlxInvalidHandle;
  end;
end;

procedure ListCloseWindow(ListWin: HWND); dcpcall;
begin
  gtk_widget_destroy(PGtkWidget(ListWin));
end;
{$ELSE}
{$IFDEF LCLGTK3}
function ListLoad(ParentWin: HWND; FileToLoad: PAnsiChar; ShowFlags: Integer): HWND; dcpcall;
var
  Scroll: PGtkScrolledWindow;
  View: PGtkTextView;
  Buffer: PGtkTextBuffer;
  Iter: TGtkTextIter;
  Source, Markup: String;
begin
  try
    if FileToLoad = nil then
      raise EArgumentException.Create('A file name is required');
    Source := ReadUtf8File(String(FileToLoad));
    Markup := RenderMarkdownPango(Source);
    Scroll := gtk_scrolled_window_new(nil, nil);
    View := PGtkTextView(gtk_text_view_new);
    Buffer := gtk_text_buffer_new(nil);
    gtk_text_buffer_get_end_iter(Buffer, @Iter);
    gtk_text_buffer_insert_markup(Buffer, @Iter, PChar(Markup), Length(Markup));
    gtk_text_view_set_buffer(View, Buffer);
    gtk_text_view_set_editable(View, False);
    gtk_text_view_set_cursor_visible(View, False);
    gtk_text_view_set_wrap_mode(View, GTK_WRAP_WORD_CHAR);
    gtk_container_add(PGtkContainer(Scroll), PGtkWidget(View));
    gtk_container_add(PGtkContainer(ParentWin), PGtkWidget(Scroll));
    gtk_widget_show(PGtkWidget(View));
    gtk_widget_show(PGtkWidget(Scroll));
    Result := HWND(Scroll);
  except
    Result := wlxInvalidHandle;
  end;
end;

procedure ListCloseWindow(ListWin: HWND); dcpcall;
begin
  gtk_widget_destroy(PGtkWidget(ListWin));
end;
{$ELSE}
function ListLoad(ParentWin: HWND; FileToLoad: PAnsiChar; ShowFlags: Integer): HWND; dcpcall;
var
  Browser: QTextBrowserH;
  Source, Html: String;
  WideHtml: UnicodeString;
begin
  try
    if FileToLoad = nil then
      raise EArgumentException.Create('A file name is required');
    Source := ReadUtf8File(String(FileToLoad));
    Html := RenderMarkdownHtml(Source);
    WideHtml := UTF8ToUTF16(Html);
    Browser := QTextBrowser_Create(QWidgetH(ParentWin));
    QTextEdit_setReadOnly(QTextEditH(Browser), True);
    QTextBrowser_setOpenLinks(Browser, False);
    QTextBrowser_setOpenExternalLinks(Browser, False);
    QTextEdit_setHtml(QTextEditH(Browser), @WideHtml);
    QWidget_setGeometry(QWidgetH(Browser), 0, 0, 100, 100);
    QWidget_show(QWidgetH(Browser));
    Result := HWND(Browser);
  except
    Result := wlxInvalidHandle;
  end;
end;

procedure ListCloseWindow(ListWin: HWND); dcpcall;
begin
  QWidget_destroy(QWidgetH(ListWin));
end;
{$ENDIF}
{$ENDIF}

procedure ListGetDetectString(DetectString: PAnsiChar; MaxLen: Integer); dcpcall;
begin
  StrPLCopy(DetectString, 'EXT="MD" | EXT="MARKDOWN" | EXT="MDOWN"', MaxLen - 1);
end;

function MarkdownWlxLicense: PAnsiChar; dcpcall;
begin
  Result := 'Copyright (C) 2026 Martin Brozkeff Malec; licensed under the EUPL 1.2';
end;

function MarkdownWlxVersion: PAnsiChar; dcpcall;
begin
  Result := '0.1.1';
end;

exports
  ListLoad,
  ListCloseWindow,
  ListGetDetectString,
  MarkdownWlxLicense,
  MarkdownWlxVersion;

end.
