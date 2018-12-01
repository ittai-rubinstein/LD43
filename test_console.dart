import "Command.dart";
import "Environment.dart";
import 'dart:io';

void main() {
    Environment env = Environment();
    while(true) {
//        stdout.writeln('Enter a command:');
        stdout.write(env.pwd() + " # ");
        String input = stdin.readLineSync();
        try {
            Command cmd = parse_command(input);
//            stdout.writeln("Command is $cmd");
            stdout.write(cmd.apply("", env));
        }
        on ParseException catch (e) {
            stdout.writeln("Error: " + e.cause);
        }
    }
}