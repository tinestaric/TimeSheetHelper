# TimeSheet Helper - Copilot Feature

## Overview

The TimeSheet Helper extension for Business Central provides an AI-powered copilot feature that makes time tracking easier and more efficient. The copilot allows users to enter unstructured text describing how they spent their time, and the AI will parse this into structured timesheet entries automatically.

## Features

- **Natural Language Time Entry**: Enter your time in natural language, such as "Spent 2 hours on project planning meeting, 3 hours on coding the new feature, and 1 hour answering emails."
- **AI-Powered Parsing**: The copilot parses your text and extracts relevant information such as projects, tasks, hours spent, and dates.
- **Automatic Timesheet Creation**: The parsed information is automatically converted into timesheet line entries.

## How to Use

1. Open a timesheet card in Business Central.
2. Click on the "Copilot Time Entry" action in the Processing group.
3. In the dialog that appears, enter a description of how you spent your time.
4. Click the "Generate Entries" button.
5. The copilot will analyze your text and generate timesheet entries accordingly.

## Example Description

```
Spent 2 hours in the morning on the TimeSheet Helper project planning meeting.
After lunch, I worked for 3.5 hours on coding the new feature for the Marketing project.
Also spent 30 minutes answering client emails for the Support task.
Yesterday I spent 4 hours on design work for the website project.
```

## Technical Information

This extension adds the following objects to Business Central:

- Page Extension 50101 "TimeSheet Card Ext" extending "TimeSheet Card"
- Page 50102 "TimeSheet Copilot Dialog"
- Codeunit 50103 "TimeSheet Copilot"
- Additionally, it includes mock tables, pages, and enums for demonstration purposes

## Requirements

- Business Central 26.0 or later 