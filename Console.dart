import 'dart:html';
import 'dart:math';
import 'GameLogic.dart';
// import 'dart:collection'; 

const DEBUG_CONSOLE = false;

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
    static const num Y_MIN_POS = 20;
    // The leftmost point visible in the screen:
    static const int X_MIN_POS = 7;
    // The converse values depend upon the window size (which may be dynamic?)
    num GetMaxYPos(){
        return canvas.height - Y_MIN_POS;
    }
    num GetMaxXPos(){
        return canvas.width - X_MIN_POS;
    }
    // How far down we need to jump between lines:
    static const int LINE_HEIGHT = Y_MIN_POS;

    // The position of the current line being edited. These values will be updated as the prints goes on.
    num YPosCurrLine = Y_MIN_POS;
    num XPosCurrPrint = X_MIN_POS;

    // This is the height of the newest line in the code. Is currently set to the bottom of the screen.
    // TODO: make this "dynamic" (i.e. the scroll goes up and down, and this starts the top of screen).
    num NewestLineYPos;

    // The width of a character. Measured in a horani manner.
    // TODO: improve the accuracy.
    static const num CHARACTER_WIDTH = 10.8369140625;
    

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

        // Initialize the printing head to the botoom of the screen. Later, this should be changed.
        NewestLineYPos = Y_MIN_POS;

        PrintAllTerminal();
        // print("Character width should be ${ctx.measureText("a").width}");

        
    }

    /**
     * Ends the line currently being printed, and returns the carrage
     */
    void GoToNewLine(){
        XPosCurrPrint = X_MIN_POS;
        YPosCurrLine += LINE_HEIGHT;
    }

    /**
     * Prints the result of a command (different color pallet from commands?)
     */
    void PrintResult(String result){
        ctx.fillStyle = "Cyan";
        PrintStringToScreenMultipleLines(result);
    }

    /**
     * Prints all the terminals content into the console.
     */
    void PrintAllTerminal(){
        canvas.width = canvas.clientWidth;
        canvas.height = canvas.clientHeight;
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        // Compute the Y axis of the first line to be printed:
        num NumLines = GetTotalNumLines();
        num BaseYPos = NewestLineYPos - ((NumLines - 1) * LINE_HEIGHT);
        // Set the printing head to the start of the print:
        XPosCurrPrint = X_MIN_POS;
        YPosCurrLine = BaseYPos;
        // Print the past values:
        for (var past_command in commands_and_outputs) {
            // Unpack the past_command
            String path = past_command[0];
            String command = past_command[1];
            String result = past_command[2];
            // Produce the print for the command itself, and count its lines:
            PrintCommandLine(path, command);
            // Go to a new line to print the result:
            GoToNewLine();
            // Print the result
            PrintResult(result);
            GoToNewLine();
        }
        // Add the command currently being written:
        PrintCommandLine(current_address, current_command);
    }

    // Prints a string that is not expected to require a new line
    // Updates the XPosCurrPrint Accordingly
    void PrintStringToScreenSimple(String message){
        ctx.fillText(message, XPosCurrPrint, YPosCurrLine);
        // print(XPosCurrPrint);
        // print(ctx.measureText(message).width);
        XPosCurrPrint += ctx.measureText(message).width;
    }

    /**
     * Prints a String to the console, separating it into several lines as necessary.
     */
    void PrintStringToScreenMultipleLines(String message){
        // Set the font all the time
        ctx.font = "18px monospace";
        // While we still have data to print:
        while (message.isNotEmpty) {
            // Check how many charcters can be printed on the current line.
            // If it contains no \n chars, then it is determined by the width of the screen.
            // If it does contain a \n char, then it is determined by the first of the two.
            num max_chars_curr_line = min(((GetMaxXPos() - XPosCurrPrint) / CHARACTER_WIDTH).floor(), 
                                            ((message.indexOf("\n") <= 0)?(1000000):(message.indexOf("\n") + 1)));
            // If all the data fits in one line, we print it, and don't go to a new line
            if (message.length <= max_chars_curr_line) {
                if (DEBUG_CONSOLE) {
                    print('Printing $message to single line.');
                }
                PrintStringToScreenSimple(message);
                break;
            // Otherwise, we print what we can to this line, then jump to the next line, and remove what needs to be removed
            // from the data to be printed.
            } else {
                if (DEBUG_CONSOLE) {
                    print('Printing ${message.substring(0,max_chars_curr_line)} to single line.');
                }
                PrintStringToScreenSimple(message.substring(0,max_chars_curr_line));
                GoToNewLine();
                message = message.substring(max_chars_curr_line);
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
        ctx.fillStyle = "White";
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
                case 'ArrowDown':
                NewestLineYPos = max(Y_MIN_POS, NewestLineYPos - LINE_HEIGHT / 4);
                PrintAllTerminal();
                break;
                case 'ArrowUp':
                NewestLineYPos = NewestLineYPos + (LINE_HEIGHT / 4);
                PrintAllTerminal();
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
        // Compute the number of lines for the current command and result
        num NumLinesCurrPrint = NumLinesForString('$username@$machine_name:$current_address\$ $current_command') +
                NumLinesForString(result);
        // Add the command, the answer, and the current address to the list of past commands (for console content)
        commands_and_outputs.add([current_address, current_command, result]);
        // clears the command
        current_command = "";
        // TODO: change this to get the current address from the Linux system.
        current_address = current_address;
        // Lower us by however much the new prints take
        NewestLineYPos += LINE_HEIGHT * NumLinesCurrPrint;
        // Make sure we actually show the newest line:
        NewestLineYPos = min(GetMaxYPos(), max(Y_MIN_POS, NewestLineYPos));
        PrintAllTerminal();
    }

    // When parsing user keyboard, this adds the actual character to the command line.
    void AddCharToConsole(String new_character){
        if (DEBUG_CONSOLE) {
            print('Got the character ${new_character}');
        }
        current_command += new_character;
        PrintSingleCharToCommand(new_character);
    }

    /**
     * Adds a single character to the command currently being written on the console.
     */
    void PrintSingleCharToCommand(String new_char){
        // Make sure that character is actually on screen.
        
        if ((GetMaxXPos() > XPosCurrPrint + CHARACTER_WIDTH) && (NewestLineYPos == min(GetMaxYPos(), max(Y_MIN_POS, NewestLineYPos)))) {
            PrintStringToScreenSimple(new_char);
        } else {
            NewestLineYPos = min(GetMaxYPos(), max(Y_MIN_POS, NewestLineYPos));
            PrintAllTerminal();
        }
    }

    String SendCommand(String command) {
        String cmd_output = GameLogic.run_command(command);
        return cmd_output;
    }
    // A method that handles the printing of all the console to the string
    void PrintEntireConsoleToScreen(){

    }
}