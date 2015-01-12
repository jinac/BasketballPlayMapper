Multiple Player Motion Tracking for Sports Applications
```````````````````````````````````````````````````````

EE368 - Spring 2012
Michael Durate, John  Inacay, Yuxiang Zhou

To run the code, 

1. set matlab run location to the directory
containing 'Ohio1.avi' and 'OregonL1.avi'

2. open TrackingMain.m

choose VideoNum = 1 for 'Ohio1.avi',
choose VideoNum = 2 for 'OregonL1.avi'

choose ShowFigures = 0 to only show final plot of player trajectories for team 1 and team 2
choose ShowFigures = 1 to show intermediate masks and figures. (may want to reduce frame number)

starting and ending frames can be chosen in SetParams.m, the default is ~100 frames from each video starting near the beginning to about 3/4 way through.


3. code may take up to 5 minutes to run depending on frame selection

4. view time lapse plot of player locations