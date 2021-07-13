## Table Of Content
1. [General](#general)  
    1.1 [Brief](#brief)  
    * [Basic Usage](#basic-usage)
    * [Basic Structure](#basic-structure)  


# GENERAL

## Brief
### Basic Usage
In order to run the project, and after changing the path in the "ListOfMouseLists" and the "Mouse" files, one should run:
````matlab
loml = ListOfMouseLists() % Might take some time! Loads all the the mice and lists into a struct of a ListOfMiceLists
````
Now, all the needed data is loaded, and one can start using the different functions.

### Basic Structure
The structure of the project is so:
* **ListOfMouseLists** - The main object, and the only one that needs to be loaded. It is an object that holds all the different mouse lists.
    * **MouseList** - An Object that holds mice of the same kind (e.g. "OfcAcc", "AccInAccOut").
        * **Mouse** - This is an abstract class, and isn't used directly. Each mouse type has a different class that inherits from this class (e.g. "OfcAccMouse"). Each mouse is represented with an object of the correct mouse type.





***

One can either use this object functions (to run functions that do analysis across all mice groups), or use `ListOfMouseLists.MouseList` to run a functoin 




The proper way to use this program is first to create the wanted mice (mouse types are sub-classes of Mouse, look at Main for examples). By creating them they are automatically updated / added to the relevant mouseList (according to their type). Then, you can either use each mouse separately, or use the mouseList to analyze all the mice (Both are saved in a path saved as a static property).

**NOTICE**: In order to use the mouse list, you need to load the list, and then use the mouseList.loadMice() function to load the mice themselves and not just their paths.

The relevant functions are under "Plot" title (see elaboration in each section separately)

## Saving the data
When parsed by me, passive has the following categories -

 1. State - awake / anesthetized
 2. Sound Type - BBN / FS
 3. Time - pre / post
these categories are used for the plots, and for the description vector.


# Mouse

## Use
Notice that in a lot of function a description vector is needed. It's built as so - 
- For Task signals ["Task", "divideBy"],
	- eg. ["Task", "lick"]
- For Passive signals ["Passive", "state", "soundType", "time"],
	- eg.  ["Passive", "awake", "BBN", "post"]

## Useful functions
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

## Code structure:
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

# Mouse List

## Useful functions
The most useful functions are the plot functions and are:
* plotCorrelationScatterPlot
* plotCorrelationBar
* plotSlidingCorrelationBar

## Code structure:

* Methods
	* Constructor and initialization
	* Plot
		* Plot
		* Helpers
* Static Methods
	* Plot
		* Helpers
