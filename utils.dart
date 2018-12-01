import "FileSystem.dart";

bool is_absolute_directory(String path) {
    if(path.length == 0) {
        return false;
    }
    return (path[0] == "/");
}
