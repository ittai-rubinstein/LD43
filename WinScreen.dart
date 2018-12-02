import 'TextOnCanvas.dart';
import 'GameLogic.dart';
// import 'dart:html';
import 'MissionControl.dart';

class VictoryScreen{
    static const String Victory = "Success!!!";
    static TextOnCanvas toc = new TextOnCanvas("Console", "$Victory");
    static const String VictoryMessage = "Congratulations!\n" + 
    "The filesystem was successfully saved.\nNow you get to eat some cake while waiting for rescue...";
    
    static bool open = false;

    static void CloseVicScreen(var event){
        if(open){
            open = false;
            GameLogic.reset();
        }
    }

    static void PrintBanner(){
        toc.ClearScreen();
        open = true;
        toc.setFillStyle("White");
        toc.PrintStringToScreenMultipleLines(VictoryMessage);
        MissionControl.UpdateMission("You don't really have any cake on your shuttle...");
        // window.onKeyDown.listen(CloseVicScreen);
        
    }
}