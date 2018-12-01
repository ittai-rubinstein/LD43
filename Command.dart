import "Environment.dart";

List<String> get_absolute_children(String path, Environment env) {
    return env.get_children(path).map((child) => (path + "/" + child)).toList();
}

class LinuxException implements Exception {
    String cause;
    LinuxException(this.cause);
}

abstract class Command {
    String apply(String stdin, Environment env);
}

abstract class BaseCommand extends Command {
    List<String> arguments;
    String cmd_name;
    BaseCommand(this.arguments, this.cmd_name);

    String toString() {
        return "$cmd_name(" + arguments.join(", ") + ")";
    }
}

// Pipe command A into command B
class CompoundCommand extends Command {
    Command a, b;

    CompoundCommand(this.a, this.b);
    String apply(String stdin, Environment env) {
        String middle_string = a.apply(stdin, env);
        return b.apply(middle_string, env);
    }

    String toString() {
        return "(" + a.toString() + " | " + b.toString() + ")";
    }
}

class Echo extends BaseCommand {
    Echo(List<String> arguments) : super(arguments, 'echo');

    String apply(String stdin, Environment env) {
        return arguments.join(" ") + "\n";
    }
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
                datas.add(get_absolute_children(filename, env).join(" "));
            }
        }
        String ret = datas.join("\n");
        if(ret.length == 0)
            return "";
        return ret + "\n";
    }
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
}

class Xargs extends BaseCommand {
    Xargs(List<String> arguments) : super(arguments, 'xargs');

    String apply(String stdin, Environment env) {
        if(arguments.length == 0) {
            return "xargs: no command specified\n";
        }
        BaseCommand cmd_to_run = parse_atomic_command(
            arguments.join(" ") + " " + stdin);
        return cmd_to_run.apply("", env);
    }
}

class Pwd extends BaseCommand {
    Pwd(List<String> arguments) : super(arguments, 'pwd');

    String apply(String stdin, Environment env) {
        return env.pwd() + "\n";
    }
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
}

List<String> _find_impl(String path, Environment env) {
    List<String> ret = [path];
    if(env.is_link(path)) {
        return ret;
    }
    if(env.get_type(path) == NodeType.DIRECTORY) {
        for (String child in get_absolute_children(path, env)) {
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
}

void _cp_impl(String from, String to, Environment env) {
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
            String new_target = to + env.filename(from);
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
    if(!env.exists(from)) {
        return ["can't stat '$from': No such file or directory"];
    }
    if(env.get_type(from) != NodeType.DIRECTORY) {
        throw Exception("Internal error!");
    }
    if(!env.exists(to)) {
        try {
            env.create_new_dir(to);
        } on FileException catch(e) {
            return ["can't stat '$to': No such file or directory"];
        }
    }
    if(env.get_type(to) != NodeType.DIRECTORY) {
        return ["target '$to' is not a directory"];
    }
    String real_target = to + env.filename(to);
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
            String new_target = real_target + env.filename(child);
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
}

class EmptyCommand extends BaseCommand {
    EmptyCommand(List<String> arguments) : super(arguments, 'empty_command') {
        assert(arguments.length == 0);
    }

    String apply(String stdin, Environment env) {
        return stdin;
    }
}

class ParseException implements LinuxException {
    String cause;
    ParseException(this.cause);
}

BaseCommand command_name_and_arguments_to_command(String cmd_name, List<String> arguments) {
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
    const List<String> forbidden_characters = ["{", "}", "(", ")", "<", ">", '"', "'", "-"];
    for(var char in forbidden_characters) {
        if(cmd_text.contains(char)) {
            throw ParseException("Character '$char' not yet supported");
        }
    }

    num pipe_loc = cmd_text.indexOf('|');

    if(pipe_loc != -1) {
        Command first = parse_command(cmd_text.substring(0, pipe_loc));
        Command second = parse_command(cmd_text.substring(pipe_loc+1));
        return CompoundCommand(first, second);
    }

    return parse_atomic_command(cmd_text);
}
