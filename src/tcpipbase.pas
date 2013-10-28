(*
  Useful classes for TCP/IP communication.
  Copyright (c) 2013 by Silvio Clecio, Gilson Nunes Rodrigues and Waldir Paim

  See the file COPYING.FPC, included in this distribution,
  for details about the copyright.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
*)

unit TcpIpBase;

{$mode objfpc}{$H+}

interface

uses
  TcpIpUtils, SysUtils;

type

  { TTcpIpBaseSocket }

  TTcpIpBaseSocket = class
  private
    FPort: Word;
    FHost: string;
  protected
    function GetLastError: Integer; virtual; abstract;
  public
    constructor Create(const AHost: string; const APort: Word); virtual;
    function IsConnected: Boolean; virtual; abstract;
    property LastError: Integer read GetLastError;
    property Host: string read FHost;
    property Port: Word read FPort;
  end;

  { TTcpIpSocket }

  TTcpIpSocket = class(TTcpIpBaseSocket)
  public
    function CanWrite(const ATimeOut: Integer): Boolean; virtual; abstract;
    function CanRead(const ATimeOut: Integer): Boolean; virtual; abstract;
    function Waiting: Integer; virtual; abstract;
    function Write(const ABuffer; ACount: LongInt): LongInt; virtual; abstract;
    function Read(var ABuffer; ACount: LongInt): LongInt; virtual; abstract;
    function Send(const ABuffer; ACount: LongInt;
      const ATimeOut: Integer): LongInt;
    function Receive(var ABuffer; ACount: LongInt;
      const ATimeOut: Integer): LongInt;
  end;

resourcestring
  STcpIpSocketError = 'Socket error: %d.';

implementation

{ TTcpIpBaseSocket }

constructor TTcpIpBaseSocket.Create(const AHost: string;
  const APort: Word);
begin
  FHost := AHost;
  FPort := APort;
end;

{ TTcpIpSocket }

function TTcpIpSocket.Send(const ABuffer; ACount: LongInt;
  const ATimeOut: Integer): LongInt;
var
  VPByte: PByte;
  VEndTick: QWord;
  VWriteCount: LongInt;
begin
  if not IsConnected or (ACount < 1) then
  begin
    Result := 0;
    Exit;
  end;
  Result := ACount;
  VEndTick := GetTickCount64 + ATimeOut;
  VPByte := @ABuffer;
  while ACount > 0 do
  begin
    VWriteCount := Write(VPByte^, ACount);
    if VWriteCount < 0 then
      raise ETcpIpError.CreateFmt(STcpIpSocketError, [GetLastError]);
    if VWriteCount > 0 then
    begin
      Inc(VPByte, VWriteCount);
      Dec(ACount, VWriteCount);
    end
    else
    if GetTickCount64 > VEndTick then
      Break;
  end;
  Dec(Result, ACount);
end;

function TTcpIpSocket.Receive(var ABuffer; ACount: LongInt;
  const ATimeOut: Integer): LongInt;
var
  VPByte: PByte;
  VEndTick: QWord;
  VInfinite: Boolean;
  VReadCount: LongInt;
begin
  if not IsConnected or (ACount < 1) then
  begin
    Result := 0;
    Exit;
  end;
  Result := ACount;
  VInfinite := ATimeOut = TCP_IP_INFINITE_TIMEOUT;
  if VInfinite then
    VEndTick := 0
  else
    VEndTick := GetTickCount64 + ATimeOut;
  VPByte := @ABuffer;
  while ACount > 0 do
  begin
    VReadCount := Read(VPByte^, ACount);
    if VReadCount < 0 then
      raise ETcpIpError.CreateFmt(STcpIpSocketError, [GetLastError]);
    if VReadCount > 0 then
    begin
      Inc(VPByte, VReadCount);
      Dec(ACount, VReadCount);
    end
    else
    if not VInfinite then
      if GetTickCount64 > VEndTick then
        Break;
  end;
  Dec(Result, ACount);
end;

end.
