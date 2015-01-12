% Multiple Player Tracking for Sports Applications
% 
% EE 368 Final Project - Spring 2012
% ------------------------------------------
% Michael Durate, John Inacay, Yuxiang (Jerry) Zhou
% -------------------------------------------

function [ ] = PlotPlayers(VideoNum, team1_points, team2_points, Homography )
% PlotPlayers - plots players in 2-D given their locations and homography
% matrix
% 
% % Inputs - VideoNum: 1 or 2 based on which clip is chosen
%            team1_points: t by 2 matrix of [x,y] location of each player
%            from team 1
%            team2_points: t by 2 matrix of [x,y] location of each player
%            from team 2
%            Homography: t by 2 by 3 matrix of the transform used to go
%            from 3-D camera view to 2-D template view     
%
% Centroid values from player detection are used. A prediction algorithmn
% is used when a distant value, or no value is found around the expected
% locations.
% Different teams are plotted in different colors, green represents the
% starting point and red represents the end point of each player.

global FIRST LAST

clear team1_loc

% Extract x and y coordinates from result of player detection
% beginning at t = 1. Limit number of players tracked to those
% found in the first frame.
x_coords = team1_points(1,:,1);
y_coords = team1_points(1,:,2);
team1_loc(1,:,1) = x_coords(x_coords~=0);
team1_loc(1,:,2) = y_coords(y_coords~=0);
team1_loc(1,:,3) = 0;
team1_loc(1,:,4) = 0;
team1_loc(1,:,5) = 0;
s2=size(team1_loc);
num_players = s2(2);

if VideoNum==1
    MAX_DELTA = 70; % Max value to search for surrounding points
else
    MAX_DELTA = 40;
end
DELTA_NORMAL = 7; % Upper limit of normal velocity between frames

% Tracking Algorithmn

for num_frame = 2:(LAST-FIRST+1)
    new_xs = team1_points(num_frame,:,1);
    new_xs = new_xs(new_xs~=0);
    new_ys = team1_points(num_frame,:,2);
    new_ys = new_ys(new_ys~=0);
    
    % DEFAULT all players remain at the same location
    team1_loc(num_frame,:,:) = team1_loc(num_frame-1,:,:);
    
    % Iterate through all expected players
    for n2 = 1:num_players
     
        old_x = team1_loc(num_frame-1,n2,1);
        old_y = team1_loc(num_frame-1,n2,2);
        clear distances
        distances(1,:) = [0 0 -1]; %make sure array always exists, set dummy value of -1
       
        % Iterate through all new detected points
        for n1 = 1:length(new_xs)
            new_x = new_xs(n1);
            new_y = new_ys(n1);
            
            if (sqrt((new_x-old_x)^2+(new_y-old_y)^2) ) < MAX_DELTA

                distances = vertcat(distances,[new_x,new_y,sqrt((new_x-old_x)^2+(new_y-old_y)^2)]);
            end                     

        end
        % Sort all detected points by distance to previous location
        distances = sort(distances,3);

        s=size(distances);
        if s(1) > 1 % at least 1 was found within MAX DISTANCE
            
            if distances(2,3) <= DELTA_NORMAL % the closest point is within a small distance - no jump
                team1_loc(num_frame,n2,1) = distances(2,1); %new x
                team1_loc(num_frame,n2,2) = distances(2,2); %new y
                team1_loc(num_frame,n2,3) = distances(2,1)-old_x; %new x velocity
                team1_loc(num_frame,n2,4) = distances(2,2)-old_y; %new y velocity
                team1_loc(num_frame,n2,5) = 0; % a real match is found, reset # of frames without match to 0
            else % closest point is a jump (occlusion occuring) - go slowly to new target
                
                team1_loc(num_frame,n2,1) = old_x + sign(distances(2,1)-old_x)*abs(team1_loc(num_frame-1,n2,3)) + (distances(2,1)-old_x)/15; %new x is old x + old velocity in direction of new + small distance to eventauly get to new
                team1_loc(num_frame,n2,2) = old_y + sign(distances(2,2)-old_y)*abs(team1_loc(num_frame-1,n2,4)) + (distances(2,2)-old_y)/15; %new y
                team1_loc(num_frame,n2,3) = team1_loc(num_frame-1,n2,3); %preserve velocity
                team1_loc(num_frame,n2,4) = team1_loc(num_frame-1,n2,4);
                team1_loc(num_frame,n2,5) = 0; % a real match is found, reset # of frames without match to 0
            end
        else % no close points, predict new location based on previous velocity
            team1_loc(num_frame,n2,1) = old_x+team1_loc(num_frame-1,n2,3); %new x - assume same velocity
            team1_loc(num_frame,n2,2) = old_y+team1_loc(num_frame-1,n2,4);
            team1_loc(num_frame,n2,3) = team1_loc(num_frame-1,n2,3); %preserve velocity
            team1_loc(num_frame,n2,4) = team1_loc(num_frame-1,n2,4); %
            team1_loc(num_frame,n2,5) = team1_loc(num_frame-1,n2,5)+1; % # of frames without a match ++
        end
    end
              
end

% For each player, if the final # of frames without a match gets too high,
% then revert to the last known location.
for n2 = 1:num_players
    guessed_frames = team1_loc(LAST-FIRST+1,n2,5);
    if guessed_frames > 10
        for revert = LAST-FIRST+1-guessed_frames:LAST-FIRST+1
            team1_loc(revert,n2,:) = team1_loc(LAST-FIRST+1-guessed_frames,n2,:);
        end
    end
end

%Transforming from 3-D camera vew to 2-D template location
clear team1_hloc
for num_frame = 1:LAST-FIRST
    for n = 1:num_players
        x=team1_loc(num_frame,n,1);
        y=team1_loc(num_frame,n,2)+25;
        if VideoNum==1
            [xy] = GetPosition(reshape(Homography(num_frame,1:2,1:3),2,3),[x, y]);
        else
            [xy] = GetPosition(reshape(Homography(1,1:2,1:3),2,3),[x, y]);
        end
         if xy(2) > 780
            xy(1) = team1_hloc(num_frame-1,n,1);
            xy(2) = team1_hloc(num_frame-1,n,2);
        end
        team1_hloc(num_frame,n,1) = xy(1);
        team1_hloc(num_frame,n,2) = xy(2);
    end
end

% Smoothing filter for player trajectory
for n = 1:num_players
    team1_hloc(:,n,1) = smooth(team1_hloc(:,n,1),50);
    team1_hloc(:,n,2) = smooth(team1_hloc(:,n,2),50);
end


% Plotting on the template for team 1
figure
imshow('half_court.jpg');
hold on

% Time lapse display
for n = 1:num_players
    plot(team1_hloc(1,n,1),team1_hloc(1,n,2),'og','LineWidth',4,'MarkerFaceColor','g');
end
for t = 2:1:LAST-FIRST-1
    for n = 1 :num_players

    
    plot([team1_hloc(t,n,1),team1_hloc(t-1,n,1)],[team1_hloc(t,n,2),team1_hloc(t-1,n,2)],'-m','LineWidth',1.5);
    
    end
    pause(.02)

end
for n = 1:num_players
    plot(team1_hloc(LAST-FIRST,n,1),team1_hloc(LAST-FIRST,n,2),'or','LineWidth',4,'MarkerFaceColor','r');
end

pause(1);

% Repeat same tracking algorithmn for team 2
clear team2_loc
x_coords = team2_points(1,:,1);
y_coords = team2_points(1,:,2);
team2_loc(1,:,1) = x_coords(x_coords~=0); %x loc
team2_loc(1,:,2) = y_coords(y_coords~=0); %y loc
team2_loc(1,:,3) = 0; %x velocity
team2_loc(1,:,4) = 0; %y velocity
team2_loc(1,:,5) = 0; %# of frames not found, resets every time one is found
s2=size(team2_loc);
num_players = s2(2);

if VideoNum==1
    MAX_DELTA = 70;
else
    MAX_DELTA = 40;
end
DELTA_NORMAL = 7; %7

for num_frame = 2:(LAST-FIRST)
    new_xs = team2_points(num_frame,:,1);
    new_xs = new_xs(new_xs~=0);
    new_ys = team2_points(num_frame,:,2);
    new_ys = new_ys(new_ys~=0);
    
    %DEFAULT all players remain at the same location
    team2_loc(num_frame,:,:) = team2_loc(num_frame-1,:,:);
    
    
    for n2 = 1:num_players
     
        old_x = team2_loc(num_frame-1,n2,1);
        old_y = team2_loc(num_frame-1,n2,2);
        clear distances
        distances(1,:) = [0 0 -1]; %make sure array always exists, set dummy value of -1
       
        for n1 = 1:length(new_xs)
            new_x = new_xs(n1);
            new_y = new_ys(n1);
            
            if (sqrt((new_x-old_x)^2+(new_y-old_y)^2) ) < MAX_DELTA

                distances = vertcat(distances,[new_x,new_y,sqrt((new_x-old_x)^2+(new_y-old_y)^2)]);
            end                     

        end
        distances = sort(distances,3);

        s=size(distances);
        if s(1) > 1 % at least 1 point is found
         
            
            if distances(2,3) <= DELTA_NORMAL % the closest point is normal - no jump
                team2_loc(num_frame,n2,1) = distances(2,1); %new x
                team2_loc(num_frame,n2,2) = distances(2,2); %new y
                team2_loc(num_frame,n2,3) = distances(2,1)-old_x; %new x velocity
                team2_loc(num_frame,n2,4) = distances(2,2)-old_y; %new y velocity
                team2_loc(num_frame,n2,5) = 0; % # of frames without a match ++
            else %closest point is a jump - go slowly to new target
                team2_loc(num_frame,n2,1) = old_x + sign(distances(2,1)-old_x)*abs(team2_loc(num_frame-1,n2,3)) + (distances(2,1)-old_x)/15; %new x is old x + old velocity in direction of new + small distance to eventauly get to new
                team2_loc(num_frame,n2,2) = old_y + sign(distances(2,2)-old_y)*abs(team2_loc(num_frame-1,n2,4)) + (distances(2,2)-old_y)/15; %new y
                team2_loc(num_frame,n2,3) = team2_loc(num_frame-1,n2,3); %preserve velocity
                team2_loc(num_frame,n2,4) = team2_loc(num_frame-1,n2,4);
                team2_loc(num_frame,n2,5) = 0; % # of frames without a match ++
            end
        else %no close points, guess a new location based on previous velocity
         
                team2_loc(num_frame,n2,1) = old_x+team2_loc(num_frame-1,n2,3); %new x - assume same velocity
                team2_loc(num_frame,n2,2) = old_y+team2_loc(num_frame-1,n2,4);
                team2_loc(num_frame,n2,3) = team2_loc(num_frame-1,n2,3); %preserve velocity
                team2_loc(num_frame,n2,4) = team2_loc(num_frame-1,n2,4);
                team2_loc(num_frame,n2,5) = team2_loc(num_frame-1,n2,5)+1; % # of frames without a match ++
        end
    end
              
end

for n2 = 1:num_players
    guessed_frames = team2_loc(LAST-FIRST,n2,5);
    if guessed_frames > 10
        for revert = LAST-FIRST+1-guessed_frames:LAST-FIRST
            team2_loc(revert,n2,:) = team2_loc(LAST-FIRST-guessed_frames,n2,:);
        end
    end
end


%Transforming
clear team2_hloc
for num_frame = 1:LAST-FIRST
    for n = 1:num_players
        x=team2_loc(num_frame,n,1);
        y=team2_loc(num_frame,n,2)+25;
        if VideoNum==1
            [xy] = GetPosition(reshape(Homography(num_frame,1:2,1:3),2,3),[x, y]); 
        else
            [xy] = GetPosition(reshape(Homography(1,1:2,1:3),2,3),[x, y]); 
        end
        if xy(2) > 780
            xy(1) = team2_hloc(num_frame-1,n,1);
            xy(2) = team2_hloc(num_frame-1,n,2);
        end
        team2_hloc(num_frame,n,1) = xy(1);
        team2_hloc(num_frame,n,2) = xy(2);
    end
end

for n = 1:num_players
    team2_hloc(:,n,1) = smooth(team2_hloc(:,n,1),50);
    team2_hloc(:,n,2) = smooth(team2_hloc(:,n,2),50);
end


% Plotting on template
for n = 1:num_players
    plot(team2_hloc(1,n,1),team2_hloc(1,n,2),'og','LineWidth',4,'MarkerFaceColor','g');
end



for t = 2:1:LAST-FIRST-1
    for n = 1 :num_players

    
    plot([team2_hloc(t,n,1),team2_hloc(t-1,n,1)],[team2_hloc(t,n,2),team2_hloc(t-1,n,2)],'-b','LineWidth',1.5);
    
    end
    pause(.02)

end
for n = 1:num_players
    plot(team2_hloc(LAST-FIRST,n,1),team2_hloc(LAST-FIRST,n,2),'or','LineWidth',4,'MarkerFaceColor','r');
end

end

