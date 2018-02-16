function statsBoxplotsMenu(~,~,fig)
%statsBoxplotsMenu - menu for drawing / displaying boxplots

% Get the guidata
sts = guidata(fig.fig);
if isempty(sts)
    return
end

% Draw the window to help control the colours / groups / etc
[window] = manipulateWindow(fig,sts,sts.datatype);

% Set the callback for the finish button
set(window.mzrtchoice,'Callback',{@statsMZRTupdate,fig,window});
set(window.list,'Callback',{@statsBoxplotsDraw,fig,window});
set(window.groups,'Callback',{@statsBoxplotsDraw,fig,window});

return

% Functions to draw the results...
set(window.draw,'Callback',{@statsUnivariateDraw,fig,window});

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [man] = manipulateWindow(fig,sts,datatype)
% Window with the little options for manipulating the figure...

% This is where we draw everything
parent = fig.pan2;

fS = 14;

% Heading
uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0 0.95 1 0.05],...
    'Style','text',...
    'String','Boxplots!',...
    'FontSize',24,...
    'BackgroundColor',[1 1 1]);

%%%%


% Which DA to perform?
x = 0.9;
uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0 x 0.5 0.05],...
    'Style','text',...
    'String','Format',...
    'FontSize',fS,...
    'BackgroundColor',[1 1 1]);
man.mzrtchoice = uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0.5 x-0.15 0.475 0.2],...
    'Style','popupmenu',...
    'String',{'mz | rt';'rt | mz'},...
    'Value',1,...
    'FontSize',fS);

% Generate mz | rt or rt | mz values in nice text format... nightmare!
%vals = statsMZRTRTMZ(sts.proc.var.mz,sts.proc.var.rt,1);
vals = statsMZRTRTMZ(sts.proc.var.mz,sts.proc.var.mz,3);

% m/z | rt values
x = 0.875;
man.list = uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0.1125 x-0.18 0.85 0.2],...
    'Style','listbox',...
    'String',vals,...
    'Value',1,...
    'FontSize',fS,...
    'Min',1,...
    'Max',1);

% Using which group / groups?
x = 0.6;
names = fieldnames(sts.proc.meta);
idx = strcmp(names,'histID');
if sum(idx) == 1
    idx = find(idx);
else
    idx = 1;
end
uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0 x 0.5 0.05],...
    'Style','text',...
    'String','Group(s)',...
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

% Analyse button
man.external = uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0.05 0.40 0.9 0.05],...
    'Style','checkbox',...
    'String','Plot in external figure',...
    'BackgroundColor',[1 1 1],...
    'FontSize',fS,...
    'Value',0);

% ROC instead
man.plotROC = uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0.05 0.355 0.9 0.05],...
    'Style','checkbox',...
    'String','Plot ROC instead',...
    'BackgroundColor',[1 1 1],...
    'FontSize',fS,...
    'Value',0);

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%