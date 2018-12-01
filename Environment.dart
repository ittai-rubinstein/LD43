class FileException implements Exception {}

class Environment {
    FileSystem filesys;

    Node curDir;

    Environment() {
        filesys = FileSystem();
        curDir = filesys.root;
    }

    String absolute_path(String path) {
        var location = get_insertion_point(path);
        String result = path_to_node(location.dir);
        if (location.name != '')
            result += '${location.name}';
        return result;
    }

    String path_to_node(Node node) {
        String result = node.type == NodeType.DIRECTORY ? '/' : '';
        while (!identical(node, filesys.root)) {
            result = '/${node.name}' + result;
            node = node.parent;
        }
        return result;
    }

    InsertionPoint get_insertion_point(String path, {int recursion_limit = 100, Node start_from = null}) {
        InsertionPoint ptr;
        if (start_from == null)
            start_from = curDir;
        if (path == '')
            return InsertionPoint(start_from);
        if (path[0] == '/') {
            ptr = InsertionPoint(filesys.root);
            path = path.substring(1);
        } else {
            ptr = InsertionPoint(start_from);
        }
        List<String> path_components = path.split("/");
        for (int i = 0;i < path_components.length;i++) {
            String component = path_components[i];
            if (ptr.name != '')
                throw FileException();  // either a file or a non-existing object
            if (component == '.' || component == '')
                continue;
            if (component == '..') {
                ptr.dir = ptr.dir.parent;
                continue;
            }
            if (!ptr.dir.children.containsKey(component)) {
                // point to the non-exiting child
                ptr.name = component;
                continue;
            }
            Node child = ptr.dir.children[component];

            switch (child.type) {
                case NodeType.DIRECTORY:
                    ptr.dir = child;
                    break;
                case NodeType.FILE:
                    ptr.name = component;
                    break;
                case NodeType.LINK:
                    if (recursion_limit == 0)
                        throw FileException();
                    ptr = get_insertion_point(child.contents, 
                            recursion_limit: recursion_limit-1, start_from: ptr.dir);
            }
            // here we're about to exit the loop. ptr must point to file / directory
        }
        return ptr;
    }

    Node get_parent_dir(String path) {
        Node result = get_insertion_point(dirname(path)).get_node();
        if (result.type != NodeType.DIRECTORY)
            throw FileException();
        return result;
    }

    bool exists(String path) {
        try {
            return get_insertion_point(path).exists();
        } on FileException catch (e) {
            // failed to get the insertion point
            return false;
        }
    }

    NodeType get_type(String path) => get_insertion_point(path).get_node().type;

    bool is_link(String path) {
        Node container = get_parent_dir(path);
        if (!container.children.containsKey(filename(path)))
            throw FileException();
        return container.children[filename(path)].type == NodeType.LINK;
    }

    List<String> get_children(String path) {
        Node node = get_insertion_point(path).get_node();
        if (node.type != NodeType.DIRECTORY)
            throw FileException();
        return node.children.keys.toList();
    }

    String read_file(String path) {
        Node file = get_insertion_point(path).get_node();
        if (file.type != NodeType.FILE)
            throw FileException();
        return file.contents;
    }

    void write_file(String path, String content) {
        Node file = get_insertion_point(path).get_node();
        if (file.type != NodeType.FILE)
            throw FileException();
        file.contents = content;
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

    void create_new_file(String path, [String content = null]) {
        InsertionPoint location = get_insertion_point(path);
        if (location.exists())
            throw FileException();
        Node new_file = Node.File(filename(path));
        if (content != null)
            new_file.contents = content;
        location.dir.set_child(new_file);
    }
    
    void create_new_dir(String path) {
        InsertionPoint location = get_insertion_point(path);
        if (location.exists())
            throw FileException();
        Node new_dir = Node.Directory(filename(path));
        location.dir.set_child(new_dir);
    }

    String pwd() {
        return path_to_node(curDir);
    }

    void cd(String path) {
        Node target = get_insertion_point(path).get_node();
        if (target.type != NodeType.DIRECTORY)
            throw FileException();
        curDir = target;
    }

    void rm(String path) {
        Node container = get_parent_dir(path);
        if (!container.children.containsKey(filename(path)))
            throw FileException();
        container.children.remove(filename(path));
    }

    void rmdir(String path) {
        Node container = get_parent_dir(path);
        if (!container.children.containsKey(filename(path))) 
            throw FileException();
        Node target = container.children[filename(path)];
        if (target.type != NodeType.DIRECTORY)
            throw FileException();
        if (target.children.length != 0)
            throw FileException();
        if (identical(target, curDir))
            throw FileException();
        container.children.remove(filename(path));
    }

    void duplicate(String from, String to) {
        Node from_container = get_parent_dir(from);
        if (!from_container.children.containsKey(filename(from)))
            throw FileException();
        Node from_node = from_container.children[filename(from)];
        if (from_node.type == NodeType.DIRECTORY)
            throw FileException();
        Node to_container = get_parent_dir(to);
        if (to_container.children.containsKey(filename(to)))
            throw FileException();
        to_container.children[filename(to)] = from_node;
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

    Node.File(this.name) : type = NodeType.FILE, contents = "";

    Node.Directory(this.name) : type = NodeType.DIRECTORY, children = Map<String, Node>();

    void set_child(Node file) {
        file.parent = this;
        children[file.name] = file;
    }
}

class InsertionPoint {
    Node dir;  // always a directory
    String name;
    InsertionPoint(this.dir,[this.name = '']);
    bool exists() {
        if (name == '')
            return true;  // this is a directory, not a file
        return dir.children.containsKey(name);
    }
    Node get_node() {
        if (name == '')
            return dir;
        if (!dir.children.containsKey(name))
            throw FileException();
        return dir.children[name];
    }
}

class FileSystem {
    Node root;

    FileSystem() {
        root = Node.Directory('');
        root.parent = root;
    }
}
