# CTE Explorer

## Overview

CTE Explorer is a proof-of-concept tool that allows visual exploration of CTE based SQL scripts. 

The tool uses sqlglot to parse SQL scripts to derive directed acyclic graph (DAG) representation of CTE lineage

The DAG is created using d3.js

This tool is ideal for massive SQL scripts that leverages CTE's to perform a chain of enrichments and transformation

It provides a digestable visual representation of such scripts.

## Usage

### Viewing saved scripts
Select one of the saved models to view the CTE based SQL script and associated DAG

![cte_explorer_1](https://user-images.githubusercontent.com/98712501/171544249-dfd94af3-26a1-4dd3-af37-bec9aeabc2a1.jpg)

### Viewing individual CTE's in a script
Each node in the DAG represents one of the CTE's featured in the selected SQL script.
Clicking on a node within the DAG will display the SQL code for the CTE in the center text editor.
The column definitions will be featured below the center text editor 

![cte_explorer_2](https://user-images.githubusercontent.com/98712501/171544481-63a97b83-d656-4fea-908f-3cd39d77337c.jpg)

### Enter new script for analysis
- Click the button on the left labeled "New Code"
- Enter your new CTE base SQL script and press the button labeled "Parse" directly above the editor
- The sql file and corresponding json will be stored in static/model and will appear in list of Saved Models in the app

![cte_explorer_4](https://user-images.githubusercontent.com/98712501/171630292-3553e25c-46ab-4e17-972e-df1bfa88dbe4.jpg)

## Installation

1. Download this repo to your local machine\
2. Install requirement
```
pip install -r requirements.txt
```
3. launch app
```
py app.py
```

Access the app by going to http://127.0.0.1:5000/Home
