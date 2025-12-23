#include <iostream>
void test_warning() {
    int x; 
    if (x > 0) { // x 未初始化，触发 warning
        std::cout << x << std::endl;
    }
}
