% SET PARAMETERS
clear
close all

%% 1 - CREATE MICE (AND SAVE)
OfcAccMouse("1_from406", false);
OfcAccMouse("2_from406", false);
OfcAccMouse("3_from406", true);
OfcAccMouse("6_from406", false);
OfcAccMouse("2_from430", false);

AudAccMouse("3_from410", false);
AudAccMouse("4_from410", false);
AudAccMouse("4_from410L", false);
AudAccMouse("3_from430", false);
AudAccMouse("4_from430", false);

AccInAccOutMouse("1_from500", false);
AccInAccOutMouse("2_from500", false);
AccInAccOutMouse("3_from500", false);

AudInAccOutMouse("1_from440", false);
AudInAccOutMouse("2_from440", false);
AudInAccOutMouse("3_from440", false);

AudInAudOutMouse("4_from440", false);