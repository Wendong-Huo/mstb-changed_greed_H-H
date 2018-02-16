function [ fig ] = statsDraw
%statsDraw - draw the window and axes / panels

% Define default view
layout = 'axes';
datatype = 'ms'; % ms or lcms

% Main figure
fig.fig = figure('Name','Stats Toolbox',...
    'Units','normalized',...
    'Position',[0.2 0.2 0.6 0.6],...
    'Tag','stats',...
    'Color','white');

% Decide which layout to be drawn on start - imaging only a table view for
% observations and an axes view
%fig.layout = 'plot';
[locn] = statsLocations(layout,datatype);

% A panel for holding the axes and stuff and then another to host all the
% menus instead of the pop up boxes. Quite a stretch I think
fig.pan1 = uipanel('Parent',fig.fig,...
    'Units','normalized',...
    'Position',[0.2 0 0.8 1],...
    'BackgroundColor','white');

fig.pan2 = uipanel('Parent',fig.fig,...
    'Units','normalized',...
    'Position',[0 0 0.2 1],...
    'BackgroundColor','white');

% Draw the parts in here according to which should be visible...
%
%

% Plot the data along the bottom
fig.ax.spec(1) = axes('Parent',fig.pan1,...
    'Units','normalized',...
    'Position',locn.spec.pos,...
    'XTick',[],...
    'YTick',[],...
    'Box','on',...
    'Visible',locn.spec.vis,...
    'LineWidth',5,...
    'TickLength',[0 0]);

% Scatter plot (e.g. multivariate data)
fig.ax.scatter(1) = axes('Parent',fig.pan1,...
    'Units','normalized',...
    'Position',locn.scatter.pos,...
    'XTick',[],...
    'YTick',[],...
    'Box','on',...
    'Visible',locn.scatter.vis,...
    'LineWidth',5,...
    'TickLength',[0 0]);

% Confusion plot axes
fig.ax.conf(1) = axes('Parent',fig.pan1,...
    'Units','normalized',...
    'Position',locn.conf.pos,...
    'XTick',[],...
    'YTick',[],...
    'Box','on',...
    'Visible',locn.conf.vis,...
    'LineWidth',5,...
    'TickLength',[0 0]);

% Loading plot
fig.ax.load(1) = axes('Parent',fig.pan1,...
    'Units','normalized',...
    'Position',locn.load.pos,...
    'XTick',[],...
    'YTick',[],...
    'Box','on',...
    'Visible',locn.load.vis,...
    'LineWidth',5,...
    'TickLength',[0 0]);

% Table of observations
fig.ax.table = uitable('Parent',fig.pan1,...
    'Units','normalized',...
    'Position',locn.tab.pos,...
    'Visible',locn.tab.vis);


% Toolbar required
[fig] = statsToolbarDraw(fig);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
