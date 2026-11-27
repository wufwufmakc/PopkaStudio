; (UTF-8 with a BOM: Inno Setup reads the Russian lines right only so)
; PopkaStudio-Setup.exe - the classic Windows installer (Inno Setup 6). Built by .github/workflows/windows-installer.yml:
;   iscc /DAppVersion=2.7 installer\PopkaStudio.iss      -> installer\Output\PopkaStudio-Setup-2.7.exe
; It holds PopkaStudio's own files (a few tens of MB); what is big - Python, arduino-cli, the ESP32 tools (1.5-3 GB) -
; install.ps1 -Setup downloads after the files are in, as install.ps1 does for a clone. For this user only, no
; administrator: %LOCALAPPDATA%\PopkaStudio (a short path: the ESP32 build doesn't like long ones). Your projects
; (projects\) stay on an uninstall; what the installer downloaded goes.

#ifndef AppVersion
  #define AppVersion "0.0"
#endif

[Setup]
AppId={{6C1F3B0E-2F5B-4C1E-9C55-9F0A2B7D4E61}
AppName=PopkaStudio
AppVersion={#AppVersion}
AppVerName=PopkaStudio {#AppVersion}
AppPublisher=PopkaStudio
AppPublisherURL=https://github.com/wufwufmakc/PopkaStudio
DefaultDirName={localappdata}\PopkaStudio
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
OutputDir=Output
OutputBaseFilename=PopkaStudio-Setup-{#AppVersion}
SetupIconFile=popkastudio.ico
UninstallDisplayIcon={app}\installer\popkastudio.ico
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
CloseApplications=yes

[Languages]
Name: "en"; MessagesFile: "compiler:Default.isl"
Name: "ru"; MessagesFile: "compiler:Languages\Russian.isl"

[CustomMessages]
en.Tools=Downloading Python, arduino-cli and the ESP32 tools (1.5-3 GB, 5-20 minutes the first time)...
ru.Tools=Загрузка Python, arduino-cli и инструментов ESP32 (1,5-3 ГБ, первый раз 5-20 минут)...
en.ToolsFailed=PopkaStudio's files are in, but downloading its tools failed (exit %1). Check the internet and run the installer again. The log: %2
ru.ToolsFailed=Файлы PopkaStudio установлены, но загрузить инструменты не удалось (код %1). Проверьте интернет и запустите установщик ещё раз. Лог: %2
en.Desktop=Create a desktop shortcut
ru.Desktop=Создать ярлык на рабочем столе

[Tasks]
Name: "desktop"; Description: "{cm:Desktop}"; Flags: unchecked

[Files]
Source: "..\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion; \
  Excludes: "\.git,\.git\*,\.github\*,\docs\*,\studio\app\node_modules\*,\installer\Output\*,\.venv\*,\.tools\*,\build\*,\projects\*,\studio\secrets\*,\studio\backups\*,\studio\videos\*,\tools\fonts\*"

[Dirs]
Name: "{app}\projects"; Flags: uninsneveruninstall

[Icons]
Name: "{userprograms}\PopkaStudio"; Filename: "{app}\bin\popkastudio.cmd"; WorkingDir: "{app}"; \
  IconFilename: "{app}\installer\popkastudio.ico"; Flags: runminimized
Name: "{userdesktop}\PopkaStudio"; Filename: "{app}\bin\popkastudio.cmd"; WorkingDir: "{app}"; \
  IconFilename: "{app}\installer\popkastudio.ico"; Flags: runminimized; Tasks: desktop

[Run]
Filename: "{app}\bin\popkastudio.cmd"; WorkingDir: "{app}"; Description: "{cm:LaunchProgram,PopkaStudio}"; \
  Flags: postinstall nowait skipifsilent runminimized

[UninstallRun]
; (a running PopkaStudio holds its Python: stop it first, by its port's owner)
Filename: "powershell.exe"; Parameters: "-NoProfile -Command ""Get-NetTCPConnection -LocalPort 8466 -State Listen -ErrorAction SilentlyContinue | ForEach-Object {{ Stop-Process -Id $_.OwningProcess -Force }"""; \
  Flags: runhidden; RunOnceId: "StopStudio"

[UninstallDelete]
Type: filesandordirs; Name: "{app}\.venv"
Type: filesandordirs; Name: "{app}\.tools"
Type: filesandordirs; Name: "{app}\build"
Type: filesandordirs; Name: "{app}\tools\fonts"
Type: filesandordirs; Name: "{app}\studio\__pycache__"
Type: files; Name: "{app}\install.log"

[Code]
procedure CurStepChanged(CurStep: TSetupStep);
var
  Code: Integer;
  Log: String;
begin
  if CurStep <> ssPostInstall then
    Exit;
  WizardForm.StatusLabel.Caption := CustomMessage('Tools');
  Log := ExpandConstant('{app}\install.log');
  if not Exec(ExpandConstant('{sys}\WindowsPowerShell\v1.0\powershell.exe'),
              '-NoProfile -ExecutionPolicy Bypass -File "' + ExpandConstant('{app}\install.ps1') + '" -Setup',
              ExpandConstant('{app}'), SW_SHOW, ewWaitUntilTerminated, Code) then
    Code := -1;
  if Code <> 0 then
    SuppressibleMsgBox(FmtMessage(CustomMessage('ToolsFailed'), [IntToStr(Code), Log]), mbError, MB_OK, IDOK);
end;
