import 'Environment.dart';

class SwapLevel {
    static const String SUN = "\u{1f31e}";
    static const String MOON = "\u{1f31a}";
    // Swap two files
    Environment setup() {
        var env = Environment();
        env.create_new_file("/sun");
        env.create_new_file("/moon");
        env.write_file("/sun", SUN);
        env.write_file("/moon", MOON);
        return env;
    }

    bool is_solved(Environment env) {
        try {
            if (env.read_file("/sun") != MOON)
                return false;
            if (env.read_file("/moon") != SUN)
                return false;
        } catch (e) {
            return false;
        }
        return true;
    }
}