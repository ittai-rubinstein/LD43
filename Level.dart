import 'Environment.dart';
import 'Command.dart';
import 'GameLogic.dart';

enum LevelStatus {
    SAME, HARDER, IMPOSSIBLE
}

bool contains_any(String line, List<String> things) {
    for (String thing in things)
        if (line.contains(thing))
            return true;
    return false;
}

abstract class Level {
    List<List<String>> solutions;
    String description;
    Environment setup();
    bool is_solved(Environment env);
    LevelStatus status_without(String cmd) {
        bool solvable = false;
        bool harder = false;
        for (List<String> sol in solutions) {
            bool applicable = true;
            for (String line in sol) {
                if (line.contains(cmd)) {
                    applicable = false;
                    harder = true;
                    // don't break - might not be harder after all
                }
                if (contains_any(line, GameLogic.removed_commands)) {
                    applicable = false;
                    harder = false;
                    break;
                }
            }
            if (applicable)
                solvable = true;
        }
        if (!solvable)
            return LevelStatus.IMPOSSIBLE;
        if (harder)
            return LevelStatus.HARDER;
        return LevelStatus.SAME;
    }
}

class SwapLevel extends Level{
    String description = "Swap the contents of the two files: Put the contents of 'moon'"
                         " in a file named 'sun' and vice versa.";

    static const String SUN = "\u{1f31e}";
    static const String MOON = "\u{1f31a}";

    List<List<String>> solutions = [
        ["cp sun sun2",
        "cp moon sun",
        "cp sun2 moon"],
        ["cat sun | tee sun2",
        "cat moon | tee sun",
        "cat sun2 | tee moon"],
        ["cat sun > bla",
        "cat moon > sun",
        "cat bla > moon"],
        ["mv sun bla",
        "mv moon sun",
        "mv bla moon"]
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

class FileContentLevel extends Level{
    String description = "Create a file named 'hello' with the word 'world' in it.";

    List<List<String>> solutions = [
        ["echo world > hello"],
        ["echo world | tee hello"],
        ["mkdir boo", "touch boo/world", "ls boo > hello"],
        ["mkdir boo", "find | tee boo/world", "ls boo | tee hello"]];

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

class CopyEmojiFileLevel extends Level {
    static const String filename = 'power\u{26a1}';
    String description = "There is a file named $filename in /."
                         " Create a file with the same name in /turn_on. Its contents don't matter\n";
    List<List<String>> solutions = [[
        "cd turn_on", "ls .. | xargs touch"]
        ];
    
    Environment setup() {
        Environment env = Environment();
        env.create_new_dir("turn_on");
        env.create_new_file("/$filename", "Something");
        return env;
    }

    bool is_solved(Environment env) {
        try {
            if (env.exists("/turn_on/$filename") && 
                env.get_type("/turn_on/$filename") == NodeType.FILE)
                return true;
        } on FileException {
            return false;
        }
        return false;
    }
}

class RemoveAllButLevel extends Level {
    List<String> dirnames = ["\u{2660}","\u{2663}","\u{2665}","\u{2666}"];
    String description = "Remove the directories d\u{2660} - d\u{2666}, while maitaining"
                        " a direcory called 'innocent'. We don't care about"
                        " the contents of the directories";

    List<List<String>> solutions = [
        ["cd innocent",
        "rm .."],
        ["rm .",
        "mkdir innocent"],
        ["touch innocent/guard",
        "find / | xargs rmdir"]
    ];

    Environment setup() {
        Environment env = Environment();
        for (int i = 0;i < 4;i++)
            env.create_new_dir("/d"+dirnames[i]);
        env.create_new_dir("innocent");
        return env;
    }

    bool is_solved(Environment env) {
        bool is_link;
        for (int i = 0;i < 4;i++) {
            try {
                is_link = env.is_link("/d"+dirnames[i]);
            } on FileException {
                continue;  // nonexistent
            }
            if (is_link)
                continue;
            if (env.get_type("/d"+dirnames[i]) == NodeType.DIRECTORY)
                return false;  // should have been removed
        }
        try {
            is_link = env.is_link("/innocent");
        } on FileException {
            return false;  // nonexistent
        }
        if (is_link || env.get_type("/innocent") != NodeType.DIRECTORY)
            return false;
        return true;
    }
}

class MoveDirectoryLevel extends Level {
    int BASE_EMOJI = 0x23e9;
    String description = "Create a directory named 'good' with the files"
                         " file\u{23e9} - file\u{23ec} from /bad\n"
                         "Note: the files are empty.";

    List<List<String>> solutions = [
        ["mv bad good"],
        ["cp bad good"],
        ["mkdir good",
        "cd bad",
        "find . > ../boo",
        "cd ../good",
        "cat ../boo | xargs touch"],
        ["mkdir good",
        "cd bad",
        "find . | tee ../boo",
        "cd ../good",
        "cat ../boo | xargs touch"]
    ];

    Environment setup() {
        Environment env = Environment();
        env.create_new_dir("/bad");
        for (int i = 0;i < 4;i++) {
            env.create_new_file("/bad/file" + String.fromCharCode(BASE_EMOJI+i));
        }
        return env;
    }

    bool is_solved(Environment env) {
        try {
            for (int i = 0;i < 4;i++) {
                if (!env.exists("/good/file" + String.fromCharCode(BASE_EMOJI+i)))
                    return false;
            }
        } on FileException {
            return false;
        }
        return true;
    }
}

List<Level> LEVELS = [FileContentLevel(), SwapLevel(), CopyEmojiFileLevel(), MoveDirectoryLevel(), RemoveAllButLevel()];

void test_levels() {
    GameLogic.commands_left = 1000000;
    for (Level level in LEVELS) {
        for (var sol in level.solutions) {
            Environment env = level.setup();
            for (String cmd in sol) {
                Command command = parse_command(cmd);
                command.execute("", env);
            }
            if (!level.is_solved(env)) {
                print("Level $level is broken!");
                return;
            }
        }
    }
    print("All levels are OK!");
}