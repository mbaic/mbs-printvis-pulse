controladdin "MBS PV Chart Host"
{
    StartupScript = 'src/ControlAddIn/scripts/startup.js';
    Scripts = 'src/ControlAddIn/scripts/chartHost.js';
    StyleSheets = 'src/ControlAddIn/scripts/chartHost.css';
    RequestedHeight = 280;
    MinimumHeight = 240;
    HorizontalStretch = true;
    VerticalStretch = false;

    event OnControlReady();
    procedure RenderBarChart(ChartJson: Text);
}
