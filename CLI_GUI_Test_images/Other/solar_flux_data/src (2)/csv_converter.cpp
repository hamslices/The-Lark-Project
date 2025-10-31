// FILE: csv_converter.cpp
// PURPOSE: Converts csv date-time Fields to proper date-time units for plotting.
//          Removes all but fluxursi data.
//
// AUTHOR: hamslices
// ASSISTANCE: Major portions of this code were developed in collaboration with Google's AI.
//
// REQUIRES: "input.csv" in the same directory as the exe.
// USAGE: ./csv_converter

#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <sstream>
#include <cmath>
#include <iomanip>

// Extracts the date (YYYY-MM-DD) from a Julian Day number
std::string julian_to_date(double julian_day) {
    long long J = static_cast<long long>(julian_day + 0.5);

    long long A;
    if (J < 2299161) {
        A = J;
    }
    else {
        long long alpha = static_cast<long long>((J - 1867216.25) / 36524.25);
        A = J + 1 + alpha - static_cast<long long>(alpha / 4);
    }

    long long B = A + 1524;
    long long C = static_cast<long long>((B - 122.1) / 365.25);
    long long D = static_cast<long long>(365.25 * C);
    long long E = static_cast<long long>((B - D) / 30.6001);

    int day = static_cast<int>(B - D - static_cast<long long>(30.6001 * E));
    int month = (E < 14) ? static_cast<int>(E - 1) : static_cast<int>(E - 13);
    int year = (month > 2) ? static_cast<int>(C - 4716) : static_cast<int>(C - 4715);

    std::stringstream ss;
    ss << std::setfill('0') << std::setw(4) << year << "-"
        << std::setw(2) << month << "-"
        << std::setw(2) << day;

    return ss.str();
}

// Converts the fractional part of a Carrington Rotation to time (HH:MM:SS)
std::string carrington_to_time(double carrington_rotation) {
    double fraction = carrington_rotation - static_cast<long long>(carrington_rotation);
    double total_seconds = fraction * 24.0 * 3600.0;

    int hours = static_cast<int>(total_seconds / 3600);
    total_seconds -= hours * 3600;
    int minutes = static_cast<int>(total_seconds / 60);
    int seconds = static_cast<int>(total_seconds - minutes * 60);

    std::stringstream ss;
    ss << std::setfill('0') << std::setw(2) << hours << ":"
        << std::setw(2) << minutes << ":"
        << std::setw(2) << seconds;

    return ss.str();
}

int main() {
    std::ifstream inputFile("input.csv");
    if (!inputFile.is_open()) {
        std::cerr << "Error: Could not open input file." << std::endl;
        return 1;
    }

    std::ofstream outputFile("output_final.csv");
    if (!outputFile.is_open()) {
        std::cerr << "Error: Could not create output file." << std::endl;
        return 1;
    }

    outputFile << "datetime,fluxursi\n";

    std::string line;
    std::getline(inputFile, line); // Skip header

    while (std::getline(inputFile, line)) {
        std::stringstream ss(line);
        std::string cell;
        std::vector<std::string> row;

        while (std::getline(ss, cell, ',')) {
            // Trim whitespace
            cell.erase(0, cell.find_first_not_of(" \t\n\r"));
            cell.erase(cell.find_last_not_of(" \t\n\r") + 1);
            row.push_back(cell);
        }

        if (row.size() >= 7) {
            try {
                double julian_day = std::stod(row[2]);
                double carrington_rotation = std::stod(row[3]);

                std::string date_part = julian_to_date(julian_day);
                std::string time_part = carrington_to_time(carrington_rotation);

                outputFile << date_part << " " << time_part << "," << row[6] << "\n";
            }
            catch (const std::invalid_argument& e) {
                std::cerr << "Warning: Skipping row due to invalid number format." << std::endl;
            }
            catch (const std::out_of_range& e) {
                std::cerr << "Warning: Skipping row due to number out of range." << std::endl;
            }
        }
    }

    inputFile.close();
    outputFile.close();

    std::cout << "CSV processing complete. Data saved to output_final.csv" << std::endl;

    return 0;
}