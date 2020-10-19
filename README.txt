%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% GENERAL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Passive has the following categories -
    1. State - awake / anesthetized
    2. Sound Type - BBN / FS
    3. Time - pre / post
these categories are used for the plots, and for the description vector.

The description vector is built as so - 
For Task signals ["Task", "divideBy"], for example ["Task", "lick"]
For Passive signals ["Passive", "state", "soundType", "time"], for example ["Passive", "awake", "BBN", "post"]



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Mouse %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
This is the structor of the code:
* Methods *
    Constructor Functions
        Main
        Helpers

    Plot
        General
        Correlation
        Sliding Correlation
        Helpers
            get data
            draw

    General Helpers
    Old

* Static Methods *
    Plot
        Helpers

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Mouse List %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Mouse List

Documentation writes if it is an important function or not

Plot - all has data + draw (except scatter plot that has only draw)

Hirarchy of the functions:
