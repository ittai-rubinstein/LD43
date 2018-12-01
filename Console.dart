import 'dart:html';
// import 'dart:collection'; 

const DEBUG_CONSOLE = true;

class Console{
    // The command currently being parsed
    String current_command = "";
    // Our current path (for the print beside the line currently being parsed)
    String current_address = "~";
    // A list of the past commands, outputs and paths (currently only for printing history; in the future perhaps for completions)
    List commands_and_outputs = [];
    // The canvas on which we will be drawing the code
    CanvasElement canvas;  
    // The 2d drawing context
    CanvasRenderingContext2D ctx;
    // The user name and machine namefor the username@machine:
    String username = "user";
    String machine_name = "linux";
    
    // The highest point visible in the screen:
    static const num Y_MIN_POS = 15;
    // The leftmost point visible in the screen:
    static const int X_MIN_POS = 7;
    // The converse values depend upon the window size (which may be dynamic?)
    int GetMaxYPos(){
        return canvas.height - Y_MIN_POS;
    }
    int GetMaxXPos(){
        return canvas.width - X_MIN_POS;
    }
    // How far down we need to jump between lines:
    static const int LINE_HEIGHT = Y_MIN_POS;

    // The Y axis position of the current line being edited. All other prints will be relative to this value.
    num YPosCurrLine = Y_MIN_POS;
    num XPosCurrPrint = X_MIN_POS;

    // The width of a character. Measured in a horani manner.
    // TODO: improve the accuracy.
    static const CHARACTER_WIDTH = 8.196;
    

    Console(){
        // Ask the html for the canvas of the console, on which we will print everything:
        canvas = querySelector('#Console');
        // Generate a 2d drawing context:
        ctx = canvas.getContext('2d');
        // Set the keyboard handler to listen to keystrokes:
        window.onKeyDown.listen(this.KeyboardHandler);
        // Prevent annoying stretching, by making everything absolute size:
        canvas.width = canvas.clientWidth;
        canvas.height = canvas.clientHeight;

        // Junk. To be removed...

        PrintCommandLine("~", "echo hello world");
        // print(canvas.width);
        // print(canvas.height);
        // print(canvas.clientWidth);
        // print(canvas.clientHeight);
        // ctx.font = "18px Times New Roman";
        // ctx.fillStyle = "red";
        // ctx.fillText(" " + "a" * 50,7,15);
        // ctx.fillText(" " + "a" * 50,7,30);
    }

    // Prints a string that is not expected to require a new line
    // Updates the 
    void PrintStringToScreenSimple(String message){
        ctx.fillText(message, XPosCurrPrint, YPosCurrLine);
        print(XPosCurrPrint);
        print(ctx.measureText(message).width);
        XPosCurrPrint += ctx.measureText(message).width;
    }

    /**
     * Prints a String to the console, separating it into several lines as necessary.
     */
    void PrintStringToScreenMultipleLines(String message){
        // Set the font all the time
        ctx.font = "18px Times New Roman";
        // While we still have data to print:
        while (message.isNotEmpty) {
            // If all the data fits in one line, we print it, and don't go to a new line
            if ((XPosCurrPrint + (CHARACTER_WIDTH * message.length)) < GetMaxXPos()) {
                PrintStringToScreenSimple(message);
                break;
            // Otherwise, we print what we can to this line, then jump to the next line, and remove what needs to be removed
            // from the data to be printed.
            } else {
                message.substring(0,((GetMaxXPos() - XPosCurrPrint) / CHARACTER_WIDTH).floor());
                XPosCurrPrint = X_MIN_POS;
                YPosCurrLine += LINE_HEIGHT;
                message = message.substring(((GetMaxXPos() - XPosCurrPrint) / CHARACTER_WIDTH).floor());
            }
        }
    }

    // Prints the pretty command line to the console
    void PrintCommandLine(String path, String command){
        // For the user @ machine part, we want a yellow font
        ctx.fillStyle = "Yellow";
        PrintStringToScreenMultipleLines("$username@$machine_name");
        // For the ":" we want a white font
        ctx.fillStyle = "White";
        PrintStringToScreenMultipleLines(":");
        // For the path we want a bright blue font
        ctx.fillStyle = "blue";
        PrintStringToScreenMultipleLines("$path");
        // For the "$ " and the command itself, we want a white font again
        ctx.fillStyle = "white";
        PrintStringToScreenMultipleLines("\$ $command");
    }

    // Computes the number of characters that fit in one line of the console
    int NumCharactersPerLine(){
        return (canvas.width / CHARACTER_WIDTH).floor();
    }

    // Computes the number of lines necessary for writing a string
    int NumLinesForString(String message){
        return (message.length.toDouble() / NumCharactersPerLine()).ceil();
    }

    // Returns the user@machine string for pretty prints
    String GetUserMachine(){
        return "$username@$machine_name";
    }

    /*
    Computes the number of lines required for printing the whole terminal state.
    */
    int GetTotalNumLines(){
        int num_lines = 0;
        for (var past_command in commands_and_outputs) {
            // Unpack the past_command
            String path = past_command[0];
            String command = past_command[1];
            String result = past_command[2];
            // Produce the print for the command itself, and count its lines:
            String CommandPrint = GetUserMachine() + ":" + path + "\$ " + command;
            num_lines += NumLinesForString(CommandPrint);
            // Count the lines for the result:
            num_lines += NumLinesForString(result);
        }
        // Add the command currently being written:
        String CommandPrint = GetUserMachine() + ":" + current_address + "\$ " + current_command;
        num_lines += NumLinesForString(CommandPrint);
        return num_lines;
    }

    // Handles the Keyboard interrupts.
    // If the key event is a character, adds it to the current command.
    // If the command is an enter, runs the command.
    // Otherwise does nothing.
    void KeyboardHandler(KeyboardEvent event){
        if (DEBUG_CONSOLE) {
            print('Got key ${event.key}');
        }
        // If the length of event.key is 1, then the event is a character to be added:
        if (event.key.length == 1) {
            AddCharToConsole(event.key);
        } else {
            // Deal with all other cases:
            switch(event.key){
                case 'Enter':
                FinishReadingCommand();
                break;
                default:
                break;
            }
        }
    }

    // Called when we are done reading a command from the user (i.e. when the enter key has been pressed).
    void FinishReadingCommand(){
        // Send the command to the Linux system (currently just prints to log)
        String result = SendCommand(current_command);
        // Add the command, the answer, and the current address to the list of past commands (for console content)
        commands_and_outputs.add([current_address, current_command, result]);
        // clears the command
        current_command = "";
        // TODO: change this to get the current address from the Linux system.
        current_address = "";
    }

    // When parsing user keyboard, this adds the actual character to the command line.
    void AddCharToConsole(String new_character){
        if (DEBUG_CONSOLE) {
            print('Got the character ${new_character}');
        }
        current_command += new_character;
    }

    String SendCommand(String command){
        if (DEBUG_CONSOLE) {
            print('Send command $command');
        }
        return "Answer($command)";
    }
    // A method that handles the printing of all the console to the string
    void PrintEntireConsoleToScreen(){

    }
}