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
                return null;
            if (ptr.type == NodeType.LINK) {
                if (recursion_limit == 0)
                    return null;
                ptr = node_at(ptr.contents, recursion_limit: recursion_limit-1, start_from: ptr);
                if (ptr == null)
                    return null;
                continue;
            }
            if (component == '.' || component == '')
                continue;
            if (component == '..') {
                ptr = ptr.parent;
                continue;
            }
            ptr = ptr.get_child(component);
        }
        return ptr;
    }

    bool exists(String path) => node_at(path) != null;

    NodeType get_type(String path) {
        Node node = node_at(path);
        if (node == null)
            throw FileException();
        return node.type;
    }

    String read_file(String path) {
        Node file = node_at(path);
        if (file == null)
            throw FileException();
        if (file.type != NodeType.FILE)
            throw FileException();
        return file.contents;
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

    Node get_child(String component) => children[component];
}

class FileSystem {
    Node root;

    FileSystem() {
        root = Node();
        root.parent = root;
        root.type = NodeType.DIRECTORY;
        root.children = Map<String, Node>();
    }
}
