import 'Environment.dart';
import 'Level.dart';
import 'Command.dart';
import 'Console.dart';

class GameLogic {
    static Environment env;
    static Console console;

    static SwapLevel level;
    static void reset() {
        level = SwapLevel();
        start_level();
    }

    static void start_level() {
        env = level.setup();
    }

    static on_level_complete() {
        print("Well done");
        console.ClearHistory();
    }

    static String run_command(String cmd) {
        try {
            Command command = parse_command(cmd);
            String cmd_output = command.apply("", env);
            if (level.is_solved(env))
                on_level_complete();
            return cmd_output;
        } on ParseException catch (e) {
            return e.cause;
        }
    }
}