import 'dart:html';
import 'dart:collection'; 

class KeyboardState{
    // Maintain a mapping from a key to whether of not it is pressed
    HashMap<String, bool> keys_pressed;

    // Maintain the state of the caps lock
    bool caps_lock;

    // Useful key codes
    static const String CAPS_LOCK_KEY = "CapsLock";
    static const String SHIFT_KEY = "Shift";

    KeyboardState(){
        window.onKeyDown.listen((KeyboardEvent event) {
            // Update the keys_pressed map
            keys_pressed[event.key] = true;

            // Update the caps_lock after the pressing of the caps lock key
            if (event.key == CAPS_LOCK_KEY) {
                caps_lock = !caps_lock;
            }
        });

        window.onKeyUp.listen((KeyboardEvent event) {
            // Update the keys_pressed to the key up.
            keys_pressed[event.key] = false;
        });
        caps_lock = false;
    }
}

class Console{
    // The command currently being parsed
    String current_command;
    String current_address;
    List commands_and_outputs;
    KeyboardState keyboard_state;
    

    Console(){

    }

    void KeyboardHandler(KeyboardEvent event){
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
        current_command += new_character;
    }

    String SendCommand(String command){
        print('Send command $command');
        return "Answer($command)";
    }
}