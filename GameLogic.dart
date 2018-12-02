import 'Environment.dart';
import 'Level.dart';
import 'Command.dart';
import 'Console.dart';
import 'FileView.dart';

class GameLogic {
    static Environment env;
    static List<String> removed_commands;
    static List<Level> levels_done;
    static Console con;

    static Level current_level;
    static void reset() {
        levels_done = [];
        removed_commands = [];
        choose_next_level();
        start_level();
        con = new Console();
    }

    static void start_level() {
        env = current_level.setup();
        FileView.OnNewCommand();
        if (con != null) {
            con.ClearHistory();
            con.PrintAllTerminal();
        }
    }

    static on_level_complete() {
        levels_done.add(current_level);
        print("Well done");
        con.ClearHistory();
    }

    static String on_input(String input){
        return run_command(input);
    }

    static void choose_next_level() {
        for (Level level in LEVELS) {
            if (levels_done.contains(level))
                continue;
            current_level = level;
        }
    }

    static String run_command(String cmd) {
        try {
            Command command = parse_command(cmd);
            String cmd_output = command.apply("", env);
            if (current_level.is_solved(env))
                on_level_complete();
            return cmd_output;
        } on ParseException catch (e) {
            return e.cause;
        }
    }
}