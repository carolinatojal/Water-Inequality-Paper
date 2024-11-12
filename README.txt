# Instructions for Replication

## Paper
**Title:** Water Expenditure, Service Quality, and Inequality in Latin America and the Caribbean  
**Authors:** Mara Perez-Urdiales and Carolina Tojal R. dos Santos  

## Data
The paper uses data from the *AmericasBarometer* of the *Latin American Opinion Project (LAPOP)* from Vanderbilt University for 2021.

### Steps to Access the Data
1. Visit the [AmericasBarometer Database](http://datasets.americasbarometer.org/database/).
2. Select the year **2021** and download the file titled **"Merged_LAPOP_AmericasBarometer_2021_v1.2_w"**.
3. You’ll need to accept the website’s terms of use to access the download.

After downloading, rename the file to `LAPOP_2021.dta` and place it in a `Data` folder within this repository.

## Code
The analysis is conducted using Stata.

- **`Master.do`**: This master do-file orchestrates the replication by calling the following scripts:
  - **Income_imputation.do**: Prepares the data and imputs continous demand variable 
  - **SummaryStats**: Generates the summary statistics for the analysis.
  - **Concentration_Index**: Computes the indexes
  - **Graphs_concentration**: Generate concentration graphs

## How to Run
1. Ensure you have the `LAPOP_2021.dta` file in a `Data` folder.
2. Open Stata and run the `Master.do` file, which will execute the complete analysis workflow as described in the paper.

---

This repository enables you to replicate the results shown in the paper, following the above steps for data download and code execution.