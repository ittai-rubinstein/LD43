import 'dart:html';
import 'dart:math';
import 'GameLogic.dart';
import 'TextOnCanvas.dart';
// import 'dart:collection'; 

const DEBUG_CONSOLE = false;

class Console{
    // The command currently being parsed
    String current_command = "";
    // Our current path (for the print beside the line currently being parsed)
    String current_address = "~";
    // A list of the past commands, outputs and paths (currently only for printing history; in the future perhaps for completions)
    List commands_and_outputs = [];
    // The user name and machine namefor the username@machine:
    String username = "user";
    String machine_name = "linux";

    // The TextOnCanvas Drawing tool that will actually print things to the screen
    TextOnCanvas toc = new TextOnCanvas("Console");

    Console(){
        
        // Set the keyboard handler to listen to keystrokes:
        window.onKeyDown.listen(this.KeyboardHandler);
        PrintAllTerminal();
        // print("Character width should be ${ctx.measureText("a").width}");

        
    }

    

    /**
     * Prints the result of a command (different color pallet from commands?)
     */
    void PrintResult(String result){
        toc.setFillStyle("Cyan");
        toc.PrintStringToScreenMultipleLines(result);
    }

    /**
     * Prints all the terminals content into the console.
     */
    void PrintAllTerminal(){
        // Clear the screen
        toc.ClearScreen();
        print('Printing the terminal.');
        // Prepare to print:
        toc.SetPrintingHead(GetTotalNumLines());
        print(toc.YPosCurrLine);
        // Print the past values:
        for (var past_command in commands_and_outputs) {
            // Unpack the past_command
            String path = past_command[0];
            String command = past_command[1];
            String result = past_command[2];
            // Produce the print for the command itself, and count its lines:
            PrintCommandLine(path, command);
            // Go to a new line to print the result:
            toc.GoToNewLine();
            // If result is empty, skip printing it
            if (result != "") {
                // Print the result
                PrintResult(result);
                toc.GoToNewLine();
            }
        }
        // Add the command currently being written:
        PrintCommandLine(current_address, current_command);
    }

    // Prints the pretty command line to the console
    void PrintCommandLine(String path, String command){
        // For the user @ machine part, we want a yellow font
        print('Printing the username $username@$machine_name');
        toc.setFillStyle("Yellow");
        print(toc.ctx.fillStyle);
        toc.PrintStringToScreenMultipleLines("$username@$machine_name");
        // For the ":" we want a white font
        toc.setFillStyle("White");
        toc.PrintStringToScreenMultipleLines(":");
        // For the path we want a bright blue font
        toc.setFillStyle("blue");
        toc.PrintStringToScreenMultipleLines("$path");
        // For the "$ " and the command itself, we want a white font again
        toc.setFillStyle("White");
        toc.PrintStringToScreenMultipleLines("\$ $command");
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
            num_lines += toc.NumLinesForString(CommandPrint);
            // Count the lines for the result:
            num_lines += toc.NumLinesForString(result);
        }
        // Add the command currently being written:
        String CommandPrint = GetUserMachine() + ":" + current_address + "\$ " + current_command;
        num_lines += toc.NumLinesForString(CommandPrint);
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
                toc.NewestLineYPos = max(TextOnCanvas.Y_MIN_POS, toc.NewestLineYPos - TextOnCanvas.LINE_HEIGHT / 4);
                PrintAllTerminal();
                break;
                case 'ArrowUp':
                toc.NewestLineYPos = toc.NewestLineYPos + (TextOnCanvas.LINE_HEIGHT / 4);
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
        num NumLinesCurrPrint = toc.NumLinesForString('$username@$machine_name:$current_address\$ $current_command') +
                toc.NumLinesForString(result);
        // Add the command, the answer, and the current address to the list of past commands (for console content)
        commands_and_outputs.add([current_address, current_command, result]);
        // clears the command
        current_command = "";
        // TODO: change this to get the current address from the Linux system.
        current_address = current_address;
        // Lower us by however much the new prints take
        toc.NewestLineYPos += TextOnCanvas.LINE_HEIGHT * NumLinesCurrPrint;
        // Make sure we actually show the newest line:
        toc.NewestLineYPos = min(toc.GetMaxYPos(), max(TextOnCanvas.Y_MIN_POS, toc.NewestLineYPos));
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
        
        if ((toc.GetMaxXPos() > toc.XPosCurrPrint + TextOnCanvas.CHARACTER_WIDTH) && 
                    (toc.NewestLineYPos == min(toc.GetMaxYPos(), max(TextOnCanvas.Y_MIN_POS, toc.NewestLineYPos)))) {
            toc.PrintStringToScreenSimple(new_char);
        } else {
            toc.NewestLineYPos = min(toc.GetMaxYPos(), max(TextOnCanvas.Y_MIN_POS, toc.NewestLineYPos));
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