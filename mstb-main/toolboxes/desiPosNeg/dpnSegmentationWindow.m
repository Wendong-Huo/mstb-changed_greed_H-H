function dpnSegmentationWindow(src,event,fig)
%dpnSegmentationWindow - draw a window to allow us to play around with
%various segmentation things...

% Get the guidata
dpn = guidata(fig.fig);
if isempty(dpn)
    return
end

% Can't proceed without annotations
if ~isfield(dpn,'anno');
    disp('No annotations');
    set(src,'State','off');
    return
end

% Determine m/z range
range = [floor(min(dpn.d1.mz)) ceil(max(dpn.d1.mz))];
if strcmp(dpn.mode,'dual')
    range(1) = min([range(1) floor(min(dpn.d2.mz))]);
    range(2) = max([range(2) ceil(max(dpn.d2.mz))]);
end


% Draw different windows depending on the analysis mode.  And then also
% set the callbacks for the functions...
switch dpn.mode
    case 'dual'
        
        [seg] = segmentWindow2(src,event,fig,dpn.mode,range);
        set(seg.do,'Callback',{@dpnSegmentationPerform,fig,seg});
        
        % Callback for the fusion options
        set(seg.fuse,'Callback',{@fusionBoxCallback,seg});
        fusionBoxCallback(seg.fuse,[],seg);

        
    case 'single'
        
        [seg] = segmentWindow2(src,event,fig,dpn.mode,range);
        %set(seg.do,'Callback',{@desiSegmentationPerform,fig,seg});
        set(seg.do,'Callback',{@dpnSegmentationPerform,fig,seg});
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [man] = segmentWindow(src,event,fig)
% Window with the little options for manipulating the figure...

% Where should we draw everything
parent = fig.pan2;

% Opening text
uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0 0.95 1 0.05],...
    'Style','text',...
    'String','Segmentation etc',...
    'FontSize',24,...
    'BackgroundColor',[1 1 1]);

% Potential options...
uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0.05 0.8 0.211 0.05],...
    'Style','text',...
    'String','Analysis',...
    'FontSize',16,...
    'BackgroundColor',[1 1 1]);
man.list = uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0.5 0.7 0.45 0.2],...
    'Style','listbox',...
    'String',{'PCA';'kMeans';'MMC'},...
    'Value',1,...
    'FontSize',16);%'Min',1,...'Max',3);

% What about a box for the normalisation to be performed
uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0.05 0.62 0.35 0.05],...
    'Style','text',...
    'String','Normalisation',...
    'FontSize',16,...
    'BackgroundColor',[1 1 1]);
man.norm = uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0.5 0.575 0.45 0.1],...
    'Style','popupmenu',...
    'String',{'None';'TIC';'PQN-Median';'PQN-Mean'},...
    'Value',1,...
    'FontSize',16);%'Min',1,...'Max',3);

% Remove background pixels?
man.remBG = uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0.05 0.575 0.9 0.05],...
    'Style','checkbox',...
    'String','Remove background pixels?',...
    'Value',0,...
    'FontSize',16,...
    'BackgroundColor',[1 1 1]);

% Log transformation?
man.doLog = uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0.05 0.54 0.9 0.05],...
    'Style','checkbox',...
    'String','Log transformation?',...
    'Value',1,...
    'FontSize',16,...
    'BackgroundColor',[1 1 1]);

% Range for low/high m/z range
uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0.4 0.48 0.2 0.05],...
    'Style','text',...
    'String','< m/z <',...
    'FontSize',12,...
    'BackgroundColor',[1 1 1]);
man.mzL = uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0.05 0.49 0.35 0.05],...
    'Style','edit',...
    'String','600',...
    'Value',1,...
    'FontSize',16);
man.mzH = uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0.6 0.49 0.35 0.05],...
    'Style','edit',...
    'String','900',...
    'Value',1,...
    'FontSize',16);

% A box to limit k for kmeans
man.maxClust = uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0.2 0.7 0.15 0.025],...
    'Style','edit',...
    'String','4',...
    'Value',1,...
    'FontSize',16);
uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0.07 0.675 0.1 0.05],...
    'Style','text',...
    'String','k <= ',...
    'FontSize',14,...
    'BackgroundColor',[1 1 1]);



% A button to 'do' what we wanted...
man.do = uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0.05 0.4 0.9 0.05],...
    'Style','pushbutton',...
    'String','Go',...
    'FontSize',16,...
    'BackgroundColor',[0 156 29]/256,...
    'ForegroundColor',[0 0 0]);

% Rather than have buttons to flick through the images, I want instead to
% have three listboxes, one for Red/Green/Blue channels.  The user selects
% which colours go where
uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0 0.25 1 0.05],...
    'Style','text',...
    'String','Results',...
    'FontSize',24,...
    'BackgroundColor',[1 1 1]);
man.res(1) = uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0.05 0.05 0.3 0.2],...
    'Style','listbox',...
    'String','',...
    'Value',1,...
    'FontSize',16,...
    'Min',1,...
    'Max',3,...
    'BackgroundColor',[1 0.8 0.8]);
man.res(2) = uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0.35 0.05 0.3 0.2],...
    'Style','listbox',...
    'String','',...
    'Value',1,...
    'FontSize',16,...
    'Min',1,...
    'Max',3,...
    'BackgroundColor',[0.8 1 0.8]);
man.res(3) = uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0.65 0.05 0.3 0.2],...
    'Style','listbox',...
    'String','',...
    'Value',1,...
    'FontSize',16,...
    'Min',1,...
    'Max',3,...
    'BackgroundColor',[0.8 0.8 1]);

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [man] = segmentWindow2(src,event,fig,mode,range)
% This is the revised version for fused data - won't implement this version
% for the single mode toolbox just yet.  Aim to make it consistent with the
% QDS menu bar.

% Define a font size
fS = 14;

% Where should we draw everything
parent = fig.pan2;

% Opening text
uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0 0.95 1 0.05],...
    'Style','text',...
    'String','Segmentation etc',...
    'FontSize',24,...
    'BackgroundColor',[1 1 1]);

% Normalisation
uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0 0.85 0.5 0.1],...
    'Style','text',...
    'String','Normalisation',...
    'FontSize',fS,...
    'BackgroundColor',[1 1 1]);
man.norm = uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0.5 0.85 0.5 0.1],...
    'Style','popupmenu',...
    'String',{'None','TIC','PQN-Mean','PQN-Median'},...
    'Value',2,...
    'FontSize',fS);

% Transformation
uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0 0.8 0.5 0.1],...
    'Style','text',...
    'String','Transformation',...
    'FontSize',fS,...
    'BackgroundColor',[1 1 1]);
man.log = uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0.5 0.8 0.5 0.1],...
    'Style','popupmenu',...
    'String',{'None','Yes'},...
    'Value',2,...
    'FontSize',fS);

% Scaling
uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0 0.75 0.5 0.1],...
    'Style','text',...
    'String','Scaling',...
    'FontSize',fS,...
    'BackgroundColor',[1 1 1]);
man.scale = uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0.5 0.75 0.5 0.1],...
    'Style','popupmenu',...
    'String',{'None','UV'},...
    'Value',1,...
    'FontSize',fS);

% Add a thing to decide on the method for fusion in polarity switched data.
% This just needs to be a popupmenu
if strcmp(mode,'dual')
    uicontrol('Parent',parent,...
        'Units','normalized',...
        'Position',[0 0.7 0.5 0.1],...
        'Style','text',...
        'String','Fusion',...
        'FontSize',fS,...
        'BackgroundColor',[1 1 1]);

    man.fuse = uicontrol('Parent',parent,...
        'Units','normalized',...
        'Position',[0.5 0.7 0.5 0.1],...
        'Style','popupmenu',...
        'String',{'LL (Concat)','HL (PCA #)','HL (PCA %)'},...
        'Value',1,...
        'FontSize',fS);
    
    man.fuseText = uicontrol('Parent',parent,...
        'Units','normalized',...
        'Position',[0 0.65 0.5 0.1],...
        'Style','text',...
        'String','Number of PCs',...
        'FontSize',fS,...
        'BackgroundColor',[1 1 1],...
        'Tag','hlfusion',...
        'Visible','on');

    man.fuseComp = uicontrol('Parent',parent,...
        'Units','normalized',...
        'Position',[0.52 0.65+0.065 0.45 0.04],...
        'Style','edit',...
        'String','10',...
        'FontSize',fS,...
        'Tag','hlfusion',...
        'Visible','on');
    
    % Retro projection of scores, and loadings plot options...
    uicontrol('Parent',parent,...
        'Units','normalized',...
        'Position',[0 0.65 0.5 0.05],...
        'Style','text',...
        'String','Retro projection',...
        'FontSize',fS,...
        'BackgroundColor',[1 1 1],...
        'Tag','hlfusion',...
        'Visible','on');
        
    man.retroScores = uicontrol('Parent',parent,...
        'Units','normalized',...
        'Position',[0.6 0.675 0.15 0.025],...
        'Style','checkbox',...
        'String','S',...
        'FontSize',fS,...
        'BackgroundColor',[1 1 1],...
        'Tag','hlfusion',...
        'Visible','on',...
        'Enable','off',...
        'Value',0);
    
    man.retroLoadings = uicontrol('Parent',parent,...
        'Units','normalized',...
        'Position',[0.775 0.675 0.15 0.025],...
        'Style','checkbox',...
        'String','L',...
        'FontSize',fS,...
        'BackgroundColor',[1 1 1],...
        'Tag','hlfusion',...
        'Visible','on',...
        'Value',0,...
        'Enable','off');

end
% m/z range...
uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0 0.595-0.05 0.5 0.1],...
    'Style','text',...
    'String','m/z Range',...
    'FontSize',fS,...
    'BackgroundColor',[1 1 1]);
man.mzL = uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0.5 0.66-0.05 0.23 0.04],...
    'Style','edit',...
    'String',num2str(range(1)),...
    'FontSize',fS);
man.mzH = uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0.74 0.66-0.05 0.23 0.04],...
    'Style','edit',...
    'String',num2str(range(2)),...
    'FontSize',fS);

% Potential options...
uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0 0.525 0.5 0.05],...
    'Style','text',...
    'String','Analysis',...
    'FontSize',fS,...
    'BackgroundColor',[1 1 1]);
man.list = uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0.5 0.375 0.475 0.2],...
    'Style','listbox',...
    'String',{'PCA';'kMeans';'MMC';'None'},...
    'Value',1,...
    'FontSize',fS);%'Min',1,...'Max',3);

% A box to limit k for kmeans
man.maxClust = uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0.275 0.40 0.15 0.025],...
    'Style','edit',...
    'String','4',...
    'Value',1,...
    'FontSize',fS);
uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0.1725 0.40 0.1 0.025],...
    'Style','text',...
    'String','k <= ',...
    'FontSize',fS,...
    'BackgroundColor',[1 1 1]);


% Remove background pixels?
man.remBG = uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0.05 0.335 0.9 0.025],...
    'Style','checkbox',...
    'String','Remove background pixels?',...
    'Value',0,...
    'FontSize',fS,...
    'BackgroundColor',[1 1 1]);

% A button to 'do' what we wanted...
man.do = uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0.05 0.275 0.9 0.05],...
    'Style','pushbutton',...
    'String','Analyse!',...
    'FontSize',16,...
    'BackgroundColor',[0 156 29]/256,...
    'ForegroundColor',[0 0 0]);

% Rather than have buttons to flick through the images, I want instead to
% have three listboxes, one for Red/Green/Blue channels.  The user selects
% which colours go where
os = 0.04;
uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0 0.25-os 1 0.05],...
    'Style','text',...
    'String','Results',...
    'FontSize',24,...
    'BackgroundColor',[1 1 1]);
man.res(1) = uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0.05 0.05-os 0.3 0.2],...
    'Style','listbox',...
    'String','',...
    'Value',1,...
    'FontSize',16,...
    'Min',1,...
    'Max',3,...
    'BackgroundColor',[1 0.8 0.8]);
man.res(2) = uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0.35 0.05-os 0.3 0.2],...
    'Style','listbox',...
    'String','',...
    'Value',1,...
    'FontSize',16,...
    'Min',1,...
    'Max',3,...
    'BackgroundColor',[0.8 1 0.8]);
man.res(3) = uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0.65 0.05-os 0.3 0.2],...
    'Style','listbox',...
    'String','',...
    'Value',1,...
    'FontSize',16,...
    'Min',1,...
    'Max',3,...
    'BackgroundColor',[0.8 0.8 1]);

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function fusionBoxCallback(src,~,man)
% Show and alter the fusion boxes if we have high level fusion...

% Find handle of all 'hlfusion'-tagged entries
f0 = findobj('Tag','hlfusion');

% Get the value of the actual box
val = get(src,'Value');
str = get(src,'String');
str = str{val};

switch lower(str(1:2))
    
    case 'hl'
        
        % Make the boxes visible
        set(f0,'Visible','on');
        
        % Change the title of the box depending on what kind of fusion...
        switch lower(str(4:end))
            case '(pca #)'
                txt = 'Number of PCs';
                val = '10';
                
            case '(pca %)'
                txt = '% of variance';
                val = '75';
                
            otherwise
                % There is no otherwise
                txt = 'I have no idea';
                val = 'Oranges';
        end
        set(man.fuseText,'String',txt);
        set(man.fuseComp,'String',val);
        
    otherwise
        % To include low level concatenation
        set(f0,'Visible','off');
        
end


end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%