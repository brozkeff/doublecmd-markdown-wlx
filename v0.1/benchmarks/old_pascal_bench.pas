program OldPascalBench;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, MdRender;

var
  Stream: TFileStream;
  Source, Rendered: String;
  Iterations, I: Integer;
  OutputBytes: Int64;
  Started, Elapsed: QWord;
begin
  if ParamCount <> 2 then
  begin
    WriteLn(StdErr, 'Usage: old-pascal-bench FILE ITERATIONS');
    Halt(2);
  end;
  Iterations := StrToInt(ParamStr(2));
  if Iterations < 1 then
  begin
    WriteLn(StdErr, 'ITERATIONS must be greater than zero');
    Halt(2);
  end;

  Stream := TFileStream.Create(ParamStr(1), fmOpenRead or fmShareDenyNone);
  try
    SetLength(Source, Stream.Size);
    if Length(Source) > 0 then
      Stream.ReadBuffer(Source[1], Length(Source));
  finally
    Stream.Free;
  end;

  OutputBytes := 0;
  Started := GetTickCount64;
  for I := 1 to Iterations do
  begin
    Rendered := RenderMarkdownHtml(Source);
    OutputBytes := OutputBytes + Length(Rendered);
  end;
  Elapsed := GetTickCount64 - Started;
  WriteLn('pascal iterations=', Iterations, ' total_ms=', Elapsed,
    ' per_render_us=', (Elapsed * 1000) div QWord(Iterations),
    ' output_bytes=', OutputBytes div Iterations);
end.
