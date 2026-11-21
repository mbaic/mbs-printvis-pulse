namespace MBS.PrintVisPulse.Pages;

/// <summary>
/// Optional entry point. It only links to the dashboards declaratively with RunObject,
/// because Business Central ignores OnAction triggers on Role Center actions.
/// </summary>
page 50010 "MBS PV Pulse Role Center"
{
    ApplicationArea = All;
    Caption = 'MBS PrintVis Pulse';
    Access = Internal;
    PageType = RoleCenter;

    layout
    {
        area(RoleCenter)
        {
            systempart(MyNotes; MyNotes)
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        area(Sections)
        {
            group(Dashboards)
            {
                Caption = 'Dashboards';
                action(SalesDashboard)
                {
                    ApplicationArea = All;
                    Caption = 'Sales and Quote Pipeline';
                    RunObject = page "MBS PV Sales Dashboard";
                    ToolTip = 'Opens the quote pipeline dashboard.';
                }
                action(ProductionDashboard)
                {
                    ApplicationArea = All;
                    Caption = 'Production Pulse';
                    RunObject = page "MBS PV Prod Dashboard";
                    ToolTip = 'Opens the production pulse dashboard.';
                }
                action(ProfitabilityDashboard)
                {
                    ApplicationArea = All;
                    Caption = 'Job Profitability';
                    RunObject = page "MBS PV Profit Dashboard";
                    ToolTip = 'Opens the job profitability dashboard.';
                }
            }
        }
        area(Embedding)
        {
            action(SalesDashboardEmbed)
            {
                ApplicationArea = All;
                Caption = 'Sales and Quote Pipeline';
                RunObject = page "MBS PV Sales Dashboard";
                ToolTip = 'Opens the quote pipeline dashboard.';
            }
            action(ProductionDashboardEmbed)
            {
                ApplicationArea = All;
                Caption = 'Production Pulse';
                RunObject = page "MBS PV Prod Dashboard";
                ToolTip = 'Opens the production pulse dashboard.';
            }
            action(ProfitabilityDashboardEmbed)
            {
                ApplicationArea = All;
                Caption = 'Job Profitability';
                RunObject = page "MBS PV Profit Dashboard";
                ToolTip = 'Opens the job profitability dashboard.';
            }
        }
    }
}
