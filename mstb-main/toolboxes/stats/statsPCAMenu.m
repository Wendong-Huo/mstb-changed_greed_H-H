function statsPCAMenu(~,~,fig)
%statsPCAMenu - draw the bits and pieces for PCA to be performed and
%controlled once calculated

% Get the guidata
sts = guidata(fig.fig);
if isempty(sts)
    return
end

% Draw the window to help control the colours / groups / etc
[window] = manipulateWindow(fig,sts);

% Set the callback for the finish button / window close
set(window.groups,'Callback',{@statsPCACalculate,fig,window});
set(window.comp1,'Callback',{@statsPCACalculate,fig,window});
set(window.comp2,'Callback',{@statsPCACalculate,fig,window});
set(window.ellipse,'Callback',{@statsPCACalculate,fig,window});
set(window.extraPlot,'Callback',{@statsPCACalculate,fig,window});

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [man] = manipulateWindow(fig,sts)
% Window with the little options for manipulating the figure...

% This is where we draw everything
parent = fig.pan2;

fS = 14;

% Heading
uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0 0.95 1 0.05],...
    'Style','text',...
    'String','PCA',...
    'FontSize',24,...
    'BackgroundColor',[1 1 1]);

%%%%

% Need to make a window for the meta groups to be listed here...
x = 0.9;
names = fieldnames(sts.proc.meta);
idx = strcmp(names,'hist');
if sum(idx) == 1
    idx = find(idx);
else
    idx = 1;
end
uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0 x 0.5 0.05],...
    'Style','text',...
    'String','Groups',...
    'FontSize',fS,...
    'BackgroundColor',[1 1 1]);
man.groups = uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0.5 x-0.15 0.475 0.2],...
    'Style','listbox',...
    'String',names,...
    'Value',idx,...
    'FontSize',fS,...
    'Min',1,...
    'Max',3);

% Which components to plot
x = 0.65;
uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0 x 0.5 0.05],...
    'Style','text',...
    'String','PCs',...
    'FontSize',fS,...
    'BackgroundColor',[1 1 1]);
man.comp1 = uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0.5 x-0.15 0.22 0.2],...
    'Style','listbox',...
    'String',int2str([1:10]'),...
    'Value',1,...
    'FontSize',fS,...
    'BackgroundColor',[16 135 232]/256,...
    'ForegroundColor','white');%'Min',1,...'Max',3);
man.comp2 = uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0.75 x-0.15 0.22 0.2],...
    'Style','listbox',...
    'String',int2str([1:10]'),...
    'Value',2,...
    'FontSize',fS,...
    'BackgroundColor',[230 115 142]/256,...
    'ForegroundColor','white');%'Min',1,...'Max',3);


% Do we want to draw the ellipses?
man.ellipse = uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0.05 0.5 0.4 0.025],...
    'Style','checkbox',...
    'String','Draw ellipses?',...
    'FontSize',fS,...
    'Value',0,...
    'BackgroundColor',[1 1 1]);

% Do we want to draw the ellipses?
man.centroid = uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0.05 0.525 0.4 0.025],...
    'Style','checkbox',...
    'String','Centroids?',...
    'FontSize',fS,...
    'Value',0,...
    'BackgroundColor',[1 1 1]);

% What about showing stuff in the other axes?
x = 0.3;
uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0 x 0.5 0.05],...
    'Style','text',...
    'String','Plot',...
    'FontSize',fS,...
    'BackgroundColor',[1 1 1]);
man.extraPlot = uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0.5 x-0.15 0.475 0.2],...
    'Style','popupmenu',...
    'String',{'Eigenvalues';'Loadings';'Boxplots'},...
    'Value',1,...
    'FontSize',fS);%'Min',1,...'Max',3);

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
