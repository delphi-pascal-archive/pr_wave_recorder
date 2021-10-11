{
Прием и показ звука с одного из входов "Запись"
и запись в файл wav
оригинал: programania.com/sv.zip
}
unit Unit1;

interface

uses
 Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
 Dialogs, StdCtrls, ExtCtrls, ComCtrls, MMSystem, Buttons;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Label1: TLabel;
    Image1: TImage;
    Button3: TButton;
    Label2: TLabel;
    BitBtn1: TBitBtn;
    CheckBox1: TCheckBox;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure Button3Click(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
  private
    { Private declarations }
  public
  procedure OnWaveIn(var Msg: TMessage); message MM_WIM_DATA;
    { Public declarations }
  end;

TData16 = array [0..127] of smallint;
PData16 = ^TData16;
tWaveFileHdr = packed record
  riff: array[0..3] of Char;
  len: DWord;
  cWavFmt: array[0..7] of Char;
  dwHdrLen: DWord;
  wFormat: Word;
  wNumChannels: Word;
  dwSampleRate: DWord;
  dwBytesPerSec: DWord;
  wBlockAlign: Word;
  wBitsPerSample: Word;
  cData: array[0..3] of Char;
  dwDataLen: DWord;
end;

const BufSize=11000; { Размер буфера на 1 сек}

var
Form1: TForm1;

implementation

var
WaveIn: hWaveIn;
hBuf: THandle;
BufHead: TWaveHdr;
m:array[1..bufSize] of smallInt;
h,w,h2:integer;
zs:boolean=false;//запущен звук
//Для записи в wav
rec:boolean=false;  //идет запись
mz :array of smallInt;
waveHdr:tWaveFileHdr;
qz:integer;  //записано звука;

{$R *.DFM}

PROCEDURE iniWav;
begin
WaveHdr.riff:='RIFF';
WaveHdr.cWavFmt:='WAVEfmt ';
WaveHdr.dwHdrLen:=16;
WaveHdr.wFormat:=1;
WaveHdr.wNumChannels:=1;
WaveHdr.dwSampleRate:=11000;
WaveHdr.wBlockAlign:=4;
WaveHdr.dwBytesPerSec:=22000;
WaveHdr.wBitsPerSample:=16;
WaveHdr.cData:='data';
WaveHdr.dwDataLen:=qz*2;
end;

procedure TForm1.Button1Click(Sender: TObject);
var
 header: TWaveFormatEx;
 BufLen: word;
 buf: pointer;
begin
if zs then exit;
 with header do begin
   wFormatTag := WAVE_FORMAT_PCM;
   nChannels := 1;         // количество каналов
   nSamplesPerSec := 11000;// частота
   wBitsPerSample := 16;   // бит на отсчет
   nBlockAlign := nChannels * (wBitsPerSample div 8);
   nAvgBytesPerSec := nSamplesPerSec * nBlockAlign;
   cbSize := 0;
 end;
 WaveInOpen(Addr(WaveIn), WAVE_MAPPER, addr(header),Form1.Handle, 0, CALLBACK_WINDOW);
 BufLen := header.nBlockAlign * BufSize;
 hBuf := GlobalAlloc(GMEM_MOVEABLE and GMEM_SHARE, BufLen);
 Buf := GlobalLock(hBuf);
 with BufHead do begin
   lpData := Buf;
   dwBufferLength := BufLen;
   dwFlags := WHDR_BEGINLOOP;
 end;
 WaveInPrepareHeader(WaveIn, Addr(BufHead), sizeof(BufHead));
 WaveInAddBuffer(WaveIn, addr(BufHead), sizeof(BufHead));
 zs:=true;
 WaveInStart(WaveIn);
End;

procedure TForm1.Button2Click(Sender: TObject);
begin
if not zs then Exit;
WaveInReset(WaveIn);
WaveInUnPrepareHeader(WaveIn, addr(BufHead), sizeof(BufHead));
WaveInClose(WaveIn);
GlobalUnlock(hBuf);
GlobalFree(hBuf);
zs:=false;
end;

procedure TForm1.OnWaveIn;
var
 data16: PData16;
 i,d,z,s,x,y,xx,max,s0: integer;
begin
//сразу пустим запись дальше чтоб не прерывалась
WaveInAddBuffer(WaveIn, PWaveHdr(Msg.lParam),SizeOf(TWaveHdr));
data16 := PData16(PWaveHdr(Msg.lParam)^.lpData);

//перепишем звук из массива в который пишется
//в массив который обрабатывается чтоб запись его не портила
move(data16^[0],m,BufSize*2);
if data16^[0]<>m[1] then showMessage('Не успела');

//Обработка звука
s:=0;
s0:=0;
max:=0;
for i := 1 to BufSize do begin
  z:=m[i];
  inc(s0,z);
  z:=abs(z);
  inc(s,z);
  if z>max then max:=z;
end;

//показ звука
s:=s div bufSize;
s0:=s0 div bufSize;
label1.caption:='Среднее: '+intToStr(s)+
            ',    Максимум: '+intToStr(max)+
            ',    Постоянный уровень: '+intToStr(s0);

with form1.image1.Picture.Bitmap.canvas do begin
fillRect(rect(0,0,w,h));
pen.color:=$CCCCCC; moveTo(w,h2); lineTo(0,h2);
pen.color:=0;

max:=abs(max-abs(s0));
if max<16 then max:=16;
if checkBox1.checked then d:=BufSize else d:=w;
for x:=1 to w do begin
  xx:=x*BufSize div d;
  y:=h2+(m[xx]-s0)*h2 div max;
  if x=1 then moveTo(0,y) else lineTo(x,y);
end;
end;

if rec then begin
//запись в массив для файла
  setLength(mz,qz+bufSize+1);
  move(m[1],mz[qz+1],BufSize*2);
  inc(qz,BufSize);
  form1.label2.caption:='Записано '+formatFloat('0.00',qz*2/1000000)+' мб';
end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
w:=image1.width;
h:=image1.height;
h2:=h div 2;
image1.Picture.Bitmap.width:=w;
image1.Picture.Bitmap.height:=h;
Form1.Button1Click(Sender);
end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
Form1.Button2Click(Sender)
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
winExec('SndVol32.exe /r',SW_SHOW);
end;

procedure TForm1.BitBtn1Click(Sender: TObject);
var fw:file;
begin
if rec then begin
rec:=false;
  if qz>0 then begin
//вывод в файл wav
    iniWav;
    assignFile(fw,'sound.wav');
    rewrite(fw,1);
    blockWrite(fw,waveHdr,sizeOf(waveHdr));
    blockWrite(fw,mz[1],qz*2);
    closeFile(fw);
    showMessage('Записано в "sound.wav"');
    label2.visible:=false;
    BitBtn1.caption:='Запись';
end;
end
else begin
qz:=0;
rec:=true;
label2.visible:=true;
BitBtn1.caption:='Стой';
end;
end;

end.
