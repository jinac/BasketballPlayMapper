% Multiple Player Tracking for Sports Applications
% 
% EE 368 Final Project - Spring 2012
% ------------------------------------------
% Michael Durate, John Inacay, Yuxiang (Jerry) Zhou
% -------------------------------------------

function X = BoxCorners(is_left_court, m_side, b_side, m_top, b_top, m_bottom, b_bottom, m_paint, b_paint)

% Given the slope and constant terms of the lane's lines, this function determines the corners of the lane 
% and puts them in the correct order in X for determining the Homography Matrix in function CourtPosition

% orders the slopes and constants in vectors
	slope_h = [m_top m_bottom];
	b_h = [b_top b_bottom];
	if is_left_court
		slope_v = [m_side m_paint];
		b_v = [b_side b_paint];
	else
		slope_v = [m_paint m_side];
		b_v = [b_paint b_side];
	end

	% P1 = top right
	% P2 = bottom right
	% P3 = bottom left
	% P4 = top left


	% Find 4 Corner of the alne
	x = (b_h(2)-b_v(2))./(slope_v(2)-slope_h(2));
	P1 = [x slope_h(2).*x+b_h(2)];

	x = (b_h(1)-b_v(2))./(slope_v(2)-slope_h(1));
	P2 = [x slope_h(1).*x+b_h(1)];

	x = (b_h(1)-b_v(1))./(slope_v(1)-slope_h(1));
	P3 = [x slope_h(1).*x+b_h(1)];

	x = (b_h(2)-b_v(1))./(slope_v(1)-slope_h(2));
	P4 = [x slope_h(2).*x+b_h(2)];

	% Returns correct X depending on side of court
	if is_left_court
		X = [P1 1;
		     P2 1;
		     P3 1;
		     P4 1];
	else %is right court
		X = [P3 1;
		     P4 1;
		     P1 1;
		     P2 1];
	end

end
