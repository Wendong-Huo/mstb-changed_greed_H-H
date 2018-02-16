function [fig] = dpnDrawToolbar(fig)

% Let's add a new toolbar to it instead of the horrible push buttons
fig.tb.main = uitoolbar('Parent',fig.fig,...
    'Tag','dpntb',...
    'Visible','on');

% Need to get the icons for the buttons...
dirIcon = deSlash([pwd filesep '/desi/icons/']);

% Here a button for the loading a new file...
fig.tb.new = uipushtool('Parent',fig.tb.main,...
    'CData',getImage(dirIcon,'snowflake-2-48'),...
    'TooltipString','Pick an imzML file to be imported');

% This will save the imported data to an HDF5 file
fig.tb.save = uipushtool('Parent',fig.tb.main,...
    'CData',getImage(dirIcon,'save-48'),...
    'TooltipString','Save processed data',...
    'Enable','on');

% Update the images...
fig.tb.refresh = uipushtool('Parent',fig.tb.main,...
    'CData',getImage(dirIcon,'refresh-2-48'),...
    'TooltipString','Update the ion images and start again...',...
    'Enable','on');

insertSeparator(fig.tb.main);

% Switch the MS images
fig.tb.switch = uipushtool('Parent',fig.tb.main,...
    'CData',getImage(dirIcon,'plus-minus-2-48'),...
    'TooltipString','Switch pos/neg modes',...
    'Enable','on');

% Play with the positive image
fig.tb.editPos = uitoggletool('Parent',fig.tb.main,...
    'CData',getImage(dirIcon,'plus-5-48'),...
    'TooltipString','MS+ manipulation',...
    'Enable','on',...
    'Tag','desiSideMenu');

% Play with the negative image
fig.tb.editNeg = uitoggletool('Parent',fig.tb.main,...
    'CData',getImage(dirIcon,'minus-5-48'),...
    'TooltipString','MS- manipulation',...
    'Enable','on',...
    'Tag','desiSideMenu');

% Interpolation
fig.tb.interp = uipushtool('Parent',fig.tb.main,...
    'CData',getImage(dirIcon,'text-justify-48'),...
    'TooltipString','Interpolation',...
    'Enable','on',...
    'Tag','NOTdesiSideMenu');

%insertSeparator(fig.tb.main);

% Add an optical image
fig.tb.optimg = uipushtool('Parent',fig.tb.main,...
    'CData',getImage(dirIcon,'paper-clip-2-48'),...
    'TooltipString','Attach (!) an optical image',...
    'Enable','on');

% Coregistration
fig.tb.coreg = uitoggletool('Parent',fig.tb.main,...
    'CData',getImage(dirIcon,'photo-48'),...
    'TooltipString','Image coregistration',...
    'Enable','off',...
    'Tag','desiSideMenu');

insertSeparator(fig.tb.main);

% Zoom in
fig.tb.zoom(1) = uitoggletool('Parent',fig.tb.main,...
    'CData',getImage(dirIcon,'zoom-in-2-48'),...
    'TooltipString','Zoom in',...
    'Enable','on');

% Zoom out
fig.tb.zoom(2) = uitoggletool('Parent',fig.tb.main,...
    'CData',getImage(dirIcon,'zoom-out-2-48'),...
    'TooltipString','Zoom out',...
    'Enable','on');

% Zoom reset
fig.tb.zoomreset = uipushtool('Parent',fig.tb.main,...
    'CData',getImage(dirIcon,'resize-5-48'),...
    'TooltipString','Restore original zoom',...
    'Enable','on');

% Grid
fig.tb.grid = uitoggletool('Parent',fig.tb.main,...
    'CData',getImage(dirIcon,'grid-48'),...
    'TooltipString','Grid',...
    'Enable','on');

insertSeparator(fig.tb.main);

% Annotation
fig.tb.annotate = uitoggletool('Parent',fig.tb.main,...
    'CData',getImage(dirIcon,'brush-2-48'),...
    'TooltipString','Image annotation',...
    'Enable','on',...
    'Tag','desiSideMenu');

% Internal statistics
fig.tb.intStats = uitoggletool('Parent',fig.tb.main,...
    'CData',getImage(dirIcon,'heat-map-48'),...
    'TooltipString','Quick and dirty statistics',...
    'Enable','on',...
    'Tag','desiSideMenu');


% Stats - or similar idea
fig.tb.segment = uitoggletool('Parent',fig.tb.main,...
    'CData',getImage(dirIcon,'orange-48'),...
    'TooltipString','Multivariate segmentation (obvs)',...
    'Enable','on',...
    'Tag','desiSideMenu');

% Stats - or similar idea
fig.tb.family = uitoggletool('Parent',fig.tb.main,...
    'CData',getImage(dirIcon,'bugle-48'),...
    'TooltipString','Lipid family analysis',...
    'Enable','on',...
    'Tag','desiSideMenu');

% % Fusion!
% fig.tb.fuse = uipushtool('Parent',fig.tb.main,...
%     'CData',getImage(dirIcon,'link-48'),...
%     'TooltipString','Data fusion',...
%     'Enable','on');

insertSeparator(fig.tb.main);
insertSeparator(fig.tb.main);

% Window layout
if strcmp(fig.style,'detail')
    st = 'on';
else
    st = 'off';
end
fig.tb.layout = uitoggletool('Parent',fig.tb.main,...
    'CData',getImage(dirIcon,'window-layout-48'),...
    'TooltipString','Change the window layout',...
    'Enable','on',...
    'State',st);

insertSeparator(fig.tb.main);
insertSeparator(fig.tb.main);

% Correlation analysis for publication purposes
fig.tb.doComparison = uipushtool('Parent',fig.tb.main,...
    'CData',getImage(dirIcon,'scatter-plot-48'),...
    'TooltipString','Correlation comparison for paper purposes',...
    'Enable','on');


% Export figures
fig.tb.expfig = uipushtool('Parent',fig.tb.main,...
    'CData',fliplr(getImage(dirIcon,'stallion-48')),...
    'TooltipString','Neigh - figure extraction');


% Close other windows
fig.tb.duck = uipushtool('Parent',fig.tb.main,...
    'CData',getImage(dirIcon,'duck-48'),...
    'TooltipString','Quack - close other windows');



% What about enlarging the toolbar?
dpnEnlarge(fig.tb.main);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ico] = getImage(path,name)
% Get the necessary icon.  Need to beautify it a little bit more...

[ico] = importdata([path name '.png']);

[ico] = iconProcess(ico.alpha,ico.cdata);


end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function insertSeparator(h)

uipushtool('Parent',h,...
    'CData', NaN([50 50 3]),...
    'ClickedCallback',{},...
    'Separator', 'on',...
    'Tooltip','Is this button missing?');

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
