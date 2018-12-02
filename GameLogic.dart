import 'Environment.dart';
import 'Level.dart';
import 'Command.dart';
import 'Console.dart';
import 'FileView.dart';
import 'MissionControl.dart';
import 'WelcomeBanner.dart';

class GameLogic {
    static Environment env;
    static List<String> removed_commands = [];
    static List<Level> levels_done;
    static Console con;
    static List<String> choice_options;
    // The number of commands left for the current level
    static num commands_left = 0;

    static Level current_level;
    static void reset() {
        levels_done = [];
        removed_commands = [];
        choose_next_level();
        start_level();
        con = new Console();
    }

    static void open_start_banner(){
        WelcomeBanner.PrintBanner();
    }

    static void start_level() {
        env = current_level.setup();
        MissionControl.UpdateMission(current_level.description);

        
        // Initiailize to 5 commands per level.
        commands_left = 5;
        FileView.OnNewCommand();
        if (con != null) {
            con.ClearHistory();
            con.PrintAllTerminal();
        }
    }

    static void start_sacrifice() {
        choice_options = [];
        for (String cmd in ALL_COMMANDS) {
            if (removed_commands.contains(cmd))
                continue;
            choice_options.add(cmd);
            if (choice_options.length == 3)
                break;
        }
        print("diskd: Low disk space!\nChoose a command to sacrifice:");
        for (int i = 0;i < choice_options.length;i++) {
            print("\t${i+1}.${choice_options[i]}");
        }
    }

    static on_level_complete() async {
        levels_done.add(current_level);
        await Future.delayed(Duration(seconds: 2));
        con.ClearHistory();
        start_sacrifice();
    }

    static on_no_commands_left() async {
        // TODO: block input
        await Future.delayed(Duration(seconds: 2));
        // TODO: allow input
        start_level();
    }

    static String on_input(String input){
        if (choice_options != null) {
            try {
                int choice = int.tryParse(input.trim());
                if (choice > choice_options.length || choice <= 0)
                    return "Try again";
                String chosen = choice_options[choice - 1];
                removed_commands.add(chosen);
                choice_options = null;
                choose_next_level();
                start_level();
                return "Command ${chosen} removed.";
            } catch (e) {
                return "Try again";
            }
        }
        try {
            Command command = parse_command(input);
            String cmd_output = command.execute("", env);

            if (commands_left < 0 || (commands_left == 0 && !current_level.is_solved(env))) {
                on_no_commands_left();
                return "Time is up! Do it in 5 commands, or don't do it at all.";
            }

            if (current_level.is_solved(env)) {
                on_level_complete();
                cmd_output += "\n\n  SUCCESS!\n\n";
            }
            
            return cmd_output;
        } on ParseException catch (e) {
            return e.cause;
        }
    }

    static void choose_next_level() {
        for (Level level in LEVELS) {
            if (levels_done.contains(level))
                continue;
            current_level = level;
            break;
        }
    }
}