; Inno Setup Script for LetNote Windows Installer Wizard
; Creates a standard Next -> Next -> Install setup executable

#define MyAppName "LetNote"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "LetNote Team"
#define MyAppExeName "let_note.exe"
#define MyAppIcon "..\..\windows\runner\resources\app_icon.ico"
#define MyAppSourceDir "..\..\build\windows\x64\runner\Release"

[Setup]
AppId={{C644265F-E69C-4A2D-A3CE-73A7FD94F25B}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL=https://github.com/Saurabh-Bhatia-Official/let_note
AppSupportURL=https://github.com/Saurabh-Bhatia-Official/let_note
AppUpdatesURL=https://github.com/Saurabh-Bhatia-Official/let_note/releases
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
OutputDir=..\..\build\windows_installer
OutputBaseFilename=LetNote-Windows-x64-Setup
SetupIconFile={#MyAppIcon}
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=lowest
UninstallDisplayIcon={app}\{#MyAppExeName}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "{#MyAppSourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
