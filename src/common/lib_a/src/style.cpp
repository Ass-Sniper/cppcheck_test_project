#include <string>
#include <vector>
void test_style(std::vector<std::string> v) {
    for (int i = 0; i < v.size(); ++i) { // 建议使用 const reference 和 size_t
        std::string s = v[i];
    }
}
