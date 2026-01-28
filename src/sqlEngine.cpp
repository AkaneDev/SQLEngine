#include <SDL2/SDL.h>
#include <sqlite3.h>
#include <iostream>
#include <fstream>
#include <sstream>
#include <vector>
#include <thread>
#include <chrono>

const int SCREEN_WIDTH = 32;
const int SCREEN_HEIGHT = 32;
const int PIXEL_SIZE = 16; // scale each pixel to 16x16 window

// Read entire file into string
std::string readFile(const std::string& filename) {
    std::ifstream file(filename);
    if (!file) {
        std::cerr << "Cannot open file: " << filename << "\n";
        exit(1);
    }
    std::stringstream buffer;
    buffer << file.rdbuf();
    return buffer.str();
}

// Fetch framebuffer into 2D array
void fetchFramebuffer(sqlite3* db, std::vector<std::vector<int>>& screen) {
    const char* query = "SELECT x, y, pixel FROM framebuffer;";
    sqlite3_stmt* stmt;

    if (sqlite3_prepare_v2(db, query, -1, &stmt, nullptr) != SQLITE_OK) {
        std::cerr << "Failed to prepare statement: " << sqlite3_errmsg(db) << "\n";
        return;
    }

    // Clear screen
    for (int y = 0; y < SCREEN_HEIGHT; y++)
        for (int x = 0; x < SCREEN_WIDTH; x++)
            screen[y][x] = 0;

    while (sqlite3_step(stmt) == SQLITE_ROW) {
        int x = sqlite3_column_int(stmt, 0);
        int y = sqlite3_column_int(stmt, 1);
        int pixel = sqlite3_column_int(stmt, 2);
        if (x >= 0 && x < SCREEN_WIDTH && y >= 0 && y < SCREEN_HEIGHT)
            screen[y][x] = pixel;
    }

    sqlite3_finalize(stmt);
}

int main(int argc, char* argv[]) {
    if (argc < 3) {
        std::cerr << "Usage: " << argv[0] << " <sql_file> <db_file>\n";
        return 1;
    }

    std::string sqlFile = argv[1];
    std::string dbFile = argv[2];

    sqlite3* db;
    if (sqlite3_open(dbFile.c_str(), &db) != SQLITE_OK) {
        std::cerr << "Cannot open database: " << sqlite3_errmsg(db) << "\n";
        return 1;
    }

    std::string sql = readFile(sqlFile);

    // Create input_events table if it doesn't exist
    char* errMsg = nullptr;
    if (sqlite3_exec(db,
        "CREATE TABLE IF NOT EXISTS input_events(event CHAR(1));",
        nullptr, nullptr, &errMsg) != SQLITE_OK)
    {
        std::cerr << "SQL error: " << errMsg << "\n";
        sqlite3_free(errMsg);
    }

    // Initialize SDL
    if (SDL_Init(SDL_INIT_VIDEO) != 0) {
        std::cerr << "SDL_Init Error: " << SDL_GetError() << "\n";
        return 1;
    }

    SDL_Window* window = SDL_CreateWindow(
        "SQL Game Engine",
        SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
        SCREEN_WIDTH * PIXEL_SIZE, SCREEN_HEIGHT * PIXEL_SIZE,
        SDL_WINDOW_SHOWN
    );

    SDL_Renderer* renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);
    std::vector<std::vector<int>> screen(SCREEN_HEIGHT, std::vector<int>(SCREEN_WIDTH, 0));

    bool running = true;
    SDL_Event event;

    while (running) {
        // Clear input events at start of tick
        if (sqlite3_exec(db, "DELETE FROM input_events;", nullptr, nullptr, &errMsg) != SQLITE_OK) {
            std::cerr << "SQL error: " << errMsg << "\n";
            sqlite3_free(errMsg);
        }

        // Poll SDL events for keyboard input
        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_QUIT) running = false;
            else if (event.type == SDL_KEYDOWN) {
                char keyChar = 0;
                switch (event.key.keysym.sym) {
                    case SDLK_w: keyChar = 'U'; break;
                    case SDLK_s: keyChar = 'D'; break;
                    case SDLK_a: keyChar = 'L'; break;
                    case SDLK_d: keyChar = 'R'; break;
                }
                if (keyChar != 0) {
                    std::string sqlInsert = "INSERT INTO input_events(event) VALUES('" + std::string(1,keyChar) + "');";
                    if (sqlite3_exec(db, sqlInsert.c_str(), nullptr, nullptr, &errMsg) != SQLITE_OK) {
                        std::cerr << "SQL error: " << errMsg << "\n";
                        sqlite3_free(errMsg);
                    }
                }
            }
        }

        // Execute SQL tick
        if (sqlite3_exec(db, sql.c_str(), nullptr, nullptr, &errMsg) != SQLITE_OK) {
            std::cerr << "SQL error: " << errMsg << "\n";
            sqlite3_free(errMsg);
            break;
        }

        // Fetch framebuffer
        fetchFramebuffer(db, screen);

        // Render framebuffer
        SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255); // black background
        SDL_RenderClear(renderer);

        SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255); // white pixels
        for (int y = 0; y < SCREEN_HEIGHT; y++) {
            for (int x = 0; x < SCREEN_WIDTH; x++) {
                if (screen[y][x]) {
                    SDL_Rect r = { x * PIXEL_SIZE, y * PIXEL_SIZE, PIXEL_SIZE, PIXEL_SIZE };
                    SDL_RenderFillRect(renderer, &r);
                }
            }
        }

        SDL_RenderPresent(renderer);

        std::this_thread::sleep_for(std::chrono::milliseconds(100)); // ~10 FPS
    }

    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
    sqlite3_close(db);

    return 0;
}
