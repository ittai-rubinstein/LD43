import "Environment.dart";

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
        return arguments.join(" ");
    }
}

class Cat extends BaseCommand {
    Cat(List<String> arguments) : super(arguments, 'cat');

    String apply(String stdin, Environment env) {
        List<String> datas = [];
        for(String filename in arguments) {
            if(!env.exists(filename)) {
                datas.add("cat: can't open '$filename': No such file or directory");
                continue;
            }
            if(env.get_type(filename) == NodeType.DIRECTORY) {
                datas.add("cat: read error: Is a directory");
                continue;
            }
            datas.add(env.read_file(filename));
        }
        return datas.join("\n");
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
                datas.add(env.get_children(filename).join(" "));
            }
        }
        return datas.join("\n");
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
        return datas.join("\n");
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
        return datas.join("\n");
    }
}

class Pwd extends BaseCommand {
    Pwd(List<String> arguments) : super(arguments, 'pwd');

    String apply(String stdin, Environment env) {
        return env.pwd();
    }
}

class Xargs extends BaseCommand {
    Xargs(List<String> arguments) : super(arguments, 'xargs');

    String apply(String stdin, Environment env) {
        if(arguments.length == 0) {
            return "xargs: no command specified";
        }
        BaseCommand cmd_to_run = parse_atomic_command(
            arguments.join(" ") + " " + stdin);
        return cmd_to_run.apply("", env);
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

class ParseException implements Exception {
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
    const List<String> forbidden_characters = ["{", "}", "(", ")", "<", ">", '"', "'"];
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
