import 'TextOnCanvas.dart';
import 'GameLogic.dart';
import 'Environment.dart';

class FileView {
    // The text drawer
    static TextOnCanvas toc = new TextOnCanvas("FileView");

    static const DIR_COLOR = "Blue";
    static const FILE_COLOR = "Green";
    static const LINK_COLOR = "Grey";
    static const ARROW_COLOR = "Cyan";

    // When printing deeper levels of the file system, indent them using the spacer:
    static const String LEVEL_SPACER = "  ";

    /**
     * Recursively draws the filesystem stemming from a given directory.
     * On files, prints the name - "File"
     * On Directories open recursively.
     * TODO: on symlinks print the link with an arrow
     * TODO: add colors
     */
    static DrawFileViewFromDir([BaseDir="/", Spacers]){
        print('Printing FileView from the Dir $BaseDir');
        // Get a list of all the children of the current directory
        List<String> NodeList = new List.from(GameLogic.env.get_children(BaseDir));
        NodeList.sort();
        // Which of those children are Directories?
        List<String> Dirs = new List.from(NodeList);
        Dirs.retainWhere((String node){
            return (!GameLogic.env.is_link("$BaseDir/$node")) && GameLogic.env.get_type("$BaseDir/$node") == NodeType.DIRECTORY;
        });
        // Which of those children are Files?
        List<String> Files = new List.from(NodeList);
        Files.retainWhere((String node){
            return (!GameLogic.env.is_link("$BaseDir/$node")) && GameLogic.env.get_type("$BaseDir/$node") == NodeType.FILE;
        });
        // Which of those children are Links
        List<String> Link = new List.from(NodeList);
        Link.retainWhere((String node){
            return GameLogic.env.is_link("$BaseDir/$node");
        });

        // Print the directory children
        for (var dir in Dirs) {
            // print the spacers and the |- s
            toc.setFillStyle("White");
            toc.PrintStringToScreenMultipleLines("$Spacers|-");
            // print the dirname
            toc.setFillStyle(DIR_COLOR);
            toc.PrintStringToScreenMultipleLines("$dir");
            // If this directory is the current directory, print a * to mark the occasion:
            if ("$BaseDir/$dir/".replaceAll("//", "/") == GameLogic.env.pwd()) {
                toc.setFillStyle("White");
                toc.PrintStringToScreenMultipleLines((" " * 6) + "*");
            }
            // print a new line
            toc.GoToNewLine();
            // print its children
            DrawFileViewFromDir("$BaseDir/$dir".replaceAll("//", "/"), "$Spacers$LEVEL_SPACER");
        }

        // Print the link children
        // Print the file children
    }

    // /**
    //  * Moves the screen up or down, according to the bit given
    //  */
    // static void OnScroll(){

    // }

    /**
     * On a new command, HATZMED the top of the fileview to the top of the screen
     */
    static void OnNewCommand(){
        toc.NewestLineYPos = TextOnCanvas.Y_MIN_POS;
        DrawFileView();
    }

    static void DrawFileView(){
        // Set the head to the necessary point for start of printing
        toc.XPosCurrPrint = TextOnCanvas.X_MIN_POS;
        toc.YPosCurrLine = toc.NewestLineYPos;
        // Clear the screen of past prints
        toc.ClearScreen();

        // Print the |- and the / of the start of the fileview
        toc.setFillStyle("White");
        toc.PrintStringToScreenMultipleLines("|-");
        toc.setFillStyle(DIR_COLOR);
        toc.PrintStringToScreenMultipleLines("/");
        // If we are in the / dir, we want to signify this with an asterisk
        if ("/" == GameLogic.env.pwd()) {
            toc.setFillStyle("White");
            toc.PrintStringToScreenMultipleLines((" " * 6) + "*");
        }
        toc.GoToNewLine();
        DrawFileViewFromDir("/", LEVEL_SPACER);
    }


    // /**
    //  * Computes the number of lines required for printing the whole file-view state.
    //  */
    // int GetTotalNumLines(){
    //     int num_lines = 0;
    //     for (var past_command in commands_and_outputs) {
    //         // Unpack the past_command
    //         String path = past_command[0];
    //         String command = past_command[1];
    //         String result = past_command[2];
    //         // Produce the print for the command itself, and count its lines:
    //         String CommandPrint = GetUserMachine() + ":" + path + "\$ " + command;
    //         num_lines += toc.NumLinesForString(CommandPrint);
    //         // Count the lines for the result:
    //         num_lines += toc.NumLinesForString(result);
    //     }
    //     // Add the command currently being written:
    //     String CommandPrint = GetUserMachine() + ":" + current_address + "\$ " + current_command;
    //     num_lines += toc.NumLinesForString(CommandPrint);
    //     return num_lines;
    // }
}