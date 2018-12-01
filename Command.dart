import "Environment.dart";

abstract class Command {
    String apply(String stdin, Environment env);
}

abstract class BaseCommand extends Command {
    List<String> arguments;
    BaseCommand(this.arguments);
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
    Echo(List<String> arguments) : super(arguments);

    String apply(String stdin, Environment env) {
        return arguments.join(" ");
    }

    String toString() {
        return "echo(" + arguments.join(', ') + ")";
    }
}

class Cat extends BaseCommand {
    Cat(List<String> arguments) : super(arguments);

    String apply(String stdin, Environment env) {
        List<String> datas;
        for(String filename in arguments) {
            if(!env.exists(filename)) {
                datas.add("Path $filename does not exist");
                continue;
            }
            if(env.get_type(filename) == NodeType.DIRECTORY) {
                datas.add("$filename is a directory");
                continue;
            }
            datas.add(env.read_file(filename));
        }
        return datas.join("\n");
    }

    String toString() {
        return "cat(" + arguments.join(', ') + ")";
    }
}

class Ls extends BaseCommand {
    Ls(List<String> arguments) : super(arguments);

    String apply(String stdin, Environment env) {
        List<String> datas;
        for(String filename in arguments) {
            if(!env.exists(filename)) {
                datas.add("Path $filename does not exist");
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

    String toString() {
        return "ls(" + arguments.join(', ') + ")";
    }
}

class EmptyCommand extends BaseCommand {
    EmptyCommand(List<String> arguments) : super(arguments) {
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
    cmd_name = cmd_name.toLowerCase();
    switch(cmd_name) {
        case 'cat': return Cat(arguments); break;
        case 'echo': return Echo(arguments); break;
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
