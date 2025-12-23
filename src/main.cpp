#include <iostream>
// 引用 include 目录下的库头文件
#include "lib_b/b.h" 

// 显式声明其他目录下的函数以便链接
void test_warning(); // 来自 common/lib_a/src/uninit.cpp
void test_error();   // 来自 framework/core/src/memory_leak.cpp

int main() {
    std::cout << "===== 静态分析测试程序运行中 =====" << std::endl;

    // 调用有缺陷的函数，方便 Clang 追踪路径
    test_warning();
    test_error();

    return 0;
}