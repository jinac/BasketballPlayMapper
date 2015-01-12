% Multiple Player Tracking for Sports Applications
% 
% EE 368 Final Project - Spring 2012
% ------------------------------------------
% Michael Durate, John Inacay, Yuxiang (Jerry) Zhou
% -------------------------------------------

function Homography_matrix = CourtPosition(X)

% This function generates a homography function H that estimates the
% projection of a position in image_court onto court_template
% The points from the half court template were manually found:
% left free throw = (412, 464)
% right free throw = (694, 464)
% right base = (694, 797)
% left base = (412, 797)
%
% input X = matrix containing corresponding points of corners of court template

% Template points
Y = [412 464 1;
     694 464 1;
     694 797 1; 
     412 797 1];

% Finds Homography transform row vectors
H1 = pinv(X)*Y(:,1);
H2 = pinv(X)*Y(:,2);

H = [transpose(H1); transpose(H2)];
Homography_matrix = H;

end
