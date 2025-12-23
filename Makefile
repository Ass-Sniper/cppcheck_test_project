# 编译器与参数
CXX = g++
# -g 能够帮助 Clang 更好地关联源码路径
CXXFLAGS = -Wall -Wextra -g \
           -Iinclude \
           -Isrc/common/lib_a/include \
           -Isrc/framework/core/include

# 定义源文件路径 (全部位于 src 下)
SRCS = src/main.cpp \
       src/common/lib_a/src/style.cpp \
       src/common/lib_a/src/uninit.cpp \
       src/framework/core/src/memory_leak.cpp

# 生成目标对象名
OBJS = $(SRCS:.cpp=.o)
TARGET = test_prog

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CXX) $(OBJS) -o $(TARGET)

# 编译规则
%.o: %.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@

clean:
	rm -f $(OBJS) $(TARGET)
	@echo "清理完成"