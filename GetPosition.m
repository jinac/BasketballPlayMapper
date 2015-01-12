% Multiple Player Tracking for Sports Applications
% 
% EE 368 Final Project - Spring 2012
% ------------------------------------------
% Michael Durate, John Inacay, Yuxiang (Jerry) Zhou
% -------------------------------------------

function template_position = GetPosition(Homography_matrix, frame_position)

% This function translates from the x,y position of an object from the frame 
% to an x,y position in the half_court template based on the Homography_matrix

% input Homography_matrix = [h11 h12 h13;
%							[h21 h22 h23];
% input frame_position = [x y]
% output template_position = [x' y']

	frame_position = [frame_position 1];
	template_position = Homography_matrix*transpose(frame_position);
	template_position = transpose(template_position);
end
