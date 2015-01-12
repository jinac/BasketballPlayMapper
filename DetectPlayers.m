% Multiple Player Tracking for Sports Applications
% 
% EE 368 Final Project - Spring 2012
% ------------------------------------------
% Michael Durate, John Inacay, Yuxiang (Jerry) Zhou
% -------------------------------------------

function [ team1_points, team2_points, Homography ] = DetectPlayers(VideoNum, show_figs )
% Detect Players - attempts to retrieve x y locations of players in each
% frame as well as the homography transform matrix in each frame.
%   
% Inputs - VideoNum: 1 or 2 based on which clip is chosen
%          show_figs: Show intermediate figures
%       
% Outputs - team1_points: t by 2 vector containing x, y locations of
%           players on team 1. t is the total # of frames
%           team2_points: t by 2 vector containing x, y locations of
%           players on team 2.
%
% Using dominant color and region property filtering techniques, the court
% region, paint lines, and player locations are detected.

% Declare global constants, these have been set in SetParams
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

% Load Video

VideoNames = {'Ohio1.avi','OregonL1.avi'};

obj = VideoReader(VideoNames{VideoNum});
working = 1;

% Detect players in each frame
for frame_num = FIRST:1:LAST

    currFrame = read(obj,frame_num);
    frame = currFrame(75:505,1:718,:);
    
    % Grayscale and YCBCR version
    gray = double(rgb2gray(frame));
    ycbcr = rgb2ycbcr(frame);
    s=size(gray);

    ycbcr_y = ycbcr(:,:,1);
    ycbcr_cb = ycbcr(:,:,2);
    ycbcr_cr = ycbcr(:,:,3);
    
    
    % Paint Mask
    paint_mask_unfiltered = ycbcr_cb > PAINT_MIN & ycbcr_cb < PAINT_MAX;
 
    
    % Filter paint mask by mininum area and extremal location
    paint_mask = paint_mask_unfiltered; 
    imgLabel = bwlabel(paint_mask);
    shapeProps = regionprops(imgLabel, 'Centroid', 'Area');
    for nRegion = 1:length(shapeProps)
        idx = find(imgLabel == nRegion);
        centroid = shapeProps(nRegion).Centroid;
        area = shapeProps(nRegion).Area;
        if (centroid(1) < s(2)/7 || centroid(2) < s(1)/3 || centroid(2) > 4*s(1)/5) || area < 400
            paint_mask(idx) = 0;
        end
    end

    % Court Region Mask
    court = (ycbcr_cb > COURT_MIN & ycbcr_cb < COURT_MAX);

    if show_figs
    figure
    imshow(court)
    title('court')
    end

    % Filter court mask by mininum area
    imgLabel = bwlabel(court);
    shapeProps = regionprops(imgLabel, 'Area');
    for nRegion = 1:length(shapeProps)
        idx = find(imgLabel == nRegion);
        area = shapeProps(nRegion).Area;
        if (area < 2500)
           court(idx) = 0;
        end
    end

    % Filter the inverse of the court mask in order to remove regions that are
    % wider than they are tall. Since players generally taller than they are
    % wide, this filters out some of the logos and glare on the court
    court = ~court;
    imgLabel = bwlabel(court);
    shapeProps = regionprops(imgLabel, 'Area','BoundingBox');
    for nRegion = 1:length(shapeProps)
        idx = find(imgLabel == nRegion);
        box = shapeProps(nRegion).BoundingBox; % [xpos ypos width height]
        area = shapeProps(nRegion).Area;
        if area < 10000 && box(3) > box(4)
           court(idx) = 0;
        end
    end
    court = ~court;

    if show_figs
    figure
    imshow(court)
    title('court after filtering')
    end

    % Create a mask that represents the addition of the court and paint
    court_layer = paint_mask | court;

    if show_figs
    figure
    imshow(court_layer)
    title('court layer')
    end

    % We perform the morphological close function on this mask in order to
    % reduce noise
    SE = strel('disk',1);
    court_layer = imclose(court_layer,SE);

    if show_figs
    figure
    imshow(court_layer); title('court layer with after cb cr restriction');
    end

    [height width] = size(court_layer);

    % Create an edgemap of the frame
    edgeMap = edge(court_layer,'canny');

    % Dilate the edgemap to get thicker lines
    SE = ones(3,3);
    edgeMapDilated = imdilate(edgeMap,SE);

    if show_figs
    figure
    imshow(edgeMapDilated)
    title('Dilated Edge Map of Frame');
    end

    % Compute hough transform on edgemap. houghpeaks finds the 100 top peaks of
    % the hough tranform
    [H,T,R] = hough(edgeMapDilated);
    numLines = 100;
    P = houghpeaks(H,numLines, 'Threshold', .1*max(H(:)));

    % Find lines and connects lines that are less than 1000 pixels apart
    lines = houghlines(edgeMapDilated,T,R,P,'FillGap',1000,'MinLength',100);
    if show_figs
    figure
    imshow(frame)
    hold on
    end

    % counters makes sure that there is only 1 vertical line found, 5
    % horizontal lines and 2 lines corresponding to the scoreboard
    counter_h = 5;
    counter_boxH = 2;

    % xy cell arrays store the line information for the vertical, horizontal,
    % and scoreboard
    xyV = zeros(2,2);
    xyH = {zeros(2,2) zeros(2,2) zeros(2,2) zeros(2,2)};
    xyBoxH = {zeros(2,2) zeros(2,2)};

    % boolean corresponding to left or right court
    is_left_court = 0;

    % Searches through all lines until a vertical line is found and records if
    % the frame is left or ride court based on the angle of the vertical line.
    
    for k = 1:size(lines,2)
        theta_line = lines(k).theta;
        xy = [lines(k).point1; lines(k).point2];
        averagex = mean(xy(:,1));
        % Only extract 1 line that is on the right or left then Breaks
        if VideoNum == 1
            distance = averagex > (width - (MAX_DISTANCE_FROM_SIDE*width));
        else
            distance = logical(0);
        end
        if abs(theta_line) >= MIN_ANGLE_VERTICAL && abs(theta_line) <= MAX_ANGLE_VERTICAL && (averagex < (MAX_DISTANCE_FROM_SIDE*width) || distance)
            xyV = xy;
            if show_figs
            plot(xy(:,1),xy(:,2),'LineWidth',2,'Color','yellow');
            end
            if theta_line > 0
                is_left_court = 1;
            end
            theta_vertical = theta_line;
            break
        end
    end
    
    % Searches for horizontal lines (top and bottom) as well as the scoreboard
    % if the frame is left court we look for downward sloping horizontal lines
    for k = 1:size(lines,2)
        theta_line = lines(k).theta;
        point = lines(k).point1;
        if ~is_left_court
            is_line = theta_line >= 80 && theta_line <= 90;
        else
            is_line = theta_line <= -80 && theta_line >= -90;
        end
        % Extract 5 lines that are horizontal
        if  is_line && counter_h>0
            xy = [lines(k).point1; lines(k).point2];
            if show_figs
            plot(xy(:,1),xy(:,2),'LineWidth',2,'Color','red');
            end
            xyH{counter_h} = xy;
            counter_h = counter_h - 1;
         end

        if theta_line <= -87 && theta_line >=-93 && counter_boxH>0 && point(2) > height*3/4
            xy = [lines(k).point1; lines(k).point2];
            if show_figs
            plot(xy(:,1),xy(:,2),'LineWidth',2,'Color','blue');
            end
            xyBoxH{counter_boxH} = xy;
            counter_boxH = counter_boxH - 1;
        end
    
    end
    
    % If there is a scoreboard find its top and bottom based on the mean of the
    % lines' y values
    sb_top = height;
    sb_bottom = 0;
    idxBottom_sb = 1;
    scoreboard_present = mean(mean(xyBoxH{1} ~= zeros(2,2)));
    if scoreboard_present
        for k=1:length(xyBoxH)
            xy = xyBoxH{k};
            if mean(xy(:,2)) < sb_top
                sb_top = mean(xy(:,2));
            end
            if mean(xy(:,2)) > sb_bottom
                sb_bottom = mean(xy(:,2));
                idxBottom_sb = k;
            end
        end
    else
        sb_top = mean(xyBoxH{2}(:,2));
    end

    % Find the top and bottom of the playing field based on the horizontal lines

    % start with the bottom either at 0 or the bottom of the scoreboar because
    % you never want to choose a line above the scoreboard
    bottom = sb_bottom; 
    top = height;
    idxTop = 1;
    idxBottom = 1;

    % Find the line with the highest and lowest mean y values.
    for n=1:length(xyH)
        xy = xyH{n};
        if mean(xy(:,2)) < top
            top = mean(xy(:,2));
            idxTop = n;
        end

        if mean(xy(:,2)) > bottom
            bottom = mean(xy(:,2));
            idxBottom = n;
        end
    end

    % Extract the top and bottom lines based on calculated indexes
    xyBottom = xyH{idxBottom};
    if bottom == sb_bottom && mean(mean(xyBoxH{1} ~= zeros(2,2)))
        xyBottom = xyBoxH{idxBottom_sb};
    end
    xyTop = xyH{idxTop};

    % Find slopes and y-intercept of lines y=mx+b
    m_side = (xyV(1,2) - xyV(2,2)) / (xyV(1,1) - xyV(2,1));
    b_side = xyV(1,2) - m_side*xyV(1,1);
    m_top = (xyTop(1,2) - xyTop(2,2)) / (xyTop(1,1) - xyTop(2,1));
    b_top = xyTop(1,2) - m_top*xyTop(1,1);
    m_bottom = (xyBottom(1,2) - xyBottom(2,2)) / (xyBottom(1,1) - xyBottom(2,1));
    b_bottom = xyBottom(1,2) - m_top*xyBottom(1,1);

    % Create mask of the court based on these lines. If the scoreboard is
    % present use the whichever line is lowest.
    court_mask_lines = court_layer;
    bottom_extra = height*1/15;
    for col=1:width
        top = m_top*col + b_top;
        bottom1 = m_bottom*col + b_bottom - bottom_extra;
        bottom2 = sb_top;
        if scoreboard_present
            bottom = min([bottom1 bottom2]);
        else
            bottom = bottom1;
        end
        for row=1:height
            side = (row - b_side) / m_side;
            if row > top && row < bottom && ~xor(is_left_court,col > side)
                court_mask_lines(row,col) = 1;
            else
                court_mask_lines(row,col) = 0;
            end
        end
    end


    % figure
    % imshow(court_mask_lines)

    % Mask out to get the image before scoreboard is removed
    court_rgb = frame;
    court_rgb(:,:,1)= frame(:,:,1).*uint8(court_mask_lines);
    court_rgb(:,:,2)= frame(:,:,2).*uint8(court_mask_lines);
    court_rgb(:,:,3)= frame(:,:,3).*uint8(court_mask_lines);

    if show_figs
    figure
    imshow(court_rgb)
    title('court')
    end

    % Get players using the mask of the playing field and the mask of the court
    % with the players with value 0;
    players = ~court_layer & court_mask_lines;
    if show_figs
    figure
    imshow(players);
    title('sum of ~court player and ~court mask')
    end

    %                       %
    % Extract paint lines   %
    %                       % 

    % For the Oregon game, we extrac the lines corresponding to the paint by
    % using our previous paint mask. We then close and dilate it in order to
    % remove any playes that may be in front of it.
    if VideoNum == 1
         paint_mask_sealed = im2bw(rgb2gray(court_rgb),.5);
    else
        paint_mask_sealed = paint_mask_unfiltered & court_mask_lines;
        SE = ones(20,20);
        paint_mask_sealed = imclose(paint_mask_sealed,SE);
        SE = ones(2,2);
        paint_mask_sealed = imdilate(paint_mask_sealed,SE);
    end
    

    % Perform edge detection
    edgeMap = edge(paint_mask_sealed, 'canny');
    edgeMap = imdilate(edgeMap, ones(1,1));

    % figure
    % imshow(edgeMap)

    numLines = 200;
    [H,T,R] = hough(edgeMap);
    P = houghpeaks(H,numLines, 'Threshold', .1*max(H(:)));

    % Find lines and connects lines that are less than 1000 pixels apart
    lines = houghlines(edgeMapDilated,T,R,P,'FillGap',1000,'MinLength',10);
    if show_figs==1
    figure
    imshow(paint_mask_sealed)
    hold on
    end

    % counters for number of horizontal lines
    if VideoNum == 1
        counter_h = 4;
    else
        counter_h = 2;
    end

    % xy cell arrays store the line information for the horizontal
    xyH = {zeros(2,2) zeros(2,2)};

    for k = 1:size(lines,2)
        theta_line = lines(k).theta;
        point = lines(k).point1;
        if ~is_left_court
            is_line = theta_line >= 80 && theta_line <= 90;
        else
            is_line = theta_line <= -80 && theta_line >= -90;
        end
        % Extract 2 lines that are horizontal
        if  is_line && counter_h>0
            xy = [lines(k).point1; lines(k).point2];
            if show_figs==1
            plot(xy(:,1),xy(:,2),'LineWidth',2,'Color','red');
            end
            xyH{counter_h} = xy;
            counter_h = counter_h - 1;
        end

    end

    if VideoNum==1
    edgeMap = edge(paint_mask, 'canny');
    edgeMap = imdilate(edgeMap, ones(1,1));
    
    [H,T,R] = hough(edgeMap);
    P = houghpeaks(H,numLines, 'Threshold', .1*max(H(:)));
    
    % Find lines and connects lines that are less than 1000 pixels apart
    lines = houghlines(edgeMapDilated,T,R,P,'FillGap',100,'MinLength',100);
    end

    xyV = zeros(2,2);
    counter_v = 1;
    
    %%%%%%%%%%%%%%%%%
    for k = 1:size(lines,2)
        theta_line = lines(k).theta;
        xy = [lines(k).point1; lines(k).point2];
        averagex = mean(xy(:,1));
        % Only extract 1 line that is on the right or left
        if theta_line >= abs(theta_vertical)-MIN_ANGLE && theta_line <= abs(theta_vertical)+MAX_ANGLE && counter_v>0 && averagex > (MAX_DISTANCE_FROM_SIDELINE*width)
            xyV = xy;
            if show_figs==1
            plot(xy(:,1),xy(:,2),'LineWidth',2,'Color','yellow');
            end
            counter_v = counter_v - 1;
        end
    end

    m_paint = (xyV(1,2) - xyV(2,2)) / (xyV(1,1) - xyV(2,1));
    b_paint = xyV(1,2) - m_paint*xyV(1,1);

    xyBox = xyH;
    
    if VideoNum==1
        counter_box = 2;
        top = mean(xyTop(:,2));
        bottom = mean(xyBottom(:,2));
    end
    
    % Find the top and bottom of the restricted zone box
    for n=1:length(xyH)
        xy = xyH{n};
        if mean(xy(:,2)) < top && mean(xy(:,2)) > bottom
            xyBox{counter_box} = xy;
        end
    end
    
    % Decide which is bottom and top
    xy1 = xyH{1};
    xy2 = xyH{2};
    if mean(xy1(:,2)) > mean(xy2(:,2))
        xy_top_box = xy1;
        xy_bottom_box = xy2;
    else
        xy_top_box = xy2;
        xy_bottom_box = xy2;
    end

    m_top_box = (xy_top_box(1,2) - xy_top_box(2,2)) / (xy_top_box(1,1) - xy_top_box(2,1));
    b_top_box = xy_top_box(1,2) - m_top_box*xy_top_box(1,1);
    m_bottom_box = (xy_bottom_box(1,2) - xy_bottom_box(2,2)) / (xy_bottom_box(1,1) - xy_bottom_box(2,1));
    b_bottom_box = xy_bottom_box(1,2) - m_bottom_box*xy_bottom_box(1,1);

    % Finds corners of the restricted zone box and calculates homography matrix H
    % Apply Homography*(point in frame) to find approximation of corresponding point in template
    check = [m_side m_top_box m_bottom_box m_paint];
    check = isfinite(check);
    if sum(check) == 4
        X = BoxCorners(is_left_court, m_side, b_side, m_top_box, b_top_box, m_bottom_box, b_bottom_box, m_paint, b_paint);
    end
    Homography(frame_num-FIRST+1,:,:) = CourtPosition(X);


    MSE = mean(mean((CourtPosition(X)-reshape(Homography(working,1:2,1:3),2,3)).^2));
    if MSE > 5e3

        Homography(frame_num-FIRST+1,:,:) = Homography(working,:,:);
    else
        working = frame_num-FIRST+1;
    end


    % Create hsv image from court mask
    court_hsv = rgb2hsv(court_rgb);
    if show_figs
    figure
    subplot(3,1,1)
    imshow(court_hsv(:,:,1))
    subplot(3,1,2)
    imshow(court_hsv(:,:,2))
    subplot(3,1,3)
    imshow(court_hsv(:,:,3))
    end
    
    if VideoNum==1
        SE = strel('disk',2);
        players_erode = imerode(players,SE);

        if show_figs ==1
        figure
        imshow(players_erode);
        title('players eroded with disk and ones')
        end
        if show_figs ==1
        figure
        imshow(players_erode);
        title('players eroded with disk and ones')
        end

        %Filter players only mask by width
        MIN_DIFF = 0;
        imgLabel = bwlabel(players_erode);
        shapeProps = regionprops(imgLabel, 'BoundingBox','Area');
        for nRegion = 1:length(shapeProps)
            idx = find(imgLabel == nRegion);
            box = shapeProps(nRegion).BoundingBox;
            area = shapeProps(nRegion).Area;
            if area < 500 && box(3) > box(4)
                players_erode(idx) = 0;
            elseif box(3) > box(4) + MIN_DIFF
                players_erode(idx) = 0;
            end
        end
        if show_figs ==1
        figure
        imshow(players_erode);
        title('players without large widths')
        end

        SE = ones(40,20);
        players_dilate = imdilate(players_erode,SE);

        if show_figs ==1
        figure
        imshow(players_dilate)
        title('players dilated')
        end
        
        players = players_dilate;
    end
    
    players_sat = court_hsv(:,:,2) .* double(players);
    players_val = court_hsv(:,:,3) .* double(players);

    if show_figs
    figure
    imshow(players_sat)
    title('players saturation')
    end

    if show_figs
    figure
    imshow(players_val)
    title('players value')
    end
    
    team1 = (players_sat < MAX_team1 & players_sat > MIN_team1) | (players_val < MAXV_team1 & players_val > MINV_team1);
    team2 = (players_sat < MAX_team2 & players_sat > MIN_team2);

    if show_figs
    figure
    imshow(team1)
    title('team1 players unfiltered')
    figure
    imshow(team2)
    title('team2 players unfiltered')
    end

    team1_dilated = imdilate(team1, ones(team1_k,team1_k));
    team2_dilated = imdilate(team2, ones(1,1));

    if show_figs
    figure
    imshow(team1_dilated)
    title('team1 players dilated')
    figure
    imshow(team2_dilated)
    title('team2 players dilated')
    end
    
    % Filter players by area, solidity, position and width/height
    imgLabel = bwlabel(team1_dilated);
    shapeProps = regionprops(imgLabel, 'Area','Solidity','Centroid','BoundingBox');
    for nRegion = 1:length(shapeProps)
        idx = find(imgLabel == nRegion);
        area = shapeProps(nRegion).Area;
        solidity = shapeProps(nRegion).Solidity;
        centroid = shapeProps(nRegion).Centroid;
        box = shapeProps(nRegion).BoundingBox;
        bottom_line = m_bottom*centroid(1) + b_bottom;
        if area < MIN_AREA1_team1 || box(3) > 4*box(4)
            team1_dilated(idx) = 0;
        end
        if area < MIN_AREA2 && (solidity < MIN_SOLIDITY2_team1 || abs(centroid(2)-bottom_line) <= MIN_DIFF)
            team1_dilated(idx) = 0;
        elseif solidity < MIN_SOLIDITY
            team1_dilated(idx) = 0;
        end
    end
    imgLabel = bwlabel(team2_dilated);
    shapeProps = regionprops(imgLabel, 'Area','Solidity','Centroid','BoundingBox');
    for nRegion = 1:length(shapeProps)
        idx = find(imgLabel == nRegion);
        area = shapeProps(nRegion).Area;
        solidity = shapeProps(nRegion).Solidity;
        centroid = shapeProps(nRegion).Centroid;
        box = shapeProps(nRegion).BoundingBox;
        bottom_line = m_bottom*centroid(1) + b_bottom;
        if area < MIN_AREA1_team2 || box(3) > 4*box(4)
            team2_dilated(idx) = 0;
        end
        if area < MIN_AREA2 && (solidity < MIN_SOLIDITY2_team2 || abs(centroid(2)-bottom_line) <= MIN_DIFF)
            team2_dilated(idx) = 0;
        elseif solidity < MIN_SOLIDITY
            team2_dilated(idx) = 0;
        end
    end

    if show_figs==1
    figure
    imshow(team1_dilated)
    title('team1 players filtered by area')
    figure
    imshow(team2_dilated)
    title('team2 players filtered by area')
    end

    team1_dilated = imdilate(team1_dilated, ones(4,4));
    team2_dilated = imdilate(team2_dilated, ones(4,4));

    team2_dilated = xor(team2_dilated, team1_dilated & team2_dilated);
    
    % Filter players by area and solidity
    imgLabel = bwlabel(team2_dilated);
    shapeProps = regionprops(imgLabel, 'Area','Solidity');
    for nRegion = 1:length(shapeProps)
        idx = find(imgLabel == nRegion);
        area = shapeProps(nRegion).Area;
        solidity = shapeProps(nRegion).Solidity;
        if area < MIN_AREA1
            team2_dilated(idx) = 0;
        end
    end

    if show_figs
    figure
    imshow(frame);
    hold on
    end
    
    % Save centroid values for players of each team
    imgL = bwlabel(team1_dilated);
    centroidProps = regionprops(imgL, 'Centroid');

    for nRegion = 1:length(centroidProps)

        idx = find(imgL == nRegion);
        centroid = centroidProps(nRegion).Centroid;
        cx = (centroid(1));
        cy = (centroid(2));
        if show_figs
        plot(cx,cy,'o','color','red','LineWidth',8);
        end
        
        % Output X,Y values for team 1
        team1_points(frame_num-FIRST+1, nRegion, 1:2) = [cx cy];

    end

    imgR = bwlabel(team2_dilated);
    centroidProps = regionprops(imgR, 'Centroid');

    for nRegion = 1:length(centroidProps)

        idx = find(imgL == nRegion);
        centroid = centroidProps(nRegion).Centroid;
        cx = (centroid(1));
        cy = (centroid(2));
        if show_figs
        plot(cx,cy,'o','color','blue','LineWidth',8);
        end
        
        % Output X,Y values for team 2
        team2_points(frame_num-FIRST+1, nRegion, 1:2) = [cx cy];
    end
end

   

