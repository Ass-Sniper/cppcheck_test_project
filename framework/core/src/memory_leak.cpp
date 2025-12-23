void test_error() {
    int* p = new int[10];
    // 故意不 delete，触发 error
}
