import 'TextOnCanvas.dart';


class MissionControl{
    static TextOnCanvas toc = TextOnCanvas("MissionControl", "Mission Control");

    static void UpdateMission(String new_mission){
        toc.ClearScreen();
        toc.setFillStyle("White");
        toc.PrintStringToScreenMultipleLines(new_mission);
    }
}