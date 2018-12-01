import "Command.dart";
import "Environment.dart";
import 'dart:io';
import "Level.dart";

void main() {
//    Environment env = Environment();
    SwapLevel level = SwapLevel();
    Environment env = level.setup();
    while(true) {
//        stdout.writeln('Enter a command:');
        stdout.write(env.pwd() + " # ");
        String input = stdin.readLineSync();
        try {
            Command cmd = parse_command(input);
//            stdout.writeln("Command is $cmd");
            stdout.write(cmd.apply("", env));
            if(level.is_solved(env)) {
                stdout.writeln("Done!");
                return;
            }
        }
        on ParseException catch (e) {
            stdout.writeln("Error: " + e.cause);
        }
    }
}