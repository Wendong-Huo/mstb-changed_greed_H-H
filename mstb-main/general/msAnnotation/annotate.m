function annotate(mz,sp,grp,varargin)
%annotate - GUI to direct annotation of data

% Define input arguments...
[opts] = readArgsData(varargin);

% Get the adduct lists...
[~,add.pos,~] = adductLists('p');
[~,add.neg,~] = adductLists('n');

% First we need to draw a window
[fig] = annoDraw(add,opts);

% Add the callbacks
set(fig.polarity,'Callback',{@changePolarity,fig,add});
set(fig.folder,'Callback',  {@changeFolder,fig});
set(fig.go,'Callback',{@pressGo,fig,mz,sp,grp});
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [opts] = readArgsData(argsin)
% Read the arguments and then the data if it wasn't passed

% Define the defaults here
opts.doImg      = false;
opts.preNorm    = 1;
opts.folder     = [pwd filesep];
opts.file       = ['Anno-' datestr(now,'yymmdd-HHMMSS')];


% Run through each pair
nArgs = length(argsin);
for i = 1:2:nArgs
    if strcmpi('unicorn',argsin{i}) || strcmpi('image',argsin{i})
        tmp = argsin{i+1};        
        if islogical(tmp)
            opts.doImg = tmp;
        end
        
    elseif strcmpi('prenorm',argsin{i}) ||strcmpi('norm',argsin{i})
        tmp = argsin{i+1};
        switch lower(tmp)
            case 'none'
                opts.preNorm = 1;
            case 'tic'
                opts.preNorm = 2;
            case 'pqn-median'
                opts.preNorm = 3;
            case 'pqn-mean'
                opts.preNorm = 4;
            otherwise
                error('Unknown normalisation method');
        end
        
    elseif strcmpi('folder',argsin{i})
        tmp = argsin{i+1};
        if exist(tmp,'dir')
            if ~strcmp(tmp(end),filesep)
                tmp = [tmp filesep];
            end
            opts.folder = tmp;
        end
        
    elseif strcmpi('file',argsin{i})
        tmp = argsin{i+1};
        if ischar(tmp)
            opts.file = tmp;
        end
        
    end
end

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [fig] = annoDraw(add,opts)
% Draw a simple annotation window

f0 = findobj('Tag','annotate');
close(f0);

if opts.doImg
    try
        load(deSlash('general/annotation/annoImg.mat'));
    catch
        opts.doImg = false;
    end
end

fS = 16;

fig.fig = figure('Name','Annotate',...
    'Units','normalized',...
    'Position',[0.25 0.25 0.5 0.5],...
    'Toolbar','none',...
    'MenuBar','none',...
    'Tag','annotate');

uicontrol('Parent',fig.fig,...
    'Units','normalized',...
    'Position',[0.1 0.9 0.8 0.1],...
    'Style','text',...
    'String','m/z annotation & export',...
    'FontSize',40,...
    'FontWeight','bold');

if opts.doImg
    fig.uni = axes('Parent',fig.fig,...
        'Units','normalized',...
        'Position',[0.77 0 0.3 0.3]);
    bw = sum(a.cdata == 0,3) ~= 3;
    ff = imagesc(a.cdata);
    set(ff,'AlphaData',bw);
    axis off;
    axis square;
end

axes('Parent',fig.fig,...
    'Units','normalized',...
    'Position',[0.025 0.85 0.95 0.05]);
imagesc(rand(3,100,3));
axis off

% Database
uicontrol('Parent',fig.fig,...
    'Units','normalized',...
    'Position',[0.05 0.7 0.1 0.1],...
    'Style','text',...
    'String','Database:',...
    'FontSize',fS,...
    'FontWeight','bold',...
    'HorizontalAlignment','left');

fig.database = uicontrol('Parent',fig.fig,...
    'Units','normalized',...
    'Position',[0.15 0.7 0.2 0.1],...
    'Style','listbox',...
    'String',{'Dipa';'Luisa'},...
    'Value',1,...
    'FontSize',fS);

% Univariate test
uicontrol('Parent',fig.fig,...
    'Units','normalized',...
    'Position',[0.05 0.5 0.1 0.1],...
    'Style','text',...
    'String','Univariate:',...
    'FontSize',fS,...
    'FontWeight','bold',...
    'HorizontalAlignment','left');

fig.univariate = uicontrol('Parent',fig.fig,...
    'Units','normalized',...
    'Position',[0.15 0.5 0.2 0.1],...
    'Style','listbox',...
    'String',{'ANOVA';'Kruskal-Wallis'},...
    'Value',1,...
    'FontSize',fS,...
    'Enable','off');

% Normalisation
uicontrol('Parent',fig.fig,...
    'Units','normalized',...
    'Position',[0.05 0.3 0.1 0.1],...
    'Style','text',...
    'String','Normalisation:',...
    'FontSize',fS,...
    'FontWeight','bold',...
    'HorizontalAlignment','left');
if opts.preNorm > 1
    st = 'off';
    val = opts.preNorm;
else
    st = 'on';
    val = 1;
end
fig.norm = uicontrol('Parent',fig.fig,...
    'Units','normalized',...
    'Position',[0.15 0.3 0.2 0.1],...
    'Style','listbox',...
    'String',{'None';'TIC';'PQN-Median';'PQN-Mean'},...
    'Value',val,...
    'FontSize',fS,...
    'Enable',st);

% ppm tolerance
uicontrol('Parent',fig.fig,...
    'Units','normalized',...
    'Position',[0.05 0.1 0.15 0.1],...
    'Style','text',...
    'String','Tolerance (�ppm):',...
    'FontSize',fS,...
    'FontWeight','bold',...
    'HorizontalAlignment','left');

fig.ppm = uicontrol('Parent',fig.fig,...
    'Units','normalized',...
    'Position',[0.2 0.15 0.15 0.05],...
    'Style','edit',...
    'String','10',...
    'FontSize',fS);

% Polarity
uicontrol('Parent',fig.fig,...
    'Units','normalized',...
    'Position',[0.40 0.7 0.1 0.1],...
    'Style','text',...
    'String','Polarity:',...
    'FontSize',fS,...
    'FontWeight','bold',...
    'HorizontalAlignment','left');

fig.polarity = uicontrol('Parent',fig.fig,...
    'Units','normalized',...
    'Position',[0.50 0.7 0.2 0.1],...
    'Style','listbox',...
    'String',{'Negative';'Positive'},...
    'Value',1,...
    'FontSize',fS);

% Adducts
uicontrol('Parent',fig.fig,...
    'Units','normalized',...
    'Position',[0.40 0.5 0.1 0.1],...
    'Style','text',...
    'String','Adducts:',...
    'FontSize',fS,...
    'FontWeight','bold',...
    'HorizontalAlignment','left');

fig.adduct = uicontrol('Parent',fig.fig,...
    'Units','normalized',...
    'Position',[0.50 0.15 0.2 0.45],...
    'Style','listbox',...
    'String',add.neg,...
    'Value',1,...
    'FontSize',fS,...
    'Min',1,...
    'Max',3);

% Folder
uicontrol('Parent',fig.fig,...
    'Units','normalized',...
    'Position',[0.05 0.01 0.1 0.05],...
    'Style','text',...
    'String','Folder:',...
    'FontSize',fS,...
    'FontWeight','bold',...
    'HorizontalAlignment','left');

fig.folder = uicontrol('Parent',fig.fig,...
    'Units','normalized',...
    'Position',[0.15 0.01 0.2 0.05],...
    'Style','pushbutton',...
    'String',opts.folder,...
    'FontSize',fS);

% Name
uicontrol('Parent',fig.fig,...
    'Units','normalized',...
    'Position',[0.4 0.01 0.1 0.05],...
    'Style','text',...
    'String','Filename:',...
    'FontSize',fS,...
    'FontWeight','bold',...
    'HorizontalAlignment','left');

fig.file = uicontrol('Parent',fig.fig,...
    'Units','normalized',...
    'Position',[0.5 0.01 0.2 0.05],...
    'Style','edit',...
    'String',opts.file,...
    'FontSize',fS);

% pq value threshold
uicontrol('Parent',fig.fig,...
    'Units','normalized',...
    'Position',[0.75 0.7 0.15 0.1],...
    'Style','text',...
    'String','q <',...
    'FontSize',fS,...
    'FontWeight','bold',...
    'HorizontalAlignment','left');

fig.pqthresh = uicontrol('Parent',fig.fig,...
    'Units','normalized',...
    'Position',[0.80 0.7 0.195 0.1],...
    'Style','listbox',...
    'String',{'All';'0.05';'0.01';'0.001'},...
    'Value',1,...
    'FontSize',fS);


% Go
fig.go = uicontrol('Parent',fig.fig,...
    'Units','normalized',...
    'Position',[0.80 0.01 0.1 0.09],...
    'Style','pushbutton',...
    'String','Go',...
    'FontSize',fS);

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function changePolarity(src,~,fig,add)
% Switch the adducts depending on polarity

value = get(src,'Value');

switch value
    case 1
        set(fig.adduct,'String',add.neg,'Value',1);
    case 2
        set(fig.adduct,'String',add.pos,'Value',13);
end

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function changeFolder(~,~,fig)
% Change the folder

fold = uigetdir;

% Quit if no folder provided
if isnumeric(fold)
    return
end

% Set the folder
set(fig.folder,'String',[fold filesep]);

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function pressGo(~,~,fig,mz,sp,grp)

% Make a move
if isfield(fig,'uni')
    enactMove(fig);
end

% Need to gather up the options here...

% Choice of database
tmp = get(fig.database,'Value');
switch tmp
    case 1
        opts.db = deSlash('general/lipid/DB1.mat');
    case 2
        opts.db = deSlash('general/lipid/DBx.mat');
end

% Choice of statistic
tmp = get(fig.univariate,'Value');
switch tmp
    case 1
        opts.univariate = 'anova';
    case 2
        opts.univariate = 'kruskalwallis';
end

% Normalisation
tmp = get(fig.norm,'Value');
switch tmp
    case 1
        opts.norm = 'none';
    case 2
        opts.norm = 'tic';
    case 3 
        opts.norm = 'pqn-median';
    case 4
        opts.norm = 'pqn-mean';
end
state = get(fig.norm,'Enable');
if strcmp(state,'on')
    sp = jsmNormalise(sp,opts.norm,0,1,[]);
end

% ppm tolerance
tmp = get(fig.ppm,'String');
try
    opts.ppm = str2double(tmp);
    if isnan(opts.ppm)
        opts.ppm = 10;
        set(fig.ppm,'String',10);
    end
catch
    set(fig.ppm,'String',10');
    opts.ppm = 10;
end

% Polarity
tmp = get(fig.polarity,'Value');
switch tmp
    case 1 
        opts.polarity = 'neg';
    case 2
        opts.polarity = 'pos';
end

% Adducts...
adds = get(fig.adduct,'String')';
tmp = get(fig.adduct,'Value');
opts.adducts = adds(tmp);

% pq value threshold
adds = get(fig.pqthresh,'String')';
tmp = get(fig.pqthresh,'Value');
opts.qThresh = adds{tmp};

% Folder
opts.fold = get(fig.folder,'String');

% Name
opts.file = get(fig.file,'String');

% These functions are the two that are needed to work it!
[db,ass] = annotateMZ(mz,...
    'Polarity',opts.polarity,...
    'Adducts',opts.adducts,...
    'ppm',opts.ppm,...
    'Database',opts.db);

% Output these somewhere...
annotateOP2(mz,sp,grp,ass,db,[opts.fold opts.file '.txt'],opts.qThresh);

% Make a move
if isfield(fig,'uni')
    enactMove(fig);
end

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function enactMove(fig)

origPos = get(fig.uni,'Position');

shift = fliplr(linspace(-origPos(3),origPos(1),100));
shift2 = fliplr(linspace(origPos(1),1,20));
shift = [shift shift2];

for n = 1:numel(shift)
    tmp = origPos;
    tmp(1) = shift(n);
    set(fig.uni,'Position',tmp);
    drawnow;
end

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%