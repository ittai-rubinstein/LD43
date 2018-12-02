import 'TextOnCanvas.dart';


class MissionControl{
    static TextOnCanvas toc = TextOnCanvas("MissionControl", "Mission Control");

    static void UpdateMission(String new_mission){
        toc.ClearScreen();
        toc.XPosCurrPrint = TextOnCanvas.X_MIN_POS;
        toc.YPosCurrLine = TextOnCanvas.Y_MIN_POS;
        toc.setFillStyle("White");
        toc.PrintStringToScreenMultipleLines(new_mission);
    }
}