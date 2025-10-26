# Welcome to the Lark Project

Hello and welcome! This repository serves as the central hub and landing page for the entire Lark project. 

![alt text](https://github.com/hamslices/The-Lark-Project/blob/main/img/lark_advert_2.png?raw=true)

Lark is a comprehensive system designed for controlling the Fujitsu FTP-68EMCL112-R thermal printer, encompassing everything from custom hardware to a user-friendly graphical interface.

This central repository is also used to store project-wide assets, including invoices, photos, and other documentation related to the development of the Lark project.

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