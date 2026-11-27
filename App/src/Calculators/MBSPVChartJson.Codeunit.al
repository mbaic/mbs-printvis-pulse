namespace MBS.PrintVisPulse.Calculators;

using MBS.PrintVisPulse.Buffers;

/// <summary>
/// Pure helpers shared by the calculators: chart group accumulation and chart JSON serialization.
/// No database access and no clock access.
/// </summary>
codeunit 50023 "MBS PV Chart Json"
{
    Access = Internal;

    var
        UnassignedGroupTok: Label 'UNASSIGNED', Locked = true;

    /// <summary>
    /// Adds the amounts to the group and refreshes its descending sort value (negated, so an ascending key gives a descending order).
    /// </summary>
    procedure AddGroupTotal(var Groups: Record "MBS PV Chart Group Buffer" temporary; GroupCode: Code[20]; Amount1: Decimal; Amount2: Decimal; SortBySeries2: Boolean)
    begin
        if GroupCode = '' then
            GroupCode := UnassignedGroupTok;
        if not Groups.Get(GroupCode) then begin
            Groups.Init();
            Groups."Group Code" := GroupCode;
            Groups.Insert();
        end;
        Groups."Series 1" += Amount1;
        Groups."Series 2" += Amount2;
        if SortBySeries2 then
            Groups."Sort Amount" := -Groups."Series 2"
        else
            Groups."Sort Amount" := -Groups."Series 1";
        Groups.Modify();
    end;

    /// <summary>
    /// Serializes the top 5 groups (highest Sort Amount rank first) as chart JSON. Series 2 is written only when a label is supplied.
    /// </summary>
    procedure BuildTop5ChartJson(TitleText: Text; Series1Label: Text; Series2Label: Text; EmptyMessage: Text; var Groups: Record "MBS PV Chart Group Buffer" temporary): Text
    var
        RootObj: JsonObject;
        LabelsArr: JsonArray;
        Values1Arr: JsonArray;
        Values2Arr: JsonArray;
        RankNo: Integer;
        ResultText: Text;
    begin
        Groups.Reset();
        Groups.SetCurrentKey("Sort Amount", "Group Code");
        if Groups.FindSet() then
            repeat
                RankNo += 1;
                Groups."Display Rank" := RankNo;
                Groups.Modify();
                LabelsArr.Add(Groups."Group Code");
                Values1Arr.Add(Groups."Series 1");
                Values2Arr.Add(Groups."Series 2");
            until (Groups.Next() = 0) or (RankNo = 5);

        RootObj.Add('title', TitleText);
        RootObj.Add('series1Label', Series1Label);
        RootObj.Add('emptyMessage', EmptyMessage);
        RootObj.Add('labels', LabelsArr);
        RootObj.Add('series1', Values1Arr);
        if Series2Label <> '' then begin
            RootObj.Add('series2Label', Series2Label);
            RootObj.Add('series2', Values2Arr);
        end;
        RootObj.WriteTo(ResultText);
        exit(ResultText);
    end;
}
