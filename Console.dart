import 'dart:html';
// import 'dart:collection'; 

const DEBUG_CONSOLE = true;

class Console{
    // The command currently being parsed
    String current_command = "";
    String current_address = "~";
    List commands_and_outputs = [];
    

    Console(){
        window.onKeyDown.listen(this.KeyboardHandler);
    }

    void KeyboardHandler(KeyboardEvent event){
        if (DEBUG_CONSOLE) {
            print('Got key ${event.key}');
        }
        if (event.key.length == 1) {
            AddCharToConsole(event.key);
        } else {
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
        // print((current_command));
        // print((new_character));
        current_command += new_character;
    }

    String SendCommand(String command){
        if (DEBUG_CONSOLE) {
            print('Send command $command');
        }
        return "Answer($command)";
    }
}