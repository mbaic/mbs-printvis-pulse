namespace MBS.PrintVisPulse.Pages;

using MBS.PrintVisPulse.Diagnostics;
using System.Utilities;

/// <summary>
/// Diagnostic page. Collects a text profile of the PrintVis data that the dashboards depend on,
/// so the data can be checked against the KPI rules. Read-only. Use Download to save the report as a text file.
/// </summary>
page 50021 "MBS PV Data Info"
{
    ApplicationArea = All;
    Caption = 'MBS PrintVis Pulse Data Info';
    PageType = Card;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            group(Report)
            {
                Caption = 'Report';
                field(InfoField; InfoText)
                {
                    ApplicationArea = All;
                    Editable = false;
                    MultiLine = true;
                    ShowCaption = false;
                    ToolTip = 'Specifies the data profile of the PrintVis tables used by the dashboards.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CollectAgain)
            {
                ApplicationArea = All;
                Caption = 'Collect Again';
                Image = Refresh;
                ToolTip = 'Collects the data profile again.';

                trigger OnAction()
                begin
                    Collect();
                end;
            }
            action(Download)
            {
                ApplicationArea = All;
                Caption = 'Download';
                Image = Download;
                ToolTip = 'Downloads the data profile as a text file.';

                trigger OnAction()
                begin
                    DownloadReport();
                end;
            }
        }
        area(Promoted)
        {
            actionref(Download_Promoted; Download)
            {
            }
        }
    }

    var
        InfoText: Text;
        FileNameTxt: Label 'PrintVisPulseDataInfo.txt', Locked = true;

    trigger OnOpenPage()
    begin
        Collect();
    end;

    local procedure Collect()
    var
        DataInfo: Codeunit "MBS PV Data Info";
    begin
        InfoText := DataInfo.Collect();
    end;

    local procedure DownloadReport()
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        FileName: Text;
    begin
        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(InfoText);
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        FileName := FileNameTxt;
        DownloadFromStream(InStr, '', '', '', FileName);
    end;
}
