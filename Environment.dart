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

    Node node_at(String path) {
        Node ptr;
        if (path == '')
            return curDir;
        if (path[0] == '/') {
            ptr = filesys.root;
            path = path.substring(1);
        } else {
            ptr = curDir;
        }
        for (var component in path.split("/")) {
            if (ptr.type != NodeType.DIRECTORY)
                return null;
            if (component == '.')
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
