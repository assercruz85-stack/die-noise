; Windows installer for Die Noise (Inno Setup 7). Built by tools/make_installer_win.ps1, which passes
; the version and the staging folder; the user picks the formats on the Components page.
#ifndef AppVersion
  #define AppVersion "1.0"
#endif
#ifndef Stage
  #define Stage "..\build-win\stage"
#endif

[Setup]
AppId={{6F1C2B8E-5D2A-4C43-9C1B-BE7A0C3A1E10}
AppName=Die Noise
AppVersion={#AppVersion}
AppVerName=Die Noise {#AppVersion}
AppPublisher=Kings Die Here
DefaultDirName={commoncf64}\Kings Die Here\Die Noise
DisableDirPage=yes
DisableProgramGroupPage=yes
OutputDir=..\dist
OutputBaseFilename=DieNoise-{#AppVersion}-Windows
Compression=lzma2/max
SolidCompression=yes
; x64 plugins also run on Windows on ARM in x64 and ARM64EC hosts (e.g. REAPER for ARM).
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=admin
WizardStyle=modern
UninstallDisplayName=Die Noise {#AppVersion} (Kings Die Here)

[Types]
Name: "full"; Description: "VST3 and CLAP"
Name: "custom"; Description: "Choose formats"; Flags: iscustom

[Components]
Name: "vst3"; Description: "VST3"; Types: full custom
Name: "clap"; Description: "CLAP"; Types: full custom

[Files]
Source: "{#Stage}\VST3\Die Noise.vst3\*"; DestDir: "{commoncf64}\VST3\Die Noise.vst3"; Components: vst3; Flags: recursesubdirs ignoreversion
Source: "{#Stage}\CLAP\Die Noise.clap"; DestDir: "{commoncf64}\CLAP"; Components: clap; Flags: ignoreversion
