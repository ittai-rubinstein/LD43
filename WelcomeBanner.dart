import 'TextOnCanvas.dart';
import 'GameLogic.dart';
import 'dart:html';

class WelcomeBanner{
    static const String GameName = "Out of Space";
    static TextOnCanvas toc = new TextOnCanvas("Console", "$GameName");
    static const String WelcomeMessage = "Welcome to $GameName!!!\n" +
        "You are stranded in space, and your shuttle computer is out of disk space...\n" +
        "I suppose this is what some people would call ironic.\n" +
        "In order to save your ship from total failure, help the engineers from Mission Control fix the filesystem.\n"
        "At your disposal are:\n" + 
        "\t\t\t\t1. A minimalistic linux terminal\n\t\t\t\t2. A text based gui of the filesystem\n\t\t\t\t3. Guidance from Mission Control\n" +
        "If your not sure what to do, \"man\" would be good place to start...\n" +
        "\n\n\nPress any key to begin.";
    
    static bool open = false;

    static void CloseBanner(var event){
        if(open){
            open = false;
            GameLogic.reset();
        }
    }

    static void PrintBanner(){
        toc.ClearScreen();
        open = true;
        toc.setFillStyle("White");
        toc.PrintStringToScreenMultipleLines(WelcomeMessage);
        window.onKeyDown.listen(CloseBanner);
    }
}