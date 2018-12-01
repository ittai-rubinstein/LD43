import 'FileSystem.dart';

class Environment {
    FileSystem filesys;
    Map<String, String> env_variables;

    Environment(this.filesys);
}
