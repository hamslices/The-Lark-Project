# Welcome to the Lark Project

Hello and welcome! This repository serves as the central hub and landing page for the entire Lark project.

![alt text](https://github.com/hamslices/The-Lark-Project/blob/main/img/lark_advert_2.png?raw=true)

Lark is a comprehensive system designed for controlling the Fujitsu FTP-68EMCL112-R thermal printer, encompassing everything from custom hardware to a user-friendly graphical interface.

This central repository is also used to store project-wide assets, including invoices, photos, and other documentation related to the development of the Lark project.

## Project Motivation and Development

The driving force behind the Lark project has been a genuine passion for creating and a sense of excitement in building something new. It was born out of a specific need and a gap in the open-source community, where virtually no public repositories on GitHub offered a complete, end-to-end thermal printer solution that included both hardware and software designs. Furthermore, there was a personal requirement for a large-format thermal printer capable of continuous printing, rather than being limited to page-by-page jobs.

The development approach began with using as many off-the-shelf components as possible, like the PSU and print mechanism, allowing the focus to be on the custom controller board—the "brains" of the operation. A core philosophy was to design the simplest possible hardware without compromising on capability. To this end, KiCad was chosen for the PCB design due to its powerful, open-source, and free nature, which is perfectly suited for multi-layer board design.

With the goals of hand-assembly, cost-reduction, and usability at the forefront, many specific design choices were made. Most components are 0603 package size, the smallest that can be reasonably managed for hand-soldering. While alternative hardware designs were possible, this approach ensures the project remains accessible, affordable, and practical for creators.

A key feature of the Lark print engine is its intentional lack of external memory. This cost-saving measure created a significant advantage: the ability to print data streams as they are received, instead of buffering a full job in memory. This makes Lark perfectly suited for long, continuous printing tasks. It's also important to note that Lark does not use a conventional, and often messy, Windows print driver. Instead, it offers a clean Windows API for seamless integration into OEM software. While a traditional print driver may be a goal for the future, it is beyond the current scope of the project.

## Project Repositories

The Lark project is divided into several focused repositories. Each component is developed and maintained independently and contains its own detailed README, documentation, and license file.

*   ### **[Lark Hardware](https://github.com/hamslices/LarkHardware)**
    This repository contains all the hardware design files for the Lark controller PCB. The board is specifically designed to interface with and control the Fujitsu FTP-68EMCL112-R thermal printer mechanism. You will also find 3D CAD models for enclosures and other mechanical parts here.

*   ### **[Lark Firmware](https://github.com/hamslices/LarkFirmware)**
    Here you will find the source code for the firmware that runs on the Lark controller board. This is the core print engine that interprets commands and drives the printer mechanism.

*   ### **[Lark API](https://github.com/hamslices/LarkAPI)**
    This repository houses a C++ API for Windows. It provides a set of functions and libraries for developers to integrate and control the Lark print engine from their own Windows applications.

*   ### **[Lark Tool (CLI)](https://github.com/hamslices/LarkTool)**
    For those who prefer working from the command line, `lark_tool` is a powerful command-line interface (CLI) tool for interacting with and controlling the printer. It's perfect for scripting, testing, and automation.

*   ### **[Lark GUI](https://github.com/hamslices/LarkGUI)**
    This repository contains the graphical user interface (GUI) for the Lark printer. It provides a user-friendly, visual way to control the printer's functions without needing to write code or use the command line.

## Designer

All components of the Lark project were designed and developed by **HamSlices** in 2025, all rights reserved.

## Licenses and Contribution

Please note that each repository linked above contains its own specific license file and contribution guidelines. For more detailed information about a particular component, please refer to the README file within its respective repository.