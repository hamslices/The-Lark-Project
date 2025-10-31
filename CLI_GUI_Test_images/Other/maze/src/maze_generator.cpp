// FILE: maze_generator.cpp
// PURPOSE: creates a maze on an 8.5x11" (1728x2236) canvas
//
// AUTHOR: hamslices
// ASSISTANCE: Major portions of this code were developed in collaboration with Google's AI.
//
// USAGE: ./maze_generator

#include <iostream>
#include <vector>
#include <stack>
#include <random>
#include <fstream>
#include <algorithm>

// Represents a single cell in the maze
struct Cell {
    bool visited = false;
    bool walls[4] = { true, true, true, true }; // Top, Right, Bottom, Left
};

class Maze {
public:
    Maze(int width, int height) : width_(width), height_(height) {
        maze_.resize(height_, std::vector<Cell>(width_));
    }

    void generate() {
        std::stack<std::pair<int, int>> stack;
        std::random_device rd;
        std::mt19937 gen(rd());
        std::uniform_int_distribution<> distrib_w(0, width_ - 1);
        std::uniform_int_distribution<> distrib_h(0, height_ - 1);

        int start_x = distrib_w(gen);
        int start_y = distrib_h(gen);

        maze_[start_y][start_x].visited = true;
        stack.push({ start_x, start_y });

        while (!stack.empty()) {
            std::pair<int, int> current = stack.top();
            int x = current.first;
            int y = current.second;

            std::vector<int> neighbors;
            if (y > 0 && !maze_[y - 1][x].visited) neighbors.push_back(0); // Top
            if (x < width_ - 1 && !maze_[y][x + 1].visited) neighbors.push_back(1); // Right
            if (y < height_ - 1 && !maze_[y + 1][x].visited) neighbors.push_back(2); // Bottom
            if (x > 0 && !maze_[y][x - 1].visited) neighbors.push_back(3); // Left

            if (!neighbors.empty()) {
                std::uniform_int_distribution<> distrib_n(0, neighbors.size() - 1);
                int next_dir = neighbors[distrib_n(gen)];

                int next_x = x;
                int next_y = y;

                switch (next_dir) {
                case 0: // Top
                    next_y--;
                    maze_[y][x].walls[0] = false;
                    maze_[next_y][next_x].walls[2] = false;
                    break;
                case 1: // Right
                    next_x++;
                    maze_[y][x].walls[1] = false;
                    maze_[next_y][next_x].walls[3] = false;
                    break;
                case 2: // Bottom
                    next_y++;
                    maze_[y][x].walls[2] = false;
                    maze_[next_y][next_x].walls[0] = false;
                    break;
                case 3: // Left
                    next_x--;
                    maze_[y][x].walls[3] = false;
                    maze_[next_y][next_x].walls[1] = false;
                    break;
                }
                maze_[next_y][next_x].visited = true;
                stack.push({ next_x, next_y });
            }
            else {
                stack.pop();
            }
        }

        // Create an entry and exit
        maze_[0][0].walls[3] = false; // Entry on the left of the top-left cell
        maze_[height_ - 1][width_ - 1].walls[1] = false; // Exit on the right of the bottom-right cell
    }

    void saveToPgm(const std::string& filename, int image_width, int image_height) const {
        std::ofstream outfile(filename, std::ios::out | std::ios::binary);
        if (!outfile) {
            std::cerr << "Error opening file for writing: " << filename << std::endl;
            return;
        }

        // The PGM canvas size remains the same
        outfile << "P5\n" << image_width << " " << image_height << "\n255\n";

        // Background is initialized to white (255)
        std::vector<unsigned char> pixel_data(image_width * image_height, 255);

        const int shrink_pixels = 50;
        const int x_offset = shrink_pixels / 2;
        const int y_offset = shrink_pixels / 2;

        int maze_render_width = image_width - shrink_pixels;
        int maze_render_height = image_height - shrink_pixels;

        // Recalculate cell size based on the new, smaller rendering area
        int cell_width_px = maze_render_width / width_;
        int cell_height_px = maze_render_height / height_;

        int wall_thickness = std::max(1, std::min(cell_width_px, cell_height_px) / 5);

        for (int y = 0; y < height_; ++y) {
            for (int x = 0; x < width_; ++x) {
                // Apply the offset to the starting coordinates of each cell
                int start_x = x * cell_width_px + x_offset;
                int start_y = y * cell_height_px + y_offset;

                if (maze_[y][x].walls[0]) { // Top wall
                    for (int i = 0; i < cell_width_px; ++i) {
                        for (int t = 0; t < wall_thickness; ++t) {
                            if (start_y + t < image_height && start_x + i < image_width)
                                pixel_data[(start_y + t) * image_width + start_x + i] = 0;
                        }
                    }
                }
                if (maze_[y][x].walls[1]) { // Right wall
                    for (int i = 0; i < cell_height_px; ++i) {
                        for (int t = 0; t < wall_thickness; ++t) {
                            if (start_y + i < image_height && start_x + cell_width_px - t - 1 < image_width)
                                pixel_data[(start_y + i) * image_width + start_x + cell_width_px - t - 1] = 0;
                        }
                    }
                }
                if (maze_[y][x].walls[2]) { // Bottom wall
                    for (int i = 0; i < cell_width_px; ++i) {
                        for (int t = 0; t < wall_thickness; ++t) {
                            if (start_y + cell_height_px - t - 1 < image_height && start_x + i < image_width)
                                pixel_data[(start_y + cell_height_px - t - 1) * image_width + start_x + i] = 0;
                        }
                    }
                }
                if (maze_[y][x].walls[3]) { // Left wall
                    for (int i = 0; i < cell_height_px; ++i) {
                        for (int t = 0; t < wall_thickness; ++t) {
                            if (start_y + i < image_height && start_x + t < image_width)
                                pixel_data[(start_y + i) * image_width + start_x + t] = 0;
                        }
                    }
                }
            }
        }
        outfile.write(reinterpret_cast<const char*>(pixel_data.data()), pixel_data.size());
    }

private:
    int width_;
    int height_;
    std::vector<std::vector<Cell>> maze_;
};

int main() {
    const int MAZE_WIDTH = 50;
    const int MAZE_HEIGHT = 70;
    const int IMAGE_WIDTH = 1728;
    const int IMAGE_HEIGHT = 2236;
    const std::string FILENAME = "maze_centered.pgm";

    Maze maze(MAZE_WIDTH, MAZE_HEIGHT);
    maze.generate();
    maze.saveToPgm(FILENAME, IMAGE_WIDTH, IMAGE_HEIGHT);

    std::cout << "Centered maze generated and saved to " << FILENAME << std::endl;

    return 0;
}