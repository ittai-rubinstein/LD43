import "Command.dart";
import 'dart:io';

void main() {
    while(true) {
        stdout.writeln('Enter a command:');
        String input = stdin.readLineSync();
        try {
            Command cmd = parse_command(input);
            stdout.writeln(cmd);
        }
        on ParseException catch (e) {
            stdout.writeln("Error: " + e.cause);
        }
    }
}