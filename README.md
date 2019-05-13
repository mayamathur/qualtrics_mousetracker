
## Overview

This repository contains an open-source pipeline to collect and analyze mouse-tracking data in Qualtrics, along with data and materials from the validation study. See the following citation for details:

> Mathur MB & Reichling D (in press). Open-source software for mouse-tracking in Qualtrics to measure category competition. *Behavior Research Methods.* Preprint: [https://osf.io/ymxau](https://osf.io/ymxau).

A live demo version of the questionnaire used in the validation study [is available here](https://stanforduniversity.qualtrics.com/jfe/form/SV_6WsoglnHLBUA2YB). The code is version-controlled [via Github](https://github.com/mayamathur/qualtrics_mousetracker). 


## How to use the software to design a category-competition experiment

What follows is an abbreviated version of the instructions in the preprint, [Mathur & Reichling (in press)](https://osf.io/ymxau). The user is urged to read that paper before implementation in order to fully understand the software. 

1. Download [the template Qualtrics questionnaire](https://osf.io/jm4kc/) and import it into Qualtrics. The template by default implements [Mathur & Reichling (in press)](https://osf.io/ymxau)'s validation study with robot faces. The key feature is a "block" that presents the stimuli sequentially via Qualtrics' "Loop & Merge" feature; other blocks in the survey can be added or removed as needed. Simply edit the image URLs in the Loop & Merge through the Qualtrics interface to replace the default stimuli. You can edit other blocks if you would like, but we do not recommend allowing subjects to skip categorization questions; the R code provided here is not currently designed to handle this case (it will exclude all subjects who skip questions), so you would have to modify the code if you want to allow subjects to skip questions.

2. In Qualtrics, click on the "JS" (Javascript) icon in the training block. Edit the parameters `howManyPracticesImages` and `howManyRealImages` to match the number of stimuli you have in the training block and the main ("Categorize faces") block. If desired, edit the other timing parameters (described in [Mathur & Reichling (in press)](https://osf.io/ymxau)).

3. Collect data as usual through Qualtrics. 

4. Download the raw Qualtrics dataset. Run [the data prep R script](https://osf.io/xb8cq/) to check for subjects who should probably be excluded, to parse the coordinate data, and to return the dataset in an analysis-friendly long format (1 row per trial). 

5. You can now analyze the data as desired. We provide [an analysis R script](https://osf.io/pbe4r/) as an example of how we analyzed the data in the validation study, but this will of course depend on the research questions. Note that we recommend adjusting in analysis for main effects of the variables `weird.scaling` and `wts` as well as their interactions with the independent variable of interest (see [Mathur & Reichling (in press)](https://osf.io/ymxau)).


## Troubleshooting

*I changed something in the Look & Feel menu, and now the format is messed up (e.g., the buttons are no longer centered).*

Open the Look & Feel menu and click the link in bottom left side labeled "Back to the Old Editor". Make sure all your settings match those in the screenshots in the directory "Look and Feel settings" in this OSF repository. Note an annoying feature of Qualtrics is that you must then save the settings from the old editor; if you first return to the new editor, it will override the settings.

*When I run `make_url_key()`, the URLs are missing in the resulting key.*

Make sure you haven't renamed any variables in the raw data from Qualtrics or deleted any of the extra header rows that Qualtrics automatically includes. These extra rows contain information about the Loop & Merge iterate ID, which `make_url_key()` needs to use. Also, if you renamed the variable `cat` in the categorization block in Qualtrics, make sure you pass the correct variable as an argument to `make_url_key()`.

*I changed some of the Qualtrics variable labels (e.g., I renamed the "cat" category decision variable), and the R analysis code is hitting errors. (Or: I need use a different ID variable other than the Qualtrics default "ResponseId".)*

Simply do a Find & Replace of the relevant variable name in the file `general_helper.R`.

*I opened the raw Qualtrics dataset in Excel, and the data format looks bizarre. There are really long strings of numbers and the character "a" that are running through multiple cells, and each subject seems to have multiple rows.*

Don't worry! This occurs because Excel has limits on the maximum number of characters per cell, and if you have many stimuli in the Loop & Merge, it's possible that the mouse-tracking data strings exceed these limits. This is not a problem for the R data prep and analysis code because the data will be read in as a .csv file, which has no limits on characters per entry. If you decide to analyze the data from scratch rather than using the provided R scripts, keep in mind that you should read in the data as a .csv instead of from Excel for this reason. 

## What is the code doing under the hood?

As an example of what happens under the hood when running the code to parse the mouse-tracking data, see [uv3_code_self_audit.R](https://osf.io/9574n/), where we "manually" parse the cursor data for a single subject and face, showing how we arrive at exactly the same results as the code provided here. 


## Software updates and bug fixes

2019-5-13: Generalized `general_helper.R` to accommodate Qualtrics surveys with multiple blocks of stimuli. 

2018-12-8: Generalized `data_prep.R` code for excluding subjects with missing cells to accommodate questionnaires not ending with the default demographics block. 

2018-11-21: Updated CSS to ensure fixed distance between radio buttons. 

## How to reproduce the validation study

The validation study used [the template Qualtrics questionnaire](https://osf.io/jm4kc/) and the same R scripts linked above. Additional materials, such as the stimuli, are in the "Validation study" directory.  




