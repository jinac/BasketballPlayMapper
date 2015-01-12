% Multiple Player Tracking for Sports Applications
% 
% EE 368 Final Project - Spring 2012
% ------------------------------------------
% Michael Durate, John Inacay, Yuxiang (Jerry) Zhou
% -------------------------------------------

function [ ] = SetParams( VideoNum )

% Set Params - sets optimizing constants
%
% The values were determined by inspecting image values in YCBCR and HSV
% space. The same values apply to the entire duration of the same game.

% Frames
global FIRST LAST

% Court Extraction
global PAINT_MIN PAINT_MAX COURT_MIN COURT_MAX;

% Court Line Extraction
global MAX_DISTANCE_FROM_SIDE MAX_ANGLE_VERTICAL MIN_ANGLE_VERTICAL

% Paint Extraction
global MIN_ANGLE MAX_ANGLE MAX_DISTANCE_FROM_SIDELINE

% Jersey Extraction
global MIN_team1 MAX_team1 MINV_team1 MAXV_team1
global MIN_team2 MAX_team2
global team1_k

% Jersey filtering
global MIN_AREA1 MIN_AREA1_team1 MIN_AREA1_team2
global MIN_AREA2 MIN_DIFF MIN_SOLIDITY
global MIN_SOLIDITY2_team1 MIN_SOLIDITY2_team2

if VideoNum == 1 % Ohio vs Syracuse (red, white jerseys)
    
    FIRST = 16; %Default 16
    LAST = 120; %Default 120
    
   % Court detection
    PAINT_MIN = 125; PAINT_MAX = 160;
    
    COURT_MIN = 85; COURT_MAX = 108;
    
    % Court line detection
    MAX_DISTANCE_FROM_SIDE = 1/5;
    MAX_ANGLE_VERTICAL = 70;
    MIN_ANGLE_VERTICAL = 40;
    
    % Paint detection
    MIN_ANGLE = 10; MAX_ANGLE = 10;
    MAX_DISTANCE_FROM_SIDELINE = 0;
    
    % Jersey detection
    MIN_team1 = .8; MAX_team1 = 1;
    MINV_team1 = 1; MAXV_team1 = 1;
    MIN_team2 = 0; MAX_team2 = .24;
    team1_k = 3;
    
    % Jersey filters
    MIN_AREA1 = 0;
    MIN_AREA1_team1 = 200; MIN_AREA1_team2 = 250;
    MIN_AREA2 = 0;
    MIN_DIFF = 0;
    MIN_SOLIDITY = 0;
    MIN_SOLIDITY2_team1 = 0;
    MIN_SOLIDITY2_team2 = 0;
    
else             % Oregon vs Washington (black, white jerseys)
    FIRST = 1; %Default 1
    LAST = 85; %Default 85
    
    % Court detection
    PAINT_MIN = 150; PAINT_MAX = 170;
    
    COURT_MIN = 85; COURT_MAX = 120;
    
    % Court line detection
    MAX_DISTANCE_FROM_SIDE = 1/3;
    MAX_ANGLE_VERTICAL = 75;
    MIN_ANGLE_VERTICAL = 50;
    
    % Paint detection
    MIN_ANGLE = 15; MAX_ANGLE = 0;
    MAX_DISTANCE_FROM_SIDELINE = 3/10;
    
    % Jersey detection
    MIN_team1 = 1; MAX_team1 = 1;
    MINV_team1 = .1; MAXV_team1 = .2;
    MIN_team2 = .05; MAX_team2 = .2;
    team1_k = 3;
    
    % Jersey filters
    MIN_AREA1 = 100;
    MIN_AREA1_team1 = 100; MIN_AREA1_team2 = 150;
    MIN_AREA2 = 250;
    MIN_DIFF = 70;
    MIN_SOLIDITY = .4;
    MIN_SOLIDITY2_team1 = .8;
    MIN_SOLIDITY2_team2 = .4;

end


end

