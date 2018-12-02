import 'Environment.dart';
import 'Level.dart';
import 'Command.dart';

class GameLogic {
    static Environment env;

    static SwapLevel level;
    static void reset() {
        level = SwapLevel();
        start_level();
    }

    static void start_level() {
        env = level.setup();
    }

    static String run_command(String cmd) {
        try {
            Command command = parse_command(cmd);
            return command.apply("", env);
        } on ParseException catch (e) {
            return e.cause;
        }
    }
}