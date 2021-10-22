% Used To Create Mice - one doesn't need to run this, but only to run the load mice function as explained in the README

% SET PARAMETERS
clear
close all

%% 1 - CREATE MICE (AND SAVE)
OfcAccMouse("1_from406", false);
OfcAccMouse("2_from406", false);
OfcAccMouse("3_from406", true);
OfcAccMouse("6_from406", false);
OfcAccMouse("2_from430", false);

AudAccMouse("3_from410", true);
AudAccMouse("4_from410", true);
AudAccMouse("4_from410L", true);
AudAccMouse("3_from430", false);
AudAccMouse("4_from430", false);

AccInAccOutMouse("1_from500", false);
AccInAccOutMouse("2_from500", false);
AccInAccOutMouse("3_from500", false);

AudInAccOutMouse("1_from440", false);
AudInAccOutMouse("2_from440", false);
AudInAccOutMouse("3_from440", false);

AudInAudOutMouse("4_from440", false);

%% 2 - LOAD ALL LISTS AND MICE - Not useful if using ListsOfMouseList (it does the same thing)
OfcAcc = load('W:\shared\Timna\Gal Projects\Mouse Lists\OfcAccMice.mat').obj;
AudAcc = load('W:\shared\Timna\Gal Projects\Mouse Lists\AudAccMice.mat').obj;
AccInAccOut = load('W:\shared\Timna\Gal Projects\Mouse Lists\AccInAccOutMice.mat').obj;
AudInAccOut = load('W:\shared\Timna\Gal Projects\Mouse Lists\AudInAccOutMice.mat').obj;
AudInAudOut = load('W:\shared\Timna\Gal Projects\Mouse Lists\AudInAudOutMice.mat').obj;

AccInAccOut.loadMice()
AudAcc.loadMice()
AudInAccOut.loadMice()
AudInAudOut.loadMice()
OfcAcc.loadMice()
