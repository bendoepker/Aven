#include <print>
#include <tokenizer/tokenizer.h>

int main(const int argc, const char** argv, const char** env) {
    if(argc > 1) {
        auto tokens = tokenize(argv[1]);
        for(Token tok : tokens) {
            std::println("{} {} {}", token_type_name(tok.type), tok.data, tok.line);
        }
    } else {
        std::println("Input a file name");
    }
}
