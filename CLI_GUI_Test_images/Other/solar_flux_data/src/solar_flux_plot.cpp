// FILE: solar_flux_plot.cpp
// PURPOSE: Plots solar flux data with all features: auto-scaling, clipping, labels, and hatched fill.
//
// AUTHOR: hamslices
// ASSISTANCE: Major portions of this code were developed in collaboration with Google's AI.
//
// REQUIRES: font8x8_basic.h in the same directory.
// USAGE: ./solar_flux_plot "your_solar_data.csv"

#include <iostream>
#include <vector>
#include <string>
#include <sstream>
#include <algorithm>
#include <fstream>
#include <limits>
#include <cmath>

#include "font8x8_basic.h"

// --- FONT & DRAWING UTILITIES ---

void DrawBrush(std::vector<unsigned char>& buffer, int width, int height, int x, int y, int size, unsigned char color) {
    int halfSize = size / 2;
    for (int dy = -halfSize; dy <= halfSize; ++dy) {
        for (int dx = -halfSize; dx <= halfSize; ++dx) {
            int cX = x + dx, cY = y + dy;
            if (cX >= 0 && cX < width && cY >= 0 && cY < height) {
                buffer[cY * width + cX] = color;
            }
        }
    }
}

void DrawText(std::vector<unsigned char>& buffer, int width, int height, int x, int y, const std::string& text, int scale, unsigned char color) {
    for (const char& c : text) {
        if (c < 0 || c > 127) {
            continue;
        }
        const unsigned char* glyph = font8x8_basic[static_cast<unsigned char>(c)];
        for (int row = 0; row < 8; ++row) {
            for (int col = 0; col < 8; ++col) {
                if ((glyph[row] >> col) & 1) {
                    for (int sy = 0; sy < scale; ++sy) {
                        for (int sx = 0; sx < scale; ++sx) {
                            int pX = x + (col * scale) + sx, pY = y + (row * scale) + sy;
                            if (pX >= 0 && pX < width && pY >= 0 && pY < height) {
                                buffer[pY * width + pX] = color;
                            }
                        }
                    }
                }
            }
        }
        x += (8 * scale);
    }
}

void DrawDottedLine(int x1, int y1, int x2, int y2, std::vector<unsigned char>& buffer, int width, int height, int thickness, unsigned char color, int dash, int gap) {
    int dx = std::abs(x2 - x1), sx = x1 < x2 ? 1 : -1, dy = -std::abs(y2 - y1), sy = y1 < y2 ? 1 : -1, err = dx + dy, e2, len = 0, total = dash + gap;
    while (true) {
        if (gap == 0 || (len % total) < dash) {
            DrawBrush(buffer, width, height, x1, y1, thickness, color);
        }
        if (x1 == x2 && y1 == y2) {
            break;
        }
        e2 = 2 * err;
        if (e2 >= dy) {
            err += dy;
            x1 += sx;
        }
        if (e2 <= dx) {
            err += dx;
            y1 += sy;
        }
        len++;
    }
}

void DrawLine(int x1, int y1, int x2, int y2, std::vector<unsigned char>& buffer, int width, int height, int thickness, unsigned char color) {
    DrawDottedLine(x1, y1, x2, y2, buffer, width, height, thickness, color, 1, 0);
}

void DrawTriangle(std::vector<unsigned char>& buffer, int width, int height, int x, int y, int size, bool pointsRight, unsigned char color) {
    int dir = pointsRight ? 1 : -1;
    DrawLine(x, y, x + (size * dir), y - (size / 2), buffer, width, height, 1, color);
    DrawLine(x, y, x + (size * dir), y + (size / 2), buffer, width, height, 1, color);
    DrawLine(x + (size * dir), y - (size / 2), x + (size * dir), y + (size / 2), buffer, width, height, 1, color);
}

void DrawFilledRectangle(std::vector<unsigned char>& buffer, int width, int height, int x, int y, int w, int h, unsigned char color) {
    for (int row = 0; row < h; ++row) {
        for (int col = 0; col < w; ++col) {
            int pX = x + col, pY = y + row;
            if (pX >= 0 && pX < width && pY >= 0 && pY < height) {
                buffer[pY * width + pX] = color;
            }
        }
    }
}

// --- MAIN APPLICATION ---

struct SolarDataPoint { double julianDate; double observedFlux; };

int main(int argc, char* argv[]) {
    // 1. --- FILE HANDLING, PARSING, STATS, and CANVAS SETUP ---
    if (argc < 2) {
        std::cerr << "Usage: " << argv[0] << " <solar_flux_data.csv>" << std::endl;
        return 1;
    }
    std::string filename = argv[1];
    std::ifstream dataFile(filename);
    if (!dataFile.is_open()) {
        std::cerr << "Error: Could not open file '" << filename << "'" << std::endl;
        return 1;
    }
    std::vector<SolarDataPoint> points;
    std::string line;
    std::getline(dataFile, line);
    while (std::getline(dataFile, line)) {
        std::replace(line.begin(), line.end(), ',', ' ');
        std::stringstream ss(line);
        std::string dummy;
        double julian, flux;
        ss >> dummy >> dummy >> julian >> dummy >> flux;
        if (!ss.fail()) {
            points.push_back({ julian, flux });
        }
    }
    dataFile.close();
    if (points.empty()) {
        std::cerr << "Error: No valid data points were read." << std::endl;
        return 1;
    }
    std::cout << "Successfully read " << points.size() << " data points." << std::endl;
    double sum = 0.0;
    for (const auto& p : points) {
        sum += p.observedFlux;
    }
    double mean = sum / points.size();
    double sum_sq_diff = 0.0;
    for (const auto& p : points) {
        sum_sq_diff += (p.observedFlux - mean) * (p.observedFlux - mean);
    }
    double std_dev = std::sqrt(sum_sq_diff / points.size());
    const double STD_DEV_MULTIPLIER = 3.0;
    double visualMinFlux = std::max(0.0, mean - STD_DEV_MULTIPLIER * std_dev);
    double visualMaxFlux = mean + STD_DEV_MULTIPLIER * std_dev;
    std::cout << "Visual flux range set to: " << visualMinFlux << " -> " << visualMaxFlux << std::endl;
    const int imgWidth = 1728;
    const int padding = 150;
    const double PIXELS_PER_DAY = 10.0;
    double timeRange = points.back().julianDate - points.front().julianDate;
    double visualFluxRange = visualMaxFlux - visualMinFlux;
    int imgHeight = static_cast<int>(std::round(timeRange * PIXELS_PER_DAY)) + (2 * padding);
    std::vector<unsigned char> imageBuffer(imgWidth * imgHeight, 255);

    // 2. --- RENDER BACKGROUND (LABELS & GRIDLINES) ---
    std::cout << "Rendering labels and gridlines..." << std::endl;
    const int TEXT_SCALE = 2;
    unsigned char gridColor = 0;
    int gridThickness = 1;
    std::string title = "Penticton 10.7cm Solar Flux";
    std::string subtitle = "Observed Flux (sfu) - Scaled to 3 Sigma";
    DrawText(imageBuffer, imgWidth, imgHeight, (imgWidth / 2) - (title.length() * 8 * TEXT_SCALE / 2), 30, title, TEXT_SCALE, 0);
    DrawText(imageBuffer, imgWidth, imgHeight, (imgWidth / 2) - (subtitle.length() * 8 * TEXT_SCALE / 2), 65, subtitle, TEXT_SCALE, 0);
    int numFluxTicks = 10;
    for (int i = 0; i <= numFluxTicks; ++i) {
        double fluxValue = visualMinFlux + i * (visualFluxRange / numFluxTicks);
        int xPos = static_cast<int>(std::round((double)i / numFluxTicks * (imgWidth - 2 * padding)) + padding);
        DrawDottedLine(xPos, padding, xPos, imgHeight - padding, imageBuffer, imgWidth, imgHeight, gridThickness, gridColor, 5, 5);
        std::string label = std::to_string(static_cast<int>(fluxValue));
        DrawText(imageBuffer, imgWidth, imgHeight, xPos - (label.length() * 8 * TEXT_SCALE / 2), padding - 40, label, TEXT_SCALE, 0);
    }
    int startYear = static_cast<int>(std::round((points.front().julianDate - 2440587.5) / 365.25));
    int endYear = static_cast<int>(std::round((points.back().julianDate - 2440587.5) / 365.25));
    for (int year = startYear; year <= endYear; ++year) {
        double yearAsJulian = (year * 365.25) + 2440587.5;
        if (yearAsJulian >= points.front().julianDate && yearAsJulian <= points.back().julianDate) {
            int yPos = static_cast<int>(std::round(((yearAsJulian - points.front().julianDate) / timeRange) * (imgHeight - 2 * padding)) + padding);
            DrawDottedLine(padding, yPos, imgWidth - padding, yPos, imageBuffer, imgWidth, imgHeight, gridThickness, gridColor, 1, 0);
            std::string label = std::to_string(year);
            DrawText(imageBuffer, imgWidth, imgHeight, padding - (label.length() * 8 * TEXT_SCALE) - 10, yPos - (8 * TEXT_SCALE / 2), label, TEXT_SCALE, 0);
            double midYearAsJulian = yearAsJulian + (365.25 / 2.0);
            if (midYearAsJulian < points.back().julianDate) {
                int yPosMid = static_cast<int>(std::round(((midYearAsJulian - points.front().julianDate) / timeRange) * (imgHeight - 2 * padding)) + padding);
                DrawDottedLine(padding, yPosMid, imgWidth - padding, yPosMid, imageBuffer, imgWidth, imgHeight, gridThickness, gridColor, 5, 5);
            }
        }
    }

    // 3. --- RENDER HATCHED AREA ---
    std::cout << "Rendering hatched area..." << std::endl;
    unsigned char hatchColor = 0;
    int hatchSpacing = 8;
    std::vector<int> scanline_boundary(imgHeight, 0);
    int lastX_hatch = -1, lastY_hatch = -1;
    for (const auto& p : points) {
        double scaledFlux = (p.observedFlux - visualMinFlux) / visualFluxRange;
        int currentX = static_cast<int>(std::round(scaledFlux * (imgWidth - 2 * padding)) + padding);
        currentX = std::max(padding, std::min(imgWidth - padding, currentX));
        int currentY = static_cast<int>(std::round(((p.julianDate - points.front().julianDate) / timeRange) * (imgHeight - 2 * padding)) + padding);
        if (lastX_hatch != -1) {
            int dx = std::abs(currentX - lastX_hatch), sx = lastX_hatch < currentX ? 1 : -1, dy = -std::abs(currentY - lastY_hatch), sy = lastY_hatch < currentY ? 1 : -1, err = dx + dy, e2;
            int x = lastX_hatch, y = lastY_hatch;
            while (true) {
                if (y >= 0 && y < imgHeight) {
                    if (scanline_boundary[y] == 0 || x > scanline_boundary[y]) {
                        scanline_boundary[y] = x;
                    }
                }
                if (x == currentX && y == currentY) {
                    break;
                }
                e2 = 2 * err;
                if (e2 >= dy) {
                    err += dy;
                    x += sx;
                }
                if (e2 <= dx) {
                    err += dx;
                    y += sy;
                }
            }
        }
        lastX_hatch = currentX;
        lastY_hatch = currentY;
    }
    for (int y = padding; y < imgHeight - padding; ++y) {
        int x_boundary = scanline_boundary[y];
        if (x_boundary > 0) {
            for (int x = padding; x < x_boundary; ++x) {
                if ((x + y) % hatchSpacing == 0) {
                    imageBuffer[y * imgWidth + x] = hatchColor;
                }
            }
        }
    }

    // 4. --- RENDER THE PLOT DATA LINE ---
    std::cout << "Rendering plot data line..." << std::endl;
    const int PLOT_THICKNESS = 3;
    int lastX = -1, lastY = -1;
    for (const auto& p : points) {
        double scaledFlux = (p.observedFlux - visualMinFlux) / visualFluxRange;
        int currentX = static_cast<int>(std::round(scaledFlux * (imgWidth - 2 * padding)) + padding);
        currentX = std::max(padding, std::min(imgWidth - padding, currentX));
        int currentY = static_cast<int>(std::round(((p.julianDate - points.front().julianDate) / timeRange) * (imgHeight - 2 * padding)) + padding);
        if (lastX != -1) {
            DrawLine(lastX, lastY, currentX, currentY, imageBuffer, imgWidth, imgHeight, PLOT_THICKNESS, 0);
        }
        lastX = currentX;
        lastY = currentY;
    }

    // 5. --- RENDER CLIPPED LABELS ---
    std::cout << "Rendering clipped outlier labels..." << std::endl;
    for (const auto& p : points) {
        if (p.observedFlux > visualMaxFlux || p.observedFlux < visualMinFlux) {
            int currentY = static_cast<int>(std::round(((p.julianDate - points.front().julianDate) / timeRange) * (imgHeight - 2 * padding)) + padding);
            std::string label = std::to_string(static_cast<int>(p.observedFlux));
            int textWidth = label.length() * 8 * TEXT_SCALE;
            int textHeight = 8 * TEXT_SCALE;
            if (p.observedFlux > visualMaxFlux) {
                int xPos = imgWidth - padding;
                int textX = xPos - textWidth - 15, textY = currentY - textHeight;
                DrawFilledRectangle(imageBuffer, imgWidth, imgHeight, textX - 2, textY - 2, textWidth + 4, textHeight + 4, 255);
                DrawText(imageBuffer, imgWidth, imgHeight, textX, textY, label, TEXT_SCALE, 0);
                DrawTriangle(imageBuffer, imgWidth, imgHeight, xPos - 5, currentY, 10, false, 0);
            }
            else {
                int xPos = padding;
                int textX = xPos + 15, textY = currentY - textHeight;
                DrawFilledRectangle(imageBuffer, imgWidth, imgHeight, textX - 2, textY - 2, textWidth + 4, textHeight + 4, 255);
                DrawText(imageBuffer, imgWidth, imgHeight, textX, textY, label, TEXT_SCALE, 0);
                DrawTriangle(imageBuffer, imgWidth, imgHeight, xPos + 5, currentY, 10, true, 0);
            }
        }
    }

    // 6. --- SAVE TO PGM FILE ---
    std::string outputFilename = "solar_flux_plot.pgm";
    std::ofstream ofs(outputFilename);
    ofs << "P2\n" << imgWidth << " " << imgHeight << "\n255\n";
    for (int y = 0; y < imgHeight; ++y) {
        for (int x = 0; x < imgWidth; ++x) {
            ofs << static_cast<int>(imageBuffer[y * imgWidth + x]) << " ";
        }
        ofs << "\n";
    }
    ofs.close();
    std::cout << "Success! flux plot saved to " << outputFilename << std::endl;

    return 0;
}