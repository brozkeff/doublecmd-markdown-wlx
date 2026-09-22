unit MdRender;

{ Copyright (C) 2026 Martin Brozkeff Malec
  Licensed under the EUPL, Version 1.2. }

{$mode objfpc}{$H+}

interface

function RenderMarkdownHtml(const Source: String): String;
function RenderMarkdownPango(const Source: String): String;

implementation

uses
  Classes, SysUtils, StrUtils;

function EscapeMarkup(const Value: String): String;
begin
  Result := StringReplace(Value, '&', '&amp;', [rfReplaceAll]);
  Result := StringReplace(Result, '<', '&lt;', [rfReplaceAll]);
  Result := StringReplace(Result, '>', '&gt;', [rfReplaceAll]);
  Result := StringReplace(Result, '"', '&quot;', [rfReplaceAll]);
end;

function InlineMarkup(const Value: String; const Html: Boolean): String;
var
  S: String;
  InStrong, InCode, InEm: Boolean;
  I: Integer;
begin
  S := EscapeMarkup(Value);
  if not Html then
  begin
    Result := StringReplace(S, '**', '', [rfReplaceAll]);
    Result := StringReplace(Result, '__', '', [rfReplaceAll]);
    Result := StringReplace(Result, '`', '', [rfReplaceAll]);
    Exit(StringReplace(Result, '*', '', [rfReplaceAll]));
  end;
  Result := '';
  I := 1;
  InStrong := False;
  InCode := False;
  InEm := False;
  while I <= Length(S) do
  begin
    if (I < Length(S)) and (S[I] = '*') and (S[I + 1] = '*') then
    begin
      if InStrong then Result += '</strong>' else Result += '<strong>';
      InStrong := not InStrong;
      Inc(I, 2);
    end
    else if S[I] = '`' then
    begin
      if InCode then Result += '</code>' else Result += '<code>';
      InCode := not InCode;
      Inc(I);
    end
    else if S[I] = '*' then
    begin
      if InEm then Result += '</em>' else Result += '<em>';
      InEm := not InEm;
      Inc(I);
    end
    else
    begin
      Result += S[I];
      Inc(I);
    end;
  end;
  if InStrong then Result += '</strong>';
  if InCode then Result += '</code>';
  if InEm then Result += '</em>';
end;

function StripLink(const Value: String): String;
var
  OpenPos, ClosePos, EndPos: Integer;
begin
  Result := Value;
  OpenPos := Pos('[', Result);
  while OpenPos > 0 do
  begin
    ClosePos := PosEx('](', Result, OpenPos + 1);
    if ClosePos = 0 then Break;
    EndPos := PosEx(')', Result, ClosePos + 2);
    if EndPos = 0 then Break;
    Delete(Result, ClosePos, EndPos - ClosePos + 1);
    Delete(Result, OpenPos, 1);
    OpenPos := Pos('[', Result);
  end;
end;

function RenderLine(const Line: String; const Html: Boolean): String;
var
  S, Body: String;
  Level: Integer;
begin
  S := Line;
  if S = '' then Exit('');
  if StartsText('```', S) or StartsText('~~~', S) then Exit('');
  Level := 0;
  while (Level < Length(S)) and (S[Level + 1] = '#') do Inc(Level);
  if (Level > 0) and (Level <= 6) and (Length(S) > Level) and (S[Level + 1] = ' ') then
  begin
    Body := InlineMarkup(Copy(S, Level + 2, MaxInt), Html);
    if Html then Exit(Format('<h%d>%s</h%d>', [Level, Body, Level]));
    Exit('<span size="large" weight="bold">' + Body + '</span>');
  end;
  if (Length(S) >= 2) and ((S[1] = '-') or (S[1] = '*') or (S[1] = '+')) and (S[2] = ' ') then
  begin
    Body := InlineMarkup(Copy(S, 3, MaxInt), Html);
    if Html then Exit('<p>&bull; ' + Body + '</p>');
    Exit('• ' + Body);
  end;
  if (Length(S) >= 3) and (S[1] in ['0'..'9']) and (S[2] = '.') and (S[3] = ' ') then
  begin
    Body := InlineMarkup(Copy(S, 4, MaxInt), Html);
    if Html then Exit('<p>' + Copy(S, 1, 2) + ' ' + Body + '</p>');
    Exit(Copy(S, 1, 2) + ' ' + Body);
  end;
  Body := InlineMarkup(StripLink(S), Html);
  if Html then Result := '<p>' + Body + '</p>'
  else Result := Body;
end;

function RenderMarkdown(const Source: String; const Html: Boolean): String;
var
  Lines: TStringList;
  I: Integer;
  InCode: Boolean;
  Line, Rendered: String;
begin
  Lines := TStringList.Create;
  try
    Lines.Text := StringReplace(StringReplace(Source, #13#10, #10, [rfReplaceAll]), #13, #10, [rfReplaceAll]);
    Result := '';
    InCode := False;
    for I := 0 to Lines.Count - 1 do
    begin
      Line := Lines[I];
      if StartsText('```', Line) or StartsText('~~~', Line) then
      begin
        InCode := not InCode;
        Continue;
      end;
      if InCode then
      begin
        if Html then Rendered := '<pre>' + EscapeMarkup(Line) + '</pre>'
        else Rendered := '<tt>' + EscapeMarkup(Line) + '</tt>';
      end
      else
        Rendered := RenderLine(Line, Html);
      if Rendered <> '' then Result := Result + Rendered + IfThen(Html, '', #10);
    end;
    if Html then
      Result := '<html><head><meta charset="utf-8"><style>' +
        'body{font-family:sans-serif;font-size:10pt;margin:12px}' +
        'h1,h2,h3,h4,h5,h6{margin-top:12px;margin-bottom:4px}' +
        'p{margin:4px 0}pre,code{font-family:monospace}' +
        'pre{background:#eeeeee;padding:6px;white-space:pre-wrap}' +
        'li{margin:2px 0}' +
        '</style></head><body>' + Result + '</body></html>';
  finally
    Lines.Free;
  end;
end;

function RenderMarkdownHtml(const Source: String): String;
begin
  Result := RenderMarkdown(Source, True);
end;

function RenderMarkdownPango(const Source: String): String;
begin
  Result := RenderMarkdown(Source, False);
end;

end.
