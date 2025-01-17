function desiQQQUpload(~,~,fig,defP)
%desiQQQUpload - upload triple quad data from selecting a folder

% Close annotation / manipulation windows
f0 = findobj('Tag','manipulation');
close(f0);
f0 = findobj('Name','annotation');
close(f0);

% Change the layout to just the two window view...
xxxEnforceLayoutChange(fig,'single','off');

% Clear the axes... but what if we have annotation boxes?
sz = size(get(fig.ax.opt(2),'CData'));
set(fig.ax.opt(2),'CData',ones(sz));
sz = size(get(fig.ax.ms1(2),'CData'));
set(fig.ax.ms1(2),'CData',ones(sz));
f0 = findobj('Type','patch');
delete(f0);
f0 = findobj('Type','scatter');
delete(f0);

% Gather the guidata and determine the best path - if possible...
dpn = guidata(fig.fig);
if ~isempty(dpn)
    path = dpn.file.dir;
    if ~exist(path,'dir')
        path = defP;
    end
    sl = strfind(path,filesep);
    path = path(1:sl(end-1));
    if exist(path,'dir')
        defP = path;
    end
    
    % Change the polymer icon if we can...
    %     if isfield(dpn.d1,'poly')
    %         set(fig.tb.removePoly,'CData',dpn.d1.poly.icon.normal);
    %     end

end

% Need to turn the grid off too...
set(fig.tb.grid,'State','off');
desiGrid(fig.tb.grid,[],fig);

% Ask the user for a directory...
pickDir = uigetdir(defP);
if pickDir == 0
    flag = 0;
else
    flag = 1;
end

% If no file selected, then quit/do nothing
if flag == 0
    set(fig.tb.new,'State','off');
    return
end

% We need to look inside for a bunch of raw files - if there are none then
% we cannot continue...
rawFind = fileFinderAll(pickDir,'raw',true);
numF = size(rawFind,1);

% Check that there are some files in here... (but can't be sure that they
% are QQQ raw files rather than just other raw files
if numF == 0
    disp('NO RAW FILES FOUND - QUITTING');
    return
end

% Now we need to link into Paolo's import function - just put it in a
% try/catch loop in case of unforseen circumstances
%try
    [qmz,qsp,~] = desiQQQImport(pickDir);
%catch err
    %err
    %error('Some problem with the QQQ import code');
%end

% Define unique mz values from the first pixel - the others are/should be
% the same
unqMZ = squeeze(qmz(1,1,:));

% What is the folder name only?
sl = strfind(pickDir,filesep);
file.dir = pickDir(1:sl(end));
file.nam = [pickDir(sl(end)+1:end) '.qqq'];

% Now save the results into the structure as required.
dpn.file = file;
dpn.opts = 'QQQ import';

dpn.d1.mz = unqMZ;
dpn.d1.sp = qsp;

dpn.fig = fig;
dpn.defP = file.dir;

dpn.mode = 'single';

% Add the guidata...
guidata(fig.fig,dpn);

% Update the images...
dpnUpdateMS([],[],fig,'force');


return

file.ext = fileExtension(file.nam);

% Reformat the .dat files to the .raw file name instead
switch lower(file.ext)
    case 'dat'
        sl = strfind(file.dir,filesep);
        sl = sl(end-1);
        file.nam = file.dir(sl+1:end-1);
        file.dir = file.dir(1:sl);
        file.ext = 'raw';
end

% Traditionally we would display the options, but here instead we draw in
% the side menu...
        
% Get the options
%[opts,flag] = getOptions(file);
% [opts,flag] = desiGetProcOptions(file);
% if ~flag
%     return;
% end

% I want to display this in the menubar / figure title so that I know which
% file it is
set(fig.fig,'Name',['DESI Processing: ' file.nam]);

% Now decide what to do with it...
switch lower(file.ext)
    
    case {'imzml','raw'}

        
        %Draw the window for imzML / Raw files
        [man] = manipulateWindow(fig,file);
        set(man.finish,'Callback',{@desiFileProcess,fig,man,file,defP});
        
    case 'mat'
        % This is the option for reloading the saved files
        dpnMatlabLoad(file,fig);
        
    case 'h5'
        % This is the legacy support...will be difficult to get all the
        % structural elements...
        desiH5Load(fig,file,defP);
        
    case 'txt'
        % Analye files from raw files - potentially open to abuse and
        % failure
        desiWatersAnalyte(fig,file,defP);
        
    otherwise
        % Error - there are no other supported filetypes
end
      
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [man] = manipulateWindow(fig,file)
% Window with the little options for manipulating the figure...

% Get the defaults
[opts,~] = desiGetProcOptions(file,'force');

% This is where we draw everything
parent = fig.pan2;

fS = 14;

% Heading
uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0 0.95 1 0.05],...
    'Style','text',...
    'String','Processing',...
    'FontSize',24,...
    'BackgroundColor',[1 1 1]);

%%%%

switch lower(file.ext)
    case 'imzml'
        methods = {'Normal';'Nazanin'};
        fileVal = 1;
        opts = opts.imzml;
        roi = 'off';
    case 'raw'
        methods = {'Centroid','Profile'};
        fileVal = 2;
        opts = opts.raw;
        roi = 'on';
end

% Filetype
uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0 0.85 0.5 0.1],...
    'Style','text',...
    'String','File Tpe',...
    'FontSize',fS,...
    'BackgroundColor',[1 1 1]);
man.file = uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0.5 0.85 0.5 0.1],...
    'Style','popupmenu',...
    'String',{'imzML';'RAW'},...
    'Value',fileVal,...
    'FontSize',fS,...
    'Enable','off');

% Method
uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0 0.8 0.5 0.1],...
    'Style','text',...
    'String','Raw Data',...
    'FontSize',fS,...
    'BackgroundColor',[1 1 1]);
man.method = uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0.5 0.8 0.5 0.1],...
    'Style','popupmenu',...
    'String',methods,...
    'Value',1,...
    'FontSize',fS);

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
    'String',num2str(opts.mzRange(1)),...
    'FontSize',fS);
man.mzH = uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0.74 0.66-0.05 0.23 0.04],...
    'Style','edit',...
    'String',num2str(opts.mzRange(2)),...
    'FontSize',fS);

% m/z resolution...
uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0 0.595-0.1 0.5 0.1],...
    'Style','text',...
    'String','m/z Resolution',...
    'FontSize',fS,...
    'BackgroundColor',[1 1 1]);
man.mzRes = uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0.5 0.66-0.1 0.47 0.04],...
    'Style','edit',...
    'String',num2str(opts.mzRes),...
    'FontSize',fS);

% ppm shift...
uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0 0.595-0.15 0.5 0.1],...
    'Style','text',...
    'String','ppm Shift',...
    'FontSize',fS,...
    'BackgroundColor',[1 1 1]);
man.ppm = uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0.5 0.66-0.15 0.47 0.04],...
    'Style','edit',...
    'String',num2str(opts.ppmRes),...
    'FontSize',fS);

% mz fraction...
uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0 0.595-0.2 0.5 0.1],...
    'Style','text',...
    'String','m/z Fraction',...
    'FontSize',fS,...
    'BackgroundColor',[1 1 1]);
man.mzFrac = uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0.5 0.66-0.2 0.47 0.04],...
    'Style','edit',...
    'String',num2str(opts.mzFrac),...
    'FontSize',fS);

% ROI
uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0 0.25 0.5 0.1],...
    'Style','text',...
    'String','ROI',...
    'FontSize',fS,...
    'BackgroundColor',[1 1 1]);
man.roi = uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0.5 0.25 0.5 0.1],...
    'Style','popupmenu',...
    'String',{'Off';'On'},...
    'Value',fileVal,...
    'FontSize',fS,...
    'Enable',roi);


% Finish button
man.finish = uicontrol('Parent',parent,...
    'Units','normalized',...
    'Position',[0.05 0.01 0.9 0.05],...
    'Style','pushbutton',...
    'String','Import!',...
    'BackgroundColor',[0.5 0.9 0.5],...
    'FontSize',fS + 4);

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

