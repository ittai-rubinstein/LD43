import "Environment.dart";

abstract class Command {
    String apply(String stdin, Environment filesys);
}

abstract class BaseCommand extends Command {
    List<String> arguments;
    BaseCommand(this.arguments);
}

// Pipe command A into command B
class CompoundCommand extends Command {
    Command a, b;

    CompoundCommand(this.a, this.b);
    String apply(String stdin, Environment filesys) {
        String middle_string = a.apply(stdin, filesys);
        return b.apply(middle_string, filesys);
    }
}

class Echo extends BaseCommand {
    Echo(List<String> arguments) : super(arguments);

    String apply(String stdin, Environment filesys) {
        return arguments.join(" ");
    }
}

class Cat extends BaseCommand {
    Cat(List<String> arguments) : super(arguments);

    String apply(String stdin, Environment filesys) {
        List<String> datas;
//        arguments.forEach(() => ());
        for(String filename in arguments) {
            if(!filesys.exists(filename)) {
                datas.add("File $filename does not exist");
            }
            else {
                datas.add(filesys.get_content(filename));
            }
        }
    }
}
