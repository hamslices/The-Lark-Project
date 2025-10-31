# Scientific Data Sample for Roll-Feed Printers

## Overview

This directory contains a collection of sample images generated from scientific data, specifically formatted and prepared for high-quality printing on the "Lark" roll-feed printing system.

The samples demonstrate a complete data visualization workflow, starting from a raw CSV data file, proceeding through data conversion with a custom application, and culminating in rendered plots from both the custom application and the scientific plotting software LabPlot.

## About the Data

The scientific data used in this project is the **Adjusted 10.7 cm Solar Flux** record, sourced from the **Canadian Space Weather Forecast Centre**, a part of Natural Resources Canada.

-   **Data Source**: [Natural Resources Canada - 10.7 cm Solar Flux Data](https://www.spaceweather.gc.ca/forecast-prevision/solar-solaire/solarflux/sx-5-flux-en.php)
-   **What it Measures**: The 10.7 cm solar flux is a measurement of the radio emissions from the Sun at a wavelength of 10.7 centimeters. It serves as an excellent indicator of solar activity, tracking everything from solar flares to the overall solar cycle.
-   **Significance**: This data is crucial for space weather forecasting. Changes in solar activity, as indicated by this flux, can have significant effects on Earth's atmosphere, satellite operations, and telecommunication systems. The "Adjusted" value is corrected to a standard distance of one Astronomical Unit (the distance from the Sun to the Earth).

## Data Workflow

The images in this collection are the result of a precise data processing and visualization pipeline:

1.  **Raw Data Input**: The original data was downloaded in a standard Comma-Separated Values (`.csv`) format from the source above. It contained time-series information from the Penticton Radio Observatory.

2.  **Data Conversion**: A custom C++ application was developed to parse the raw CSV file. This application performed two key tasks:
    *   It converted complex astronomical time formats (Julian Day and Carrington Rotation) into a standard, human-readable `YYYY-MM-DD HH:MM:SS` datetime string.
    *   It extracted the relevant `fluxursi` (Adjusted Solar Flux) data column for visualization.

3.  **Plotting and Rendering**: The processed data was then used to generate visual plots in two ways:
    *   **LabPlot Renders**: The clean data was imported into LabPlot, a powerful open-source data visualization tool, which was used to create detailed and accurate scientific plots.
    *   **Custom App Renders**: Another included C++ application is also equipped with its own plotting capabilities, allowing it to directly render the processed data into a plotted graphic.

## Sample Contents

This directory includes the following types of sample images:

-   **LabPlot Renders**: High-resolution plots generated using LabPlot. These showcase the clarity and precision achievable with dedicated scientific graphing software.
-   **Custom App Renders**: Graphics generated directly by a custom C++ data processing application. These samples demonstrate the capability of a streamlined, all-in-one tool for both data conversion and visualization.

## Printing Instructions

All images have been prepared and are ready to be printed using the "Lark" roll-feed printer. They are optimized for clarity and legibility, ensuring that the final printed output accurately represents the scientific data.

## Author

-   **hamslices**