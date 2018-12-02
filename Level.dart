import 'Environment.dart';
import 'Command.dart';

abstract class Level {
    List<List<String>> solutions;
    Environment setup();
    bool is_solved(Environment env);
}

class SwapLevel implements Level{
    static const String SUN = "\u{1f31e}";
    static const String MOON = "\u{1f31a}";

    List<List<String>> solutions = [
        ["cp sun sun2",
        "cp moon sun",
        "cp sun2 moon"],
        ["cat sun | tee sun2",
        "cat moon | tee sun",
        "cat sun2 | tee moon"]
    ];

    // Swap two files
    Environment setup() {
        var env = Environment();
        env.create_new_file("/sun");
        env.create_new_file("/moon");
        env.write_file("/sun", MOON);
        env.write_file("/moon", SUN);
        return env;
    }

    bool is_solved(Environment env) {
        try {
            if (env.read_file("/sun").trim() != SUN)
                return false;
            if (env.read_file("/moon").trim() != MOON)
                return false;
        } catch (e) {
            return false;
        }
        return true;
    }
}

class FileContentLevel implements Level{
    List<List<String>> solutions = [
        ["echo world > hello"],
        ["echo world | tee hello"]];

    Environment setup() {
        return Environment();
    }

    bool is_solved(Environment env) {
        try {
            if (env.read_file("hello").trim().toLowerCase() == "world")
                return true;
        } catch (e) { 
            return false;
        }
        return false;
    }
}

List<Level> LEVELS = [SwapLevel(), FileContentLevel()];

void test_levels() {
    for (Level level in LEVELS) {
        for (var sol in level.solutions) {
            Environment env = level.setup();
            for (String cmd in sol) {
                Command command = parse_command(cmd);
                command.apply("", env);
            }
            if (!level.is_solved(env)) {
                print("Level $level is broken!");
                return;
            }
        }
    }
    print("All levels are OK!");
}