import 'FileSystem.dart';

class Environment {
    FileSystem filesys;
    Map<String, String> env_variables;

    Environment(this.filesys) {
        env_variables["pwd"] = "/";
    }

    String sanitize_path(String unsanitized_path, FileSystem filesys) {
        String absolute_path;
        if(is_absolute_directory(unsanitized_path)) {
            absolute_path = unsanitized_path;
        }
        else {
            absolute_path = env_variables["pwd"] + unsanitized_path;
        }
    }
}
