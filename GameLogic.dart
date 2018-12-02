import 'Environment.dart';
import 'Level.dart';
import 'Command.dart';
import 'Console.dart';
import 'FileView.dart';
import 'MissionControl.dart';
import 'WelcomeBanner.dart';
import 'TextOnCanvas.dart';
import 'dart:math';
import 'WinScreen.dart';

class GameLogic {
    static Environment env;
    static List<String> removed_commands = [];
    static int level_num;
    static Console con;
    static List<String> choice_options;
    // The number of commands left for the current level
    static num commands_left = 0;

    static Level current_level;
    static void reset() {
        level_num = 0;
        current_level = LEVELS[0];
        removed_commands = [];
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
        choose_next_level();
        choice_options = [];
        List<String> command_order = ALL_COMMANDS.sublist(0);
        command_order.shuffle();
        for (String cmd in command_order) {
            if (removed_commands.contains(cmd))
                continue;
            LevelStatus status = current_level.status_without(cmd);
            if (status == LevelStatus.IMPOSSIBLE || status == LevelStatus.SAME)
                continue;
            print("Good sacrifice: $cmd");
            choice_options.add(cmd);
            if (choice_options.length == 3)
                break;
        }

        if (choice_options.length < 3) {
            for (String cmd in command_order) {
                if (removed_commands.contains(cmd))
                    continue;
                LevelStatus status = current_level.status_without(cmd);
                if (status == LevelStatus.IMPOSSIBLE)
                    continue;
                if (choice_options.length == 3)
                    break;
                choice_options.add(cmd);
            }
        }

        String sacrifice_demand = "diskd: Low disk space!\nChoose a command to sacrifice:\n";
        print("diskd: Low disk space!\nChoose a command to sacrifice:");
        for (int i = 0;i < choice_options.length;i++) {
            print("\t${i+1}.${choice_options[i]}");
            sacrifice_demand += "\t${i+1}.${choice_options[i]}\n";
        }
        num NumLinesOld = con.GetTotalNumLines();
        con.commands_and_outputs.add([con.current_address, con.current_command, sacrifice_demand]);
        con.toc.NewestLineYPos = min(con.toc.GetMaxYPos(), con.toc.NewestLineYPos + ((con.GetTotalNumLines() - NumLinesOld) * TextOnCanvas.LINE_HEIGHT));
        con.PrintAllTerminal();
    }

    static on_level_complete() async {
        await Future.delayed(Duration(seconds: 1));
        start_sacrifice();
        
    }

    static on_no_commands_left() async {
        // TODO: block input
        await Future.delayed(Duration(seconds: 1));
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
                con.ClearHistory();
                start_level();
                return "Command ${chosen} removed. Thank you for your sacrifice...";
            } catch (e) {
                return "Try again";
            }
        }
        try {
            Command command = parse_command(input);
            String cmd_output = command.execute("", env);
            if (command is Man)
                commands_left++; // a lone 'man' isn't counted;

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
        int solved_level = level_num;
        level_num++;
        while (true) {
            if (level_num == LEVELS.length)
                level_num = 0;
            if (LEVELS[level_num].status_without('nonexistent-command') != LevelStatus.IMPOSSIBLE)
                break;
            if (level_num == solved_level){
                VictoryScreen.PrintBanner();
                con.toc = null;
            }
        }
        current_level = LEVELS[level_num];
    }
}