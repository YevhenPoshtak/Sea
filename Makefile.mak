# Компілятор та прапорці
CXX = g++
CXXFLAGS = -std=c++17 -Wall -Wextra -O2
LDFLAGS = 

# Визначення платформи
ifeq ($(OS),Windows_NT)
    # Windows
    PLATFORM = WIN32
    LDFLAGS += -lws2_32
    EXT = .exe
    RM = del /Q
    MKDIR = if not exist $(subst /,\,$(1)) mkdir $(subst /,\,$(1))
else
    # Unix/Linux/MacOS
    UNAME_S := $(shell uname -s)
    ifeq ($(UNAME_S),Linux)
        PLATFORM = LINUX
    endif
    ifeq ($(UNAME_S),Darwin)
        PLATFORM = MACOS
    endif
    EXT = 
    RM = rm -f
    MKDIR = mkdir -p $(1)
endif

# Додавання прапорців для платформи
CXXFLAGS += -D$(PLATFORM)

# Директорії
SRC_DIR = .
BUILD_DIR = build
BIN_DIR = bin

# Вихідні файли
COMMON_SOURCES = board.cpp player.cpp ui.cpp
AI_SOURCES = ai_random.cpp ai_smart.cpp
NETWORK_SOURCES = server.cpp client.cpp

# Об'єктні файли
COMMON_OBJECTS = $(patsubst %.cpp,$(BUILD_DIR)/%.o,$(COMMON_SOURCES))
AI_OBJECTS = $(patsubst %.cpp,$(BUILD_DIR)/%.o,$(AI_SOURCES))
NETWORK_OBJECTS = $(patsubst %.cpp,$(BUILD_DIR)/%.o,$(NETWORK_SOURCES))

# Виконувані файли
LOCAL_GAME = $(BIN_DIR)/battleship_local$(EXT)
AI_GAME = $(BIN_DIR)/battleship_ai$(EXT)
SERVER = $(BIN_DIR)/battleship_server$(EXT)
CLIENT = $(BIN_DIR)/battleship_client$(EXT)

# Всі цілі
ALL_TARGETS = $(LOCAL_GAME) $(AI_GAME) $(SERVER) $(CLIENT)

# Головна ціль
.PHONY: all
all: dirs $(ALL_TARGETS)

# Створення директорій
.PHONY: dirs
dirs:
	@$(call MKDIR,$(BUILD_DIR))
	@$(call MKDIR,$(BIN_DIR))

# Локальна гра (2 гравці)
$(LOCAL_GAME): $(BUILD_DIR)/main_local.o $(COMMON_OBJECTS)
	@echo "Збірка локальної гри..."
	$(CXX) $(CXXFLAGS) $^ -o $@ $(LDFLAGS)
	@echo "✓ $(LOCAL_GAME) готовий!"

# Гра проти AI
$(AI_GAME): $(BUILD_DIR)/main_vs_ai.o $(COMMON_OBJECTS) $(AI_OBJECTS)
	@echo "Збірка гри проти AI..."
	$(CXX) $(CXXFLAGS) $^ -o $@ $(LDFLAGS)
	@echo "✓ $(AI_GAME) готовий!"

# Мережевий сервер
$(SERVER): $(NETWORK_OBJECTS) $(COMMON_OBJECTS)
	@echo "Збірка сервера..."
	$(CXX) $(CXXFLAGS) $(BUILD_DIR)/server.o $(COMMON_OBJECTS) -o $@ $(LDFLAGS)
	@echo "✓ $(SERVER) готовий!"

# Мережевий клієнт
$(CLIENT): $(NETWORK_OBJECTS) $(COMMON_OBJECTS)
	@echo "Збірка клієнта..."
	$(CXX) $(CXXFLAGS) $(BUILD_DIR)/client.o $(COMMON_OBJECTS) -o $@ $(LDFLAGS)
	@echo "✓ $(CLIENT) готовий!"

# Компіляція об'єктних файлів
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.cpp
	@echo "Компіляція $<..."
	$(CXX) $(CXXFLAGS) -c $< -o $@

# Окремі цілі для кожного режиму
.PHONY: local
local: dirs $(LOCAL_GAME)

.PHONY: ai
ai: dirs $(AI_GAME)

.PHONY: server
server: dirs $(SERVER)

.PHONY: client
client: dirs $(CLIENT)

.PHONY: network
network: server client

# Очистка
.PHONY: clean
clean:
	@echo "Очистка..."
ifeq ($(OS),Windows_NT)
	@if exist $(BUILD_DIR) rmdir /S /Q $(BUILD_DIR)
	@if exist $(BIN_DIR) rmdir /S /Q $(BIN_DIR)
else
	@rm -rf $(BUILD_DIR) $(BIN_DIR)
endif
	@echo "✓ Очищено!"

# Повна очистка та перезбірка
.PHONY: rebuild
rebuild: clean all

# Запуск ігор
.PHONY: run-local
run-local: $(LOCAL_GAME)
	@echo "Запуск локальної гри..."
	@$(LOCAL_GAME)

.PHONY: run-ai
run-ai: $(AI_GAME)
	@echo "Запуск гри проти AI..."
	@$(AI_GAME)

.PHONY: run-server
run-server: $(SERVER)
	@echo "Запуск сервера..."
	@$(SERVER)

.PHONY: run-client
run-client: $(CLIENT)
	@echo "Запуск клієнта..."
	@$(CLIENT)

# Допомога
.PHONY: help
help:
	@echo "=== Морський Бій - Makefile ==="
	@echo ""
	@echo "Доступні команди:"
	@echo "  make          - збірка всіх компонентів"
	@echo "  make all      - те саме що make"
	@echo ""
	@echo "Збірка окремих компонентів:"
	@echo "  make local    - локальна гра (2 гравці)"
	@echo "  make ai       - гра проти AI"
	@echo "  make server   - мережевий сервер"
	@echo "  make client   - мережевий клієнт"
	@echo "  make network  - сервер і клієнт"
	@echo ""
	@echo "Запуск:"
	@echo "  make run-local   - запустити локальну гру"
	@echo "  make run-ai      - запустити гру проти AI"
	@echo "  make run-server  - запустити сервер"
	@echo "  make run-client  - запустити клієнт"
	@echo ""
	@echo "Утиліти:"
	@echo "  make clean    - очистити збудовані файли"
	@echo "  make rebuild  - повна перезбірка"
	@echo "  make help     - показати цю довідку"
	@echo ""
	@echo "Платформа: $(PLATFORM)"

# Залежності заголовків
$(BUILD_DIR)/board.o: board.cpp board.h common.h
$(BUILD_DIR)/player.o: player.cpp player.h board.h common.h
$(BUILD_DIR)/ui.o: ui.cpp common.h player.h
$(BUILD_DIR)/ai_random.o: ai_random.cpp ai.h player.h board.h common.h
$(BUILD_DIR)/ai_smart.o: ai_smart.cpp ai.h player.h board.h common.h
$(BUILD_DIR)/server.o: server.cpp network.h player.h board.h common.h
$(BUILD_DIR)/client.o: client.cpp network.h player.h board.h common.h
$(BUILD_DIR)/main_local.o: main_local.cpp common.h board.h player.h
$(BUILD_DIR)/main_vs_ai.o: main_vs_ai.cpp common.h board.h player.h ai.h

.DEFAULT_GOAL := help