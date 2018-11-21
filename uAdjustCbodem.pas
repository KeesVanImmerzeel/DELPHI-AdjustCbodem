unit uAdjustCbodem;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, uTSingleESRIgrid, uError, Registry, ESBPCSEdit, ESBPCSNumEdit,
  uTabstractESRIgrid, AVGRIDIO;

type
  TMainForm = class(TForm)
    GoButton: TButton;
    SingleESRIgridFL3: TSingleESRIgrid;
    SingleESRIgridPlas: TSingleESRIgrid;
    SingleESRIgridcOrg: TSingleESRIgrid;
    Memo1: TMemo;
    Editfl3: TEdit;
    Editplas: TEdit;
    EditCorg: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    OpenDialogfl3: TOpenDialog;
    OpenDialogPlas: TOpenDialog;
    OpenDialogcOrg: TOpenDialog;
    SaveDialog1: TSaveDialog;
    ESBPosFloatEdit_F: TESBPosFloatEdit;
    Label4: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure Editfl3Click(Sender: TObject);
    procedure EditplasClick(Sender: TObject);
    procedure EditCorgClick(Sender: TObject);
    procedure GoButtonClick(Sender: TObject);
    procedure ESBPosFloatEdit_FChange(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    
  private
    { Private declarations }
  public
    { Public declarations }
    FIniFile: TRegIniFile;
  end;

  EInputFileDoesNotExist = class( Exception );
  EErrorOpeningIDFfile = class( Exception );

ResourceString
  sInputFileDoesNotExist = 'Input-file "%s" does not exist.';
  sErrorOpeningIDFfile = 'Error opening idf-file: "%s".';

var
  MainForm: TMainForm;

  implementation

{$R *.DFM}

procedure TMainForm.FormCreate(Sender: TObject);
begin
  InitialiseLogFile;
  InitialiseGridIO;
  Caption := ExtractFileName( ChangeFileExt( ParamStr( 0 ), '' ) );
  FIniFile := TRegIniFile.Create( 'ParamStr( 0 )' );
  if ( Mode = Interactive ) then begin
    Editfl3.Text  := FIniFile.ReadString( 'Settings', 'EditFl3', 'EditFl3' );
    Editplas.text := FIniFile.ReadString( 'Settings', 'EditPlas', 'EditPlas' );
    EditCorg.Text := FIniFile.ReadString( 'Settings', 'EditCorg', 'EditCorg' );
    ESBPosFloatEdit_F.Text := FIniFile.ReadString( 'Settings', 'Edit_F', '2250' );
  end;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
FinaliseLogFile;
end;

procedure TMainForm.Editfl3Click(Sender: TObject);
begin
  with OpenDialogfl3 do begin
    if execute then begin
      Editfl3.Text := ExpandFileName( FileName );
      FIniFile.WriteString( 'Settings', 'EditFl3', Editfl3.Text );
    end;
  end;
end;

procedure TMainForm.EditplasClick(Sender: TObject);
begin
  with OpenDialogPlas do begin
    if execute then begin
      Editplas.text := ExpandFileName( FileName );
      FIniFile.WriteString( 'Settings', 'EditPlas', Editplas.text );
    end;
  end;
end;

procedure TMainForm.EditCorgClick(Sender: TObject);
begin
  with OpenDialogcOrg do begin
    if execute then begin
      EditCorg.Text := ExpandFileName( FileName );
      FIniFile.WriteString( 'Settings', 'EditCorg', EditCorg.Text );
    end;
  end;
end;

procedure TMainForm.GoButtonClick(Sender: TObject);
var
  iResult: Integer;

Procedure AdjustCvalues; {-Verhoog de c-waarden op de plasbodem (evenredig met de infiltratieflux}
var
  NRows, NCols, i, j: integer;
  x, y, aValue, flxM3perD, cAddedValue, flxMperD: Single;
  fValue, CellArea: Double;
begin
  NRows := SingleESRIgridcOrg.NRows;
  NCols := SingleESRIgridcOrg.NCols;
  for i:=1 to NRows do begin
    for j:=1 to NCols do begin
      SingleESRIgridcOrg.GetCellCentre( i, j, x, y );
      aValue := SingleESRIgridPlas.GetValueXY( x, y );
      if ( aValue > 0 ) then begin {-Als het een cel is op de plasbodem}
        flxM3perD := SingleESRIgridFL3.GetValueXY( x, y );
        if ( flxM3perD < 0 ) then begin {-Als er infiltratie wordt berekend}
          CellArea := SingleESRIgridFL3.CellArea;
          flxMperD := flxM3perD / CellArea;
          fValue   := ESBPosFloatEdit_F.AsFloat;
          cAddedValue := - fValue * flxMperD;
          SingleESRIgridcOrg[ i, j ] := SingleESRIgridcOrg[ i, j ] + cAddedValue;
        end;
      end;
    end;
  end; {-for i}
end; {-Procedure AdjustCvalues;}

begin
  with SaveDialog1 do begin
    if ( Mode = Interactive ) then
      FileName := FIniFile.ReadString( 'Settings', 'DirOfgridcResult', 'c:' ) + '\cResult.idf';
    if ( Mode = Batch ) or ( ( Mode = Interactive ) and Execute ) then begin
      try
        try
          if ( Mode = Interactive ) then
            FIniFile.WriteString( 'Settings', 'DirOfgridcResult', ExtractFileDir ( FileName ) )
          else
            FileName := ParamStr( 5 );

          {-Controleer het bestaan van de invoer-idf bestanden}
          if ( not FileExists( Editfl3.Text ) ) then
            Raise EInputFileDoesNotExist.CreateResFmt( @sInputFileDoesNotExist, [ Editfl3.Text ] );
          if ( not FileExists( Editplas.Text ) ) then
            Raise EInputFileDoesNotExist.CreateResFmt( @sInputFileDoesNotExist, [ Editplas.Text ] );
          if ( not FileExists( EditCorg.Text ) ) then
            Raise EInputFileDoesNotExist.CreateResFmt( @sInputFileDoesNotExist, [ EditCorg.Text ] );

          {-Open invoer idf-bestanden}
          SingleESRIgridFL3 := TSingleESRIgrid.InitialiseFromIDFfile( Editfl3.Text, iResult, self );
          if ( iResult <> cNoError ) then
            Raise EErrorOpeningIDFfile.CreateResFmt( @sErrorOpeningIDFfile, [ Editfl3.Text ] );
          SingleESRIgridPlas := TSingleESRIgrid.InitialiseFromIDFfile( Editplas.Text, iResult, self );
          if ( iResult <> cNoError ) then
            Raise EErrorOpeningIDFfile.CreateResFmt( @sErrorOpeningIDFfile, [ Editplas.Text ] );
          SingleESRIgridcOrg := TSingleESRIgrid.InitialiseFromIDFfile( EditCorg.Text, iResult, self );
          if ( iResult <> cNoError ) then
            Raise EErrorOpeningIDFfile.CreateResFmt( @sErrorOpeningIDFfile, [ EditCorg.Text ] );

          AdjustCvalues;

          SingleESRIgridcOrg.ExportToIDFfile( FileName );

        Except
          On E: Exception do begin
            HandleError( E.Message, true );
          end;
        end; {-Except}
      Finally
      end; {-Finally}

    end; {if execute }
  end; {with SaveCresultIdfDialog }
end;

procedure TMainForm.ESBPosFloatEdit_FChange(Sender: TObject);
begin
  FIniFile.WriteString( 'Settings', 'Edit_F', ESBPosFloatEdit_F.Text  );
end;

initialization
  FormatSettings.DecimalSeparator := '.';
  Mode := interactive;
finalization

end.
