program AdjustCbodem;

uses
  Forms,
  Sysutils,
  uError,
  uAdjustCbodem in 'uAdjustCbodem.pas' {MainForm};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Mode := Interactive;
  Try
    Try
      if ( ParamCount = 5 ) then begin
        Mode := Batch;
        with MainForm do begin
          Editfl3.Text := ParamStr( 1 );
          Editplas.Text := ParamStr( 2 );
          EditCorg.Text := ParamStr( 3 );
          ESBPosFloatEdit_F.Text := ParamStr( 4 );
          {-ParamStr( 5 ): result-idf, zie unit 'uAdjustCbodem' }
        end;
      end; {if ( ParamCount = 5 )}

      if ( Mode = Interactive ) then begin
        Application.Run;
      end else begin
        MainForm.GoButton.Click;
      end;
    Except
      WriteToLogFileFmt( 'Error in application: [%s].', [ApplicationFileName] );
    end;
  Finally
  end;
end.
