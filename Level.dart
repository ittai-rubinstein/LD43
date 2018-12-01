import 'Environment.dart';

class SwapLevel {
    static const String SUN = "\u{1f31e}";
    static const String MOON = "\u{1f31a}";
    // Swap two files
    Environment setup() {
        var env = Environment();
        env.create_new_file("/sun");
        env.create_new_file("/moon");
        env.set_file_content("/sun", SUN);
        env.set_file_content("/moon", MOON);
        return env;
    }

    bool is_solved(Environment env) {
        try {
            if (env.get_file_content("/sun") != MOON)
                return false;
            if (env.get_file_content("/moon") != SUN)
                return false;
        } catch (e) {
            return false;
        }
        return true;
    }
}