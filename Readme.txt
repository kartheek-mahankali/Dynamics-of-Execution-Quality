This Readme file will give the sequence of steps to be followed to analyse the dynamics of order execution quality.

1. Download the project folder (Project_DEQ) from GitHub. For Example, downlaod the folder into C drive such that the project directory is C:/Project_DEQ

2. Open config.yml and provide input values according to the description given in the file

3. As of July 2023, the code supports automatic downlaod SEC Rule 605 filings for market centers - CITADEL Securities, Virtu Americas, Jane Street. So, if you wish to include these market centers in your analysis, please run download_rule605_filings.R file

4. For any other market centers, use the URLs provided in ./data/constituent_data/mcid.csv file to manually download the SEC Rule 605 filings at ./data/f605_data/<mcid>_Rule605Files, where <mcid> is the four letter market center ID.

5. Make sure you have all the required SEC Rule 605 files in ./data/f605_data directory under individual sub directories for each market center. The project folder uplaoded in the GitHub, by default will have no test data. Hence, user must either run download_rule605_filings.R or manually download the files.

6. Make sure you have MiKTeX installed in your system, as this project uses LaTeX to compile the report in PDF Format.

7. Open DEQ_ProjectReport.Rmd and click on "Knit to PDF".

Below are the version details:

R version 4.3.0 (2023-04-21 ucrt)
Platform: x86_64-w64-mingw32/x64 (64-bit)
Running under: Windows 11 x64 (build 22621)

