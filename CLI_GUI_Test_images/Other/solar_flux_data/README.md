# Scientific Data Plotter for Roll-Feed Printers

This project is a C++ application designed to generate long, continuous plots of scientific time-series data. Its primary purpose is to serve as a demonstration piece, showcasing the capability of a roll-feed or continuous-form printer to handle and visualize large, complex scientific datasets with high fidelity.

The program reads a text-based data file, processes it, and outputs a high-resolution monochrome image in the PGM (Portable Graymap) format, ready for printing.

## Features

-   **Long-Form Plotting:** Designed specifically for continuous data, where the plot's length (height) is determined by the duration of the dataset.
-   **Automatic Scaling:** The plot automatically analyzes the data to establish a "normal" visual range (based on mean and standard deviation), preventing a few extreme outliers from ruining the scale.
-   **Outlier Clipping & Labeling:** Data points that fall outside the normal range are visually clipped at the plot's boundary. These outliers are clearly marked with a triangle and labeled with their true value, ensuring no information is lost.
-   **Hatched Area Fill:** The area under the plot line is filled with a light diagonal hatch pattern, improving visual appeal and emphasizing the data's magnitude.
-   **Custom Font Rendering:** Uses an embedded 8x8 bitmap font to render a title, axis labels, and tick marks directly onto the image.
-   **Dynamic Gridlines:** Generates a clean grid with solid lines for major intervals (years) and dotted lines for minor intervals (mid-years) to provide clear context.
-   **Self-Contained:** The application is a single C++ source file with no external library dependencies, making it highly portable and easy to compile.

## Sample Output

The program generates a PGM image (`final_solar_plot.pgm`). It is recommended to convert this to a more common format like PNG for viewing or embedding.

## How It Works

The application follows a precise rendering pipeline to ensure all elements are layered correctly for maximum readability:

1.  **Data Ingestion:** The program reads and parses the specified CSV data file, loading the time and measurement values into memory.
2.  **Statistical Analysis:** It calculates the mean and standard deviation of the measurement data to determine the optimal visual range for the plot, ignoring extreme spikes.
3.  **Canvas Setup:** An in-memory image buffer is created with a fixed width (for the printer) and a dynamic height calculated from the time span of the data.
4.  **Background Rendering:** The background is drawn first, including the title, axis labels, and the dotted gridlines.
5.  **Hatching:** The area under the curve is filled with a light hatch pattern. This is done by first mapping the plot's boundary and then filling the area with a diagonal pattern.
6.  **Plot Line Rendering:** The main, thick data line is drawn on top of the background and the hatching.
7.  **Outlier Labeling:** Finally, any clipped data points are marked with a triangle and a text label. A "whiteout" box is drawn behind each label to create a clean cutout, ensuring it is perfectly legible even if it overlaps the plot line.

## Usage

### Dependencies

-   A C++ compiler that supports C++11 (e.g., `g++`, `clang++`, MSVC).
-   The font header file `font8x8_basic.h` must be present in the same directory as the source code.

### Compilation

Open a terminal or command prompt in the project directory and run the following command:

```bash
g++ create_final_solar_plot.cpp -o create_final_solar_plot -std=c++11
```

### Execution

Run the compiled program from the terminal, providing the path to your data file as an argument:

```bash
./create_final_solar_plot "your_solar_data.csv"
```

The program will print its progress and save the output as `final_solar_plot.pgm`.

## Customization

Several key parameters can be easily adjusted by changing the `const` variables in the `main()` function of the C++ source code:

| Constant             | Description                                                                 | Default |
| -------------------- | --------------------------------------------------------------------------- | ------- |
| `imgWidth`           | The fixed width of the output image, corresponding to the printer's width.  | `1728`  |
| `PIXELS_PER_DAY`     | Controls the vertical scale (length) of the plot. Higher values stretch it. | `10.0`  |
| `STD_DEV_MULTIPLIER` | The number of standard deviations from the mean to define the visual range. | `3.0`   |
| `PLOT_THICKNESS`     | The thickness of the main data line in pixels.                              | `3`     |
| `TEXT_SCALE`         | The integer scaling factor for the 8x8 font (e.g., 2 creates 16x16 text).   | `2`     |

## Data Source & Notices

This application is designed to plot the 10.7cm solar flux data provided by Natural Resources Canada. For full data citation and attribution for the included font, please see the `notice.md` file.

## Author

-   **hamslices**