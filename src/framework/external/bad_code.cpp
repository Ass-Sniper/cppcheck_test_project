void hidden_error() {
    int* p = 0;
    *p = 10; // 空指针解引用，但该目录被 -i 忽略了
}
