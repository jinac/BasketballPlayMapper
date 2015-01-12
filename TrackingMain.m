% Multiple Player Tracking for Sports Applications
% 
% EE 368 Final Project - Spring 2012
% ------------------------------------------
% Michael Durate, John Inacay, Yuxiang (Jerry) Zhou
% -------------------------------------------

clear
close all
clc

% Choose Clip #
% 1. Ohio vs Syracuse
% 2. Oregon vs Washington
VideoNum = 1; %2

% Show Intermediate Masks
ShowFigures = 0;

% Optimizing Constants
SetParams(VideoNum);

% Detection Algorithm
[team1_points, team2_points, Homography] = DetectPlayers(VideoNum, ShowFigures);

% 3-D to 2-D and Plotting
PlotPlayers(VideoNum, team1_points,team2_points, Homography);