class FileException implements Exception {}

class Environment {
    FileSystem filesys;

    Node curDir;

    Environment() {
        filesys = FileSystem();
        curDir = filesys.root;
    }

    String absolute_path(String path) {
        var end_node = node_at(path);
        if (end_node == null)
            throw FileException();
        return path_to_node(end_node);
    }

    String path_to_node(Node node) {
        String result = '';
        if (identical(node, filesys.root))
            return '/';
        while (!identical(node, filesys.root)) {
            result = '/${node.name}' + result;
            node = node.parent;
        }
        return result;
    }

    Node node_at(String path, {int recursion_limit = 100, Node start_from = null}) {
        Node ptr;
        if (start_from == null)
            start_from = curDir;
        if (path == '')
            return start_from;
        if (path[0] == '/') {
            ptr = filesys.root;
            path = path.substring(1);
        } else {
            ptr = start_from;
        }
        for (var component in path.split("/")) {
            if (ptr.type == NodeType.FILE)
                throw FileException();
            if (ptr.type == NodeType.LINK) {
                if (recursion_limit == 0)
                    throw FileException();
                ptr = node_at(ptr.contents, recursion_limit: recursion_limit-1, start_from: ptr);
                continue;
            }
            if (component == '.' || component == '')
                continue;
            if (component == '..') {
                ptr = ptr.parent;
                continue;
            }
            if (!ptr.children.containsKey(component))
                throw FileException();
            ptr = ptr.children[component];
        }
        return ptr;
    }

    bool exists(String path) {
        try {
            node_at(path);
            return true;
        } on FileException catch (e) {
            return false;
        }
    }

    NodeType get_type(String path) => node_at(path).type;

    List<String> get_children(String path) {
        Node node = node_at(path);
        if (node.type != NodeType.DIRECTORY)
            throw FileException();
        return node.children.keys;
    }

    String read_file(String path) {
        Node file = node_at(path);
        if (file.type != NodeType.FILE)
            throw FileException();
        return file.contents;
    }

    String dirname(String path) {
        if (!path.contains('/'))
            return '';  // file in current directory
        
        var slash_pos = path.lastIndexOf('/');
        return path.substring(0, slash_pos);
    }

    String filename(String path) {
        if (!path.contains('/'))
            return path;  // file in current directory
        
        var slash_pos = path.lastIndexOf('/');
        return path.substring(slash_pos+1);
    }

    void create_new(String path) {
        Node dir = node_at(dirname(path));
        if (dir.type != NodeType.DIRECTORY)
            throw FileException();
        String fn = filename(path);
        if (dir.children.containsKey(fn))
            throw FileException();

        Node new_file = Node.File(fn);
        dir.set_child(new_file);
    }
}

enum NodeType {
    FILE, DIRECTORY, LINK
}

class Node {
    // A directory or file
    Map<String, Node> children;
    NodeType type;
    Node parent;
    String name;
    String contents;

    Node.File(this.name) : type = NodeType.FILE;

    Node.Directory(this.name) : type = NodeType.DIRECTORY, children = Map<String, Node>();

    void set_child(Node file) {
        file.parent = this;
        children[file.name] = file;
    }
}

class FileSystem {
    Node root;

    FileSystem() {
        root = Node.Directory('');
        root.parent = root;
    }
}
