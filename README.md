# Correlation Analysis
### Table Of Content
1. [Brief](#brief)  
    1.1 [Basic Usage](#basic-usage)  
    1.2 [Basic Structure](#basic-structure)  
    1.3 [Basic Functions Remarks](#basic-functions-remarks)
2. [General Function Use](#general-function-use)  
    2.1 [Description Vector](#description-vector)  
    2.2 [Standard Function Values](#standard-function-values)

### [Old Documentation](#old-documentation)
1. [Mouse](#mouse)  
    1.1 [Use](#use)  
    1.2 [Useful Functions](#useful-functions)  
    1.3 [Code Structure](#code-structure)  
2. [Mouse List](#mouse-list)  
    2.1 [Useful Functions](#useful-functions)  
    2.2 [Code Structure](#code-structure)  
3. [Other](#other)  
    3.1 [General](#general)  
    3.2 [Saving the Data](#saving-the-data)  

## Brief
This code was used to create some of statistic analysis figures for the following paper - https://biorxiv.org/cgi/content/short/2021.06.17.448649v1

### Basic Usage
In order to run the project, and after changing the path in the "ListOfMouseLists" and the "Mouse" files, one should run:
````matlab
loml = ListOfMouseLists() % Might take some time! Loads all the mice and lists into a struct of a ListOfMiceLists
````
Now, all the needed data is loaded, and one can start using the different functions.

### Basic Structure
The structure of the objects is so:
* **`ListOfMouseLists`** - The main object, and the only one that needs to be loaded. It holds all the different mouse lists.
    * **`MouseList`** - An Object that holds mice of the same kind (e.g. "OfcAcc", "AccInAccOut").
        * **`Mouse`** - An abstract class that isn't used directly. Each mouse type (OfcAcc, AccInAccOut, etc.) has its own class that inherits from this class. Each mouse is represented as an object of the correct mouse type.
        * **`AccInAccOutMouse`, `AudAccMouse`, `AudInAccOutMouse`, `AudInAudOutMose`, `OfcAccMouse`** - As mentioned above, these are the classes for each mouse type.

### Basic Functions Remarks
Each class in the hierarchy has functions that help analyze the relations within that class - Mouse functions allow one to inspect the data about a single mouse. MouseList functions let one analyze the data and compare mice of the same type (e.g. running functions on the mouselist "OfcAccMice" compares the different mice of type ofc-acc). ListsOfMouseLists allows one to analyze the differences and similarities between different types of mice.


## General Function Use
### Description Vector
Many functions take as input a description vector. This is a vector that describes the type of data to run the function on. 
There are three types of data - Task, Passive and Free. Each one has sub-options one should pass functions via the description vector:
* Task - The vector's shape should be `["Task", "divideBy"]`, where "dividedBy" means the type of activity the recording was cut by (lick, movement, onset, etc.). E.g. `["Task", "lick"]`.
* Passive - The vectors shape should be `["Passive", "state", "soundType", "time"]`, where the state is whether the mouse was awake or anesthetized, soundType is BBN or FS sound options, and time is pre or post-training. E.g. `["Passive", "state", "soundType", "time"]`.
* Free - The vector's shape should be `["Free", "divideBy", "time"]`, where divide by can be either concat (meaning the hole signal without division) or movement, and time means pre or post-training. E.g. `["Free", "movement", "pre"]`.

### Standard Function Values
After some calibration we have chosen to work with the following parameters - 
* **Smoothing** - 300 samples.
* **Downsample** - 10 samples.
* **Time window** - 1 seconde.
* **Time window shift** - 0.1 seconds.

*Note:* Before using 1 second time window we used 3 seconds time window. They were mostly similar, but taking a smaller time window "smoothed" the correlation less and we felt like it was able to capture small nuances better (although it catches more noise as well).


# Old Documentation
This documentation is still relevant but isn't updated with new functions and sections (e.g. listsOfMouseLists).

## Mouse

### Use
Notice that in a lot of functions a description vector is needed. It's built as so - 
- For Task signals ["Task", "divideBy"],
	- eg. ["Task", "lick"]
- For Passive signals ["Passive", "state", "soundType", "time"],
	- eg.  ["Passive", "awake", "BBN", "post"]

### Useful Functions
The most useful functions are the plot functions and are:
* plotAllSessions
* plotComparisonCorrelation
	* plotCorrelationScatterPlot
	* plotCorrelationBar
* plotSlidingCorrelation
* plotComparisonSlidingCorrelation
	* plotSlidingCorrelationHeatmap
	* plotSlidingCorrelationBar


Notice that every plot function has two parts:
 1. data - create the relevant data.
 2. draw
(except scatter plot that has only draw)

### Code Structure
* Methods
	* Constructor Functions
		* Main
		* Helpers
	* Plot
		* General
		* Correlation
		* Sliding Correlation
		* Helpers
			* get data
			* draw
	* General Helpers
	* Old
* Static Methods
	* Plot
		* Helpers

## Mouse List

### Useful functions
The most useful functions are the plot functions and are:
* plotCorrelationScatterPlot
* plotCorrelationBar
* plotSlidingCorrelationBar

### Code structure:

* Methods
	* Constructor and initialization
	* Plot
		* Plot
		* Helpers
* Static Methods
	* Plot
		* Helpers

## Other
### General
The proper way to use this program is first to create the wanted mice (mouse types are sub-classes of Mouse, look at Main for examples). By creating them they are automatically updated/added to the relevant mouseList (according to their type). Then, you can either use each mouse separately or use the mouseList to analyze all the mice (Both are saved in a path saved as a static property).

**NOTICE**: In order to use the mouse list, you need to load the list, and then use the mouseList.loadMice() function to load the mice themselves and not just their paths.

The relevant functions are under the "Plot" title (see elaboration in each section separately)

### Saving the Data
When parsed by me, passive has the following categories -

 1. State - awake/anesthetized
 2. Sound Type - BBN / FS
 3. Time - pre / post
These categories are used for the plots, and for the description vector.
