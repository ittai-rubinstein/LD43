import "Environment.dart";
import 'GameLogic.dart';


class ManPage {
    String cmd;
    String synopsis;
    List<String> usages;
    List<String> description;

    ManPage(this.cmd, this.synopsis, this.usages, this.description);
}

List<String> get_absolute_children(String path, Environment env) {
    return env.get_children(path).map((child) => env.absolute_path(path + "/" + child)).toList();
}

List<String> get_relative_children(String path, Environment env) {
    return env.get_children(path).map((child) => path + "/" + child).toList();
}

class LinuxException implements Exception {
    String cause;
    LinuxException(this.cause);
}

abstract class Command {
    String execute(String stdin, Environment env) {
        if (GameLogic.commands_left == 0)
            return "";
        GameLogic.commands_left--;
        return apply(stdin, env);
    }
    String apply(String stdin, Environment env) {
        throw Exception("internal error");
    }
}

abstract class BaseCommand extends Command {
    List<String> arguments;
    String cmd_name;
    BaseCommand(this.arguments, this.cmd_name);

    String toString() {
        return "$cmd_name(" + arguments.join(", ") + ")";
    }

    ManPage getHelp();
}

// Pipe command A into command B
class CompoundCommand extends Command {
    Command a, b;

    CompoundCommand(this.a, this.b);
    String execute(String stdin, Environment env) {
        String middle_string = a.execute(stdin, env);
        return b.execute(middle_string, env);
    }

    String toString() {
        return "(" + a.toString() + " | " + b.toString() + ")";
    }
}

class FileStdoutCommand extends Command {
    Command command;
    String stdout_filename;
    FileStdoutCommand(this.command, this.stdout_filename);
    String execute(String stdin, Environment env) {
        String target;
        try {
            target = env.absolute_path(stdout_filename);
        } on FileException catch (e) {
            return "$stdout_filename: No such file or directory";
        }
        if (!env.exists(target))
            env.create_new_file(target);
        String output = command.execute(stdin, env);
        if (env.exists(target))
            env.write_file(target, output);
        return "";
    }
}

class Echo extends BaseCommand {
    Echo(List<String> arguments) : super(arguments, 'echo');

    String apply(String stdin, Environment env) {
        return arguments.join(" ") + "\n";
    }

    ManPage getHelp() => ManPage("echo", "displays a line of text", ["echo [STRING]..."], ["Echo the STRING(s) to standard output."]);
}

class Cat extends BaseCommand {
    Cat(List<String> arguments) : super(arguments, 'cat');

    String apply(String stdin, Environment env) {
        List<String> datas = [];
        if(arguments.length == 0) {
            return "cat: no arguments given\n";
        }
        for(String filename in arguments) {
            if(!env.exists(filename)) {
                datas.add("cat: can't open '$filename': No such file or directory");
                continue;
            }
            if(env.get_type(filename) != NodeType.FILE) {
                datas.add("cat: read error: Is not a file");
                continue;
            }
            datas.add(env.read_file(filename));
        }
        return datas.join("\n") + "\n";
    }

    ManPage getHelp() => ManPage("cat", "concatenate files and print on the standard output", ["cat [FILE]..."], ["Concatenate FILE(s) to standard output."]);
}

class Ls extends BaseCommand {
    Ls(List<String> arguments) : super(arguments, 'ls');

    String apply(String stdin, Environment env) {
        List<String> datas = [];
        if(arguments.length == 0) {
            arguments.add('.');
        }
        for(String filename in arguments) {
            if(!env.exists(filename)) {
                datas.add("ls: $filename: No such file or directory");
                continue;
            }
            if(env.get_type(filename) == NodeType.FILE) {
                datas.add(filename);
            }
            else {
                datas.add(env.get_children(filename).join(" "));
            }
        }
        String ret = datas.join("\n");
        if(ret.length == 0)
            return "";
        return ret + "\n";
    }

    ManPage getHelp() => ManPage("ls", "list directory contents", ["ls [FILE]..."], ["List information about the FILEs (the current directory by", "default)."]);
}

class Touch extends BaseCommand {
    Touch(List<String> arguments) : super(arguments, 'touch');

    String apply(String stdin, Environment env) {
        List<String> datas = [];
        for(String path in arguments) {
            if(env.exists(path)) {
                continue;
            }
            try {
                env.create_new_file(path);
            } on FileException catch(e) {
                datas.add("touch: $path: No such file or directory");
            }
        }
        String ret = datas.join("\n");
        if(ret.length == 0)
            return "";
        return ret + "\n";
    }

    ManPage getHelp() => ManPage("touch", "change file timestamps", ["touch FILE..."], ["Update the access and modification times of each FILE to the", "current time.", "", "A FILE argument that does not exist is created empty."]);
}

class Mkdir extends BaseCommand {
    Mkdir(List<String> arguments) : super(arguments, 'mkdir');

    String apply(String stdin, Environment env) {
        List<String> datas = [];
        if(arguments.length == 0) {
            return "mkdir: no arguments given";
        }
        for(String path in arguments) {
            if(env.exists(path)) {
                datas.add("mkdir: can't create directory '$path': File exists");
                continue;
            }
            try {
                env.create_new_dir(path);
            } on FileException catch(e) {
                datas.add("mkdir: $path: No such file or directory");
            }
        }
        String ret = datas.join("\n");
        if(ret.length == 0)
            return "";
        return ret + "\n";
    }

    ManPage getHelp() => ManPage("mkdir", "make directories", ["mkdir DIRECTORY..."], ["Create the DIRECTORY(ies), if they do not already exist."]);
}

class Xargs extends BaseCommand {
    Xargs(List<String> arguments) : super(arguments, 'xargs');

    String execute(String stdin, Environment env) {
        if(arguments.length == 0) {
            return "xargs: no command specified\n";
        }
        BaseCommand cmd_to_run = parse_atomic_command(
            arguments.join(" ") + " " + stdin);
        return cmd_to_run.execute("", env);
    }

    ManPage getHelp() => ManPage("xargs", "build and execute command lines from standard input", ["xargs [command [initial-arguments]]"], ["xargs reads items from the standard input, delimited  by", "blanks or newlines, and executes the command (default is", "/bin/echo)  one or more times with any initial-arguments."]);
}

class Pwd extends BaseCommand {
    Pwd(List<String> arguments) : super(arguments, 'pwd');

    String apply(String stdin, Environment env) {
        return env.pwd() + "\n";
    }

    ManPage getHelp() => ManPage("pwd", "print name of current/working directory", ["pwd"], ["Print the full filename of the current working directory."]);
}

class Cd extends BaseCommand {
    Cd(List<String> arguments) : super(arguments, 'cd');

    String apply(String stdin, Environment env) {
        if(arguments.length == 0) {
            return "cd: no path specified\n";
        }
        String path = arguments[0];
        if(!env.exists(path)) {
            return "cd: can't cd to $path\n";
        }
        if(env.get_type(path) == NodeType.FILE) {
            return "cd: can't cd to $path: not a directory\n";
        }
        env.cd(arguments[0]);
        return "";
    }
    
    ManPage getHelp() => ManPage("cd", "change directory", ["cd [DIRECTORY]"], ["Changes the current directory to [DIRECTORY]. The path", "given may be relative or absolute."]);
}

List<String> _find_impl(String path, Environment env) {
    List<String> ret = [env.trim_trailing_slash(path)];
    try {
        if(env.is_link(path)) {
            return ret;
        }
    } on FileException {
        return ["find: $path: No such file or directory"];
    }
    if(env.get_type(path) == NodeType.DIRECTORY) {
        for (String child in get_relative_children(path, env)) {
            ret += _find_impl(child, env);
        }
    }
    return ret;
}

class Find extends BaseCommand {
    Find(List<String> arguments) : super(arguments, 'find');

    String apply(String stdin, Environment env) {
        if(arguments.length == 0) {
            arguments.add('.');
        }
        List<String> ret = [];
        for(String path in arguments) {
            ret += _find_impl(path, env);
        }
        if(ret.length == 0)
            return "";
        return ret.join("\n") + "\n";
    }

    ManPage getHelp() => ManPage("cat", "", [], [""]);
}

class Tee extends BaseCommand {
    Tee(List<String> arguments) : super(arguments, 'tee');

    String apply(String stdin, Environment env) {
        if (arguments.length != 1)
            return "tee: Incorrect number of arguments";
        String target;
        try {
            target = env.absolute_path(arguments[0]);
        } on FileException catch (e) {
            return "tee: Could not open '${arguments[0]}'";
        }
        if (!env.exists(target))
            env.create_new_file(target);
        if (env.get_type(target) == NodeType.DIRECTORY)
            return "tee: Could not open '$target': Is a directory";
        env.write_file(target, stdin);
        return stdin;
    }

    ManPage getHelp() => ManPage("tee", "read from standard input and write to standard output and files", ["tee [FILE]..."], ["Copy standard input to each FILE, and also to  standard  out-", "put."]);
}

void _cp_impl(String from, String to, Environment env) {
    if(env.absolute_path(from) == env.absolute_path(to)) {
        throw LinuxException("can't cp: '$from' and '$to' are the same file");
    }
    if(!env.exists(from)) {
        throw LinuxException("can't stat '$from': No such file or directory");
    }
    if(env.get_type(from) != NodeType.FILE) {
        throw LinuxException("can't copy '$from': Is a directory");
    }
    if(env.exists(to)) {
        if(env.get_type(to) == NodeType.FILE) {
            env.rm(to);
        }
        else {
            String new_target = to + "/" + env.filename(from);
            if(env.exists(new_target)) {
                if(env.get_type(new_target) == NodeType.FILE) {
                    env.rm(new_target);
                }
                else {
                    throw LinuxException("can't create '$to': Already exists");
                }
            }
            to = new_target;
        }
    }
    try {
        env.create_new_file(to, env.read_file(from));
    } on FileException catch (e) {
        throw LinuxException("$to: No such file or directory");
    }
}

// Returns the list of errors
List<String> _cpr_impl(String from, String to, Environment env) {
    if(env.absolute_path(to).indexOf(env.absolute_path(from)) != -1) {
        return ["recustion detected at '$to': omitting"];
    }
    if(!env.exists(from)) {
        return ["can't stat '$from': No such file or directory"];
    }
    if(env.get_type(from) != NodeType.DIRECTORY) {
        throw Exception("Internal error!");
    }
    String real_target;
    if(!env.exists(to)) {
        try {
            env.create_new_dir(to);
        } on FileException catch(e) {
            return ["can't stat '$to': No such file or directory"];
        }
        real_target = to;
    }
    else {
        if(env.get_type(to) != NodeType.DIRECTORY) {
            return ["target '$to' is not a directory"];
        }
        real_target = to + "/" + env.filename(from);
    }
    if(!env.exists(real_target)) {
        try {
            env.create_new_dir(real_target);
        } on FileException catch(e) {
            return ["can't stat '$real_target': No such file or directory"];
        }
    }
    List<String> ret = [];
    for(String child in get_absolute_children(from, env)) {
        if(env.is_link(child) || (env.get_type(child) == NodeType.FILE)) {
            String new_target = real_target + "/" + env.filename(child);
            try {
                _cp_impl(child, new_target, env);
            } on LinuxException catch(e) {
                ret.add(e.cause);
            }
        }
        else {
            assert(env.get_type(child) == NodeType.DIRECTORY);
            ret += _cpr_impl(child, real_target, env);
        }
    }
    return ret;
}

List<String> _cp_united_impl(String from, String to, Environment env) {
    if(!env.exists(from)) {
        return ["can't stat '$from': No such file or directory"];
    }
    if(env.get_type(from) == NodeType.FILE) {
        try {
            _cp_impl(from, to, env);
            return [];
        } on LinuxException catch(e) {
            return [e.cause];
        }
    }
    List<String> errors = _cpr_impl(from, to, env);
    return errors;
}

class Cp extends BaseCommand {
    Cp(List<String> arguments) : super(arguments, 'cp');

    String apply(String stdin, Environment env) {
        if(arguments.length == 0) {
            return "cp: no arguments given\n";
        }
        if(arguments.length == 1) {
            return "cp: only one argument given\n";
        }
        if(arguments.length == 2) {
            List<String> ret = _cp_united_impl(arguments[0], arguments[1], env);
            if(ret.length == 0) {
                return "";
            }
            return ret.join("\n") + "\n";
        }
        if(!env.exists(arguments.last)) {
            String to = arguments.last;
            return "cp: can't copy into '$to': No such file or directory\n";
        }
        if(env.get_type(arguments.last) == NodeType.FILE) {
            String to = arguments.last;
            return "cp: can't copy into '$to': Not a directory\n";
        }
        List<String> ret = [];
        for(String from in arguments.sublist(0, arguments.length - 1)) {
            ret += _cp_united_impl(from, arguments.last, env);
        }
        List<String> real_ret = [];
        for(String error in ret) {
            real_ret.add("cp: " + error);
        }
        if(real_ret.length == 0) {
            return "";
        }
        return real_ret.join("\n") + "\n";
    }

    ManPage getHelp() => ManPage("cp", "copy files and directories", ["cp SOURCE DEST", "cp SOURCE... DIRECTORY"], ["Copy SOURCE to DEST, or multiple SOURCE(s) to DIRECTORY."]);
}

List<String> _rm_impl(String path, Environment env) {
    try {
        if (env.is_link(path)) {
            env.rm(path);
            return [];
        }
    } on FileException catch (e) {
        return ["no such file or directory $path"];
    }
    if(env.get_type(path) == NodeType.FILE) {
        env.rm(path);
        return [];
    }
    List<String> ret = [];
    for(String child in get_absolute_children(path, env)) {
        ret += _rm_impl(child, env);
    }
    try {
        env.rmdir(path);
    } on FileException catch(e) {
        ret.add("cannot remove $path: parent of current directory");
    }
    return ret;
}

class Rm extends BaseCommand {
    Rm(List<String> arguments) : super(arguments, 'rm');

    String apply(String stdin, Environment env) {
        List<String> ret = [];
        for(String path in arguments) {
            ret += _rm_impl(path, env);
        }
        List<String> real_ret = [];
        for(String error in ret) {
            real_ret.add("rm: " + error);
        }
        if(real_ret.length == 0) {
            return "";
        }
        return real_ret.join("\n") + "\n";
    }

    ManPage getHelp() => ManPage("rm", "remove files or directories", ["rm [FILE]..."], ["rm removes each specified file or directory."]);
}

class Rmdir extends BaseCommand {
    Rmdir(List<String> arguments) : super(arguments, 'rmdir');

    String apply(String stdin, Environment env) {
        List<String> result = [];
        for (String arg in arguments) {
            try {
                if (env.is_link(arg) || env.get_type(arg) != NodeType.DIRECTORY) {
                    result.add("rm: Cannot remove '$arg': Not a directory");
                    continue;
                }
            } on FileException {
                result.add("rm: Cannot remove '$arg': Not a directory");
                continue;
            }
            if (env.get_children(arg).length != 0) {
                result.add("rm: Cannot remove '$arg': Not empty");
                continue;
            }
            env.rmdir(arg);
        }
        return result.join("\n");
    }

    ManPage getHelp() => ManPage("rmdir", "remove empty directories", ["rmdir DIRECTORY..."], ["Remove the DIRECTORY(ies), if they are empty."]);
}

List<String> _mv_impl(String from, String to, Environment env) {
    try {
        if(env.is_link(from)) {}
    } on FileException catch(e) {
        return ["$from - no such file or directory"];
    }
    String real_target;
    try {
        if(env.is_link(to)) {
            if(env.get_type(to) == NodeType.DIRECTORY) {
                real_target = to + "/" + env.filename(from);
            }
            else {
                _rm_impl(to, env); // Not checking errors! (kind of on purpose I guess)
                real_target = from;
            }
        }
    } on FileException catch(e) {
        _rm_impl(to, env); // Not checking errors! (kind of on purpose I guess)
        real_target = from;
    }
    if(env.is_link(from)) {
        env.duplicate(from, to);
    }
    else {
        _cp_united_impl(from, to, env);
    }
    return _rm_impl(from, env);
}

class Mv extends BaseCommand {
    Mv(List<String> arguments) : super(arguments, 'mv');

    String apply(String stdin, Environment env) {
        if(arguments.length != 2) {
            return "Unexpected number of arguments\n";
        }
        List<String> ret = _mv_impl(arguments[0], arguments[1], env);
        List<String> real_ret = [];
        for(String error in ret) {
            real_ret.add("mv: " + error);
        }
        if(real_ret.length == 0) {
            return "";
        }
        return real_ret.join("\n") + "\n";
    }

    ManPage getHelp() => ManPage("mv", "move (rename) files", ["mv SOURCE... DIRECTORY"], ["Rename SOURCE to DEST, or move SOURCE(s) to DIRECTORY."]);
}

class Man extends BaseCommand {
    Man(List<String> arguments) : super(arguments, 'man');

    String apply(String stdin, Environment env) {
        if (arguments.length < 1)
        {
            return "What manual page do you want?";
        }

        var cmd_name = arguments[0];
        try {
            var cmd = command_name_and_arguments_to_command(cmd_name, List<String> ());
            var page = cmd.getHelp();
            var upperCmd = page.cmd.toUpperCase();
            var usages = page.usages.map((s) => '       ' + s).join('\n');
            var desc = page.description.map((s) => '       ' + s).join('\n');
            return "${upperCmd}(1)        User Commands        ${upperCmd}(1)\n\n"
                 + "NAME\n"
                 + "       ${page.cmd} - ${page.synopsis}\n\n"
                 + "SYNOPSIS\n"
                 + usages + "\n\n"
                 + "DESCRIPTION\n"
                 + desc + "\n";
        } catch (ParseException) {
            return "No manual entry for ${cmd_name}"; 
        }
    }

    ManPage getHelp() => ManPage("man", "help ambassador", ["man [COMMAND]"], ["Requests help from the benevolent help ambassador."]);
}

class EmptyCommand extends BaseCommand {
    EmptyCommand(List<String> arguments) : super(arguments, 'empty_command') {
        assert(arguments.length == 0);
    }

    String apply(String stdin, Environment env) {
        return stdin;
    }

    ManPage getHelp() => ManPage("cat", "", [], [""]);
}

class ParseException implements LinuxException {
    String cause;
    ParseException(this.cause);
}

const ALL_COMMANDS = ['cat', 'echo', 'ls', 'touch', 'xargs', 'mkdir', 
                      'pwd', 'cd', 'find', 'cp', 'rm', 'mv', 'tee', 'rmdir', '>'];

BaseCommand command_name_and_arguments_to_command(String cmd_name, List<String> arguments) {
    if (GameLogic.removed_commands.contains(cmd_name))
        throw ParseException("No command named $cmd_name");
    switch(cmd_name) {
        case 'cat': return Cat(arguments); break;
        case 'echo': return Echo(arguments); break;
        case 'ls': return Ls(arguments); break;
        case 'touch': return Touch(arguments); break;
        case 'xargs': return Xargs(arguments); break;
        case 'mkdir': return Mkdir(arguments); break;
        case 'pwd': return Pwd(arguments); break;
        case 'cd': return Cd(arguments); break;
        case 'find': return Find(arguments); break;
        case 'cp': return Cp(arguments); break;
        case 'rm': return Rm(arguments); break;
        case 'mv': return Mv(arguments); break;
        case 'tee': return Tee(arguments); break;
        case 'rmdir': return Rmdir(arguments); break;
        case 'man': return Man(arguments); break;
        default: throw ParseException("No command named $cmd_name");
    }
}

Command parse_atomic_command(String cmd_text) {
    const List<String> whitespaces = ["\t", "\n"];
    for(String whitespace in whitespaces)
        cmd_text = cmd_text.replaceAll(whitespace, " ");
    cmd_text.trim();
    List<String> parts = cmd_text.split(" ");
    parts = parts.where((part) => (part.length > 0)).toList();
    if(parts.length == 0)
        return EmptyCommand([]);
    return command_name_and_arguments_to_command(parts[0], parts.sublist(1));
}

Command parse_command(String cmd_text) {
    const List<String> forbidden_characters = ["{", "}", "(", ")", "<", '"', "'", "-"];
    for(var char in forbidden_characters) {
        if(cmd_text.contains(char)) {
            throw ParseException("Character '$char' not yet supported");
        }
    }

    if (cmd_text.contains(">")) {
        if (GameLogic.removed_commands.contains(">"))
            throw ParseException("Invalid character '>'");
        List<String> parts = cmd_text.split(">");
        if (parts.length > 2)
            throw ParseException("Too many occurences of >");
        String filename = parts[1].trim();
        String cmd = parts[0].trim();
        if (filename.contains(' '))
            throw ParseException("Can only redirect into one file");
        return FileStdoutCommand(parse_command(cmd), filename);
    }

    num pipe_loc = cmd_text.indexOf('|');

    if(pipe_loc != -1) {
        Command first = parse_command(cmd_text.substring(0, pipe_loc));
        Command second = parse_command(cmd_text.substring(pipe_loc+1));
        return CompoundCommand(first, second);
    }

    return parse_atomic_command(cmd_text);
}
