unit uScriptsGenerator;

interface

uses
  uProjectSettings;

type
  TScriptsGenerator = class
  private
    FSettings : TProjectSettings;
    procedure GenerateDCovExecuteFile;
    procedure GenerateDCovUnitsAndPathFiles;
    function FGetOutputFormatSwitches : string;
    function FGetPath(const APath : string) : string;
  public
    constructor Create(const ASettings : TProjectSettings); virtual;
    destructor Destroy; override;
    procedure Generate;
  end;

implementation

uses
  Classes, SysUtils, IOUtils;

constructor TScriptsGenerator.Create(const ASettings: TProjectSettings);
begin
  FSettings := ASettings;
end;

destructor TScriptsGenerator.Destroy;
begin
  FSettings := nil;
end;

procedure TScriptsGenerator.Generate;
begin
  // Generate
  GenerateDCovExecuteFile();
  GenerateDCovUnitsAndPathFiles();
end;

procedure TScriptsGenerator.GenerateDCovExecuteFile;
const
  // Application path,  ProgramToAnalyze,  ProgramMapping,  ReportPath
  DCOV_EXECUTE_FORMAT = '"%sCodeCoverage.exe" -e "%s" -m "%s" -uf dcov_units.lst -spf dcov_paths.lst -od "%s" -lt';
var
  DCovExecuteText : TStringList;
begin
  // Create 'dcov_execute.bat'
  DCovExecuteText := TStringList.Create;
  // Fill
  DCovExecuteText.Add(Format(DCOV_EXECUTE_FORMAT,
                      [FGetPath(FSettings.ApplicationPath),
                       FGetPath(FSettings.ProgramToAnalyze),
                       FGetPath(FSettings.ProgramMapping),
                       FGetPath(FSettings.ReportPath)]) +
                       FGetOutputFormatSwitches());
  // Save
  DCovExecuteText.SaveToFile(FSettings.ScriptsPath + 'dcov_execute.bat');
  FreeAndNil(DCovExecuteText);
end;

procedure TScriptsGenerator.GenerateDCovUnitsAndPathFiles;
var
  DCovUnitsText : TStringList;
  DCovPathsText : TStringList;
  CheckedUnitList : TStrings;
  UnitFilename: string;
begin
  // Create 'dcov_execute.bat'
  DCovUnitsText := TStringList.Create;
  DCovUnitsText.Sorted := True;
  DCovUnitsText.Duplicates := dupIgnore;

  DCovPathsText := TStringList.Create;
  DCovPathsText.Sorted := True;
  DCovPathsText.Duplicates := dupIgnore;

  // Get Checked unit list
  CheckedUnitList := TStringList.Create;
  FSettings.ProgramSourceFiles.GetCheckedItemsList(CheckedUnitList);

  for UnitFilename in CheckedUnitList do
  begin
    // Add Unit name
    DCovUnitsText.Add(ChangeFileExt(ExtractFileName(UnitFilename), ''));
    // Add unit path
    DCovPathsText.Add(FSettings.ProgramSourcePath + ExtractFilePath(UnitFilename));
  end;
  // Save
  DCovUnitsText.SaveToFile(FSettings.ScriptsPath + 'dcov_units.lst');
  DCovPathsText.SaveToFile(FSettings.ScriptsPath + 'dcov_paths.lst');
  // Free
  FreeAndNil(CheckedUnitList);
  FreeAndNil(DCovUnitsText);
  FreeAndNil(DCovPathsText);
end;

function TScriptsGenerator.FGetOutputFormatSwitches: string;
begin
  Result := '';
  if(ofEMMA in FSettings.OutputFormat) then Result := Result + ' -emma';
  if(ofMETA in FSettings.OutputFormat) then Result := Result + ' -meta';
  if(ofXML in FSettings.OutputFormat) then Result := Result + ' -xml';
  if(ofHTML in FSettings.OutputFormat) then Result := Result + ' -html';
end;

function TScriptsGenerator.FGetPath(const APath: string): string;
begin
  if(FSettings.RelativeToScriptPath) then
  // Extract path relative to scripts relative
   Result := ExtractRelativepath(FSettings.ScriptsPath , APath)
  else Result := APath;
end;

end.
