import 'Environment.dart';
import 'Level.dart';
import 'Command.dart';
import 'Console.dart';
import 'FileView.dart';

class GameLogic {
    static Environment env;
    static List<String> removed_commands;
    static Console con;

    static SwapLevel level;
    static void reset() {
        level = SwapLevel();
        removed_commands = [];
        start_level();
        con = new Console();
    }

    static void start_level() {
        env = level.setup();
        FileView.OnNewCommand();
        if (con != null) {
            con.ClearHistory();
            con.PrintAllTerminal();
        }
    }

    static on_level_complete() {
        print("Well done");
        con.ClearHistory();
    }

    static String on_input(String input){
        return run_command(input);
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