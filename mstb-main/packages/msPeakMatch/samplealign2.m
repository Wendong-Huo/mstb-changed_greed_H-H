function [I,J] = samplealign2(X,Y,varargin)
%SAMPLEALIGN aligns two data sets containing sequential observations.
%
%  [I,J] = SAMPLEALIGN(X,Y) aligns the observations in two matrices of
%  data, X and Y, by introducing gaps. X and Y are matrices of data where
%  rows correspond to observations or samples, and columns correspond to
%  features or dimensions. X and Y can have different number of rows, but
%  must have the same number of columns. The first column is the reference
%  dimension and must contain unique values in ascending order. The
%  reference dimension could contain sample indices of the observations or
%  a measurable value, such as time. The SAMPLEALIGN function uses a
%  dynamic programming algorithm to minimize the sum of positive scores
%  resulting from pairs of observations that are potential matches and the
%  penalties resulting from the insertion of gaps. Return values I and J
%  are column vectors containing indices that indicate the matches for each
%  row (observation) in X and Y respectively. When you do not specify
%  return values, SAMPLEALIGN does not run the dynamic programming
%  algorithm, however you can explore the constrained space, the dynamic
%  programming network and the observations to align by using the
%  'SHOWCONSTRAINTS', 'SHOWNETWORK', and 'SHOWALIGNMENT' input arguments.
%
%  SAMPLEALIGN(...,'BAND',B) specifies a maximum allowable distance between
%  observations along the reference dimension, thus limiting the number
%  potential matches between observations in two data sets. Let S be the
%  value in the reference dimension for any given observation (row) in one
%  data set, then that observation is matched only with observations in the
%  other data set whose values in the reference dimension fall within S +/-
%  B. Only these potential matches are passed to the algorithm for further
%  scoring. B can be a scalar or a function specified using @(z), where z
%  is the mid-point between a given observation in one data set and a given
%  observation in the other data set. Default B is Inf.
%
%  The 'BAND' constraint reduces the time and memory complexity of the
%  algorithm from O(MN) to O(sqrt(MN)*K), where M and N are the number of
%  observations in X and Y respectively, and K is a small constant such
%  that K<<M and K<<N. Adjust B to the maximum expected shift between
%  X(:,1) and Y(:,1).
%
%  SAMPLEALIGN(...,'WIDTH',[U,V]) limits the number of potential matches
%  between observations in two data sets; that is, each observation in X is
%  scored to the closest U observations in Y, and each observation in Y is
%  scored to the closest V observations in X. Only these potential matches
%  are passed to the algorithm for further scoring. 'WIDTH' is either a
%  two-element vector, [U, V] or a scalar that is used for both U and V.
%  Closeness is measured using only the first column (reference dimension)
%  in each data set. Default is Inf if 'BAND' is specified; otherwise
%  default is 10.
%
%  The 'WIDTH' constraint reduces the time and memory complexity of the
%  algorithm from O(MN) to O(sqrt(MN)*sqrt(UV)), where M and N are the
%  number of observations in X and Y respectively, and U and V are small
%  such that U<<M and V<<N.
%
%  If you specify both 'BAND' and 'WIDTH', only pairs of observations that
%  meet both constraints are considered potential matches and passed to the
%  dynamic programming algorithm for scoring.
%
%  Specify 'WIDTH' when you do not have a good estimate for the 'BAND'
%  property. To get an indication of the memory required to run the
%  algorithm with specific 'BAND' and 'WIDTH' parameters on your data sets,
%  run SAMPLEALIGN, but do not specify return values and set
%  'SHOWCONSTRAINTS' to true.
%
%  SAMPLEALIGN(...,'GAP',{G,H}) specifies the observation dependent terms
%  for assigning gap penalties. G is either a scalar or a function handle
%  specified using @(X), and H is either a scalar or a function handle
%  specified using @(Y). The functions @(X) and @(Y) must calculate the
%  penalty for each observation (row) when it is matched to a gap in the
%  other data set. The functions @(X) and @(Y) must return a column vector
%  with the same number of rows as X or Y, containing the gap penalty for
%  each observation (row). When 'GAP' is set either to a single scalar, or
%  a single function handle then the same value (or function handle) is
%  used for both G and H.
%
%  Gap penalties employed in the dynamic programming algorithm are computed
%  as follows. GPX is the gap penalty for matching observations from the
%  first data set X to gaps inserted in the second data set Y, and is the
%  product of two terms: GPX = G * QMS. The term G takes its value as a
%  function of the observations in X. With this, the user can introduce gap
%  penalties dependent on the reference column, dependent on other columns,
%  or, dependent on both. Similarly, GPY is the gap penalty for matching
%  observations from Y to gaps inserted in X, and is the product of two
%  terms: GPY = H * QMS. The term H takes its value as a function of the
%  observations in Y.
%
%  The term QMS is the 0.75 quantile of the score for the pairs of
%  observations that are potential matches (that is, pairs that comply with
%  the 'BAND' and 'WIDTH' constraints). If G and H are positive scalars,
%  then GPX and GPY are independent of the observation where the gap is
%  being inserted. Default 'GAP' is 1, that is, both G and H are 1, which
%  indicates that the default penalty for gap insertions in both sequences
%  is equivalent to the 0.75 quantile of the score for the pairs of
%  observations that are potential matches.
%
%  'GAP' defaults to a relatively safe value. However, the success of the
%  algorithm depends on the fine tuning of the gap penalties, which is
%  application dependent. When the gap penalties are large relative to the
%  score of the correct matches, samplealign returns alignments with fewer
%  gaps, but with more incorrectly aligned regions. When the gap penalties
%  are smaller, the output alignment contains longer regions with gaps and
%  fewer matched observations. Set 'SHOWNETWORK' to true to compare the gap
%  penalties to the score of matched observations in different regions of
%  the alignment.
%
%  SAMPLEALIGN(...,'QUANTILE',Q) specifies the quantile value used to
%  calculate the term QMS, which is used by the 'GAP' property to calculate
%  gap penalties. Q is a scalar between 0 and 1. Default is 0.75. Set Q to
%  an empty array ([]) to make the gap penalties independent of QMS, that
%  is GPX and GPY are functions of only the G and H input parameters
%  respectively.
%
%  SAMPLEALIGN(...,'DISTANCE',D) specifies a function to calculate the
%  distance between pairs of observations that are potential matches. D is
%  a function handle specified using @(R,S). The function @(R,S) must take
%  as arguments, R and S, matrices that have the same number of rows and
%  columns, and whose paired rows represent all potential matches of
%  observations in X and Y respectively. The function @(R,S) must return a
%  column vector of positive values with the same number of elements as
%  rows in R and S. Default is the Euclidean distance between the pairs.
%
%  By default All columns in X and Y, including the reference dimension,
%  are considered when calculating distances. If you do not want to include
%  the reference dimension in the distance calculations, use the 'WEIGHT'
%  property to exclude it.
%
%  SAMPLEALIGN(...,'WEIGHTS',W) controls the inclusion/exclusion of columns
%  (features) or the emphasis of columns (features) when calculating the
%  when calculating the distance score between observations that are
%  potential matches. W can be a logical row vector that specifies columns
%  in X and Y. W can also be a numeric row vector with the same number of
%  elements as columns in X and Y, that specifies the relative weights of
%  the columns (features). Default is a logical row vector with all
%  elements set to true.
%
%  Using a numeric row vector for W and setting some values to zero can
%  simplify the distance calculation when the data sets have many columns
%  (features).
%
%  The weight values are not considered when computing the constrained
%  alignment space, that is when using the 'BAND' or 'WIDTH' properties.
%
%  SAMPLEALIGN(...,'SHOWCONSTRAINTS',true) displays the search space
%  constrained by the input parameters 'BAND' and 'WIDTH', giving an
%  indication of the memory required to run the dynamic programming
%  algorithm. When you set 'SHOWCONSTRAINTS' to true, and do not specify
%  return values, SAMPLEALIGN does not run the dynamic programming
%  algorithm. This lets you explore the constrained space without running
%  into potential memory problems. 'SHOWCONSTRAINTS' defaults to false.
%
%  SAMPLEALIGN(...,'SHOWNETWORK',true) displays the dynamic programming
%  network, the match scores, the gap penalties, and the winning path (when
%  possible). 'SHOWNETWORK' defaults to false.
%
%  SAMPLEALIGN(...,'SHOWALIGNMENT',true) displays the first and second
%  columns of the X and Y data sets in the abscissa and the ordinate
%  respectively, of a two dimensional plot. Links between all the potential
%  matches that meet the constraints are displayed, and the matches
%  belonging to the output alignment are highlighted (when possible). Set
%  'SHOWALIGNMENT' to an integer to plot a different column of the inputs
%  in the ordinate. 'SHOWALIGNMENT' defaults to false.
%
%  Examples:
%
%     % Warp a sine wave with a smooth function such that it follows
%     % closely the cyclical sunspot activity, (a.k.a. Wolfer number):
%     load sunspot.dat
%     years = (1700:1990)';
%     T = 11.038; % approximate period (years)
%     f = @(y) 60 + 60 * sin(y*(2*pi/T));
%     [i,j] = samplealign([years f(years)],sunspot,'weights',[0 1],...
%                         'showalignment',true);
%     [p,s,mu] = polyfit(years(i),years(j),15);
%     wy = @(y) polyval(p,(y-mu(1))./mu(2));
%     years = (1700:1/12:1990)'; %plot warped signal monthly
%     figure
%     plot(sunspot(:,1),sunspot(:,2),years,f(years),wy(years),f(years))
%     legend('Sunspots','Unwarped Sine Wave','Warped Sine Wave')
%     title('Smooth Warping Example')
%
%     % Recover a non-linear warping between two signals that contain
%     % noisy Gaussian peaks:
%     peakLoc = [30 60 90 130 150 200 230 300 380 430];
%     peakInt = [7 1 3 10 3 6 1 8 3 10];
%     time = 1:450;
%     comp = exp(-(bsxfun(@minus,time,peakLoc')./5).^2);
%     sig_1 = (peakInt + rand(1,10)) * comp + rand(1,450);
%     sig_2 = (peakInt + rand(1,10)) * comp + rand(1,450);
%     wf = @(t) 1 + (t<=100).*0.01.*(t.^2) + (t>100).*(310+150*tanh(t./100-3));
%     sig_2 = interp1(time,sig_2,wf(time),'pchip');
%     [i,j] = samplealign([time;sig_1]',[time;sig_2]','weights',[0,1],...
%                          'band',35,'quantile',.5);
%     figure
%     sig_3 = interp1(time,sig_2,interp1(i,j,time,'pchip'),'pchip');
%     plot(time,sig_1,time,sig_2,time,sig_3)
%     legend('Reference','Distorted Signal','Corrected Signal')
%     title('Non-linear Warping Example')
%     figure
%     plot(time,wf(time),time,interp1(j,i,time,'pchip'))
%     legend('Distorting Function','Estimated Warping')
%
%  See also DIFFPROTDEMO, LCMSDEMO, MSALIGN, MSHEATMAP, MSPALIGN,
%  MSPPRESAMPLE, MSPREPRODEMO, MSRESAMPLE.

%  References:
%
%  [1] C. S. Myers and L. R. Rabiner. A comparative study of several
%      dynamic time-warping algorithms for connected word recognition. The
%      Bell System Technical Journal, 60(7):1389-1409, Sept. 1981.
%  [2] H. Sakoe and S. Chiba. Dynamic programming algorithm optimization
%      for spoken word recognition. IEEE Trans. Acoustics, Speech and
%      Signal Processing, ASSP-26(1):43-49, Feb. 1978.

%  Copyright 2007-2012 The MathWorks, Inc.
%
%
% Heavily modified by JSM in order to adapt to MS imaging data. This is not
% the original function, and calculations such as for distance / band / etc
% will not perform as expected here.


%%% Validate mandatory inputs %%%
[nX,nD] = size(X);
[nY,n]  = size(Y);

if ~isnumeric(X) || ~isnumeric(Y) || ~isreal(X) || ~isreal(Y)
    error(message('bioinfo:samplealign:illegalType'))
end
if n~=nD || nX<2 || nY<2  || n==0
    error(message('bioinfo:samplealign:badSize'))
end

%%% Optional input PPV parsing %%%
[band,bandIsDefault,widthX,widthY,widthIsDefault,gapX,gapY, ...
    distance,weights, showConstraints, showAlignment,showNetwork, ...
    quantileValue,computeQuantile,axisLink] = parse_inputs(nD,varargin{:});


%%% Initialize some figure handles
fhAli=NaN;fhCon1=NaN;fhCon2=NaN;fhNet=NaN;

%%% Get and check the reference vectors (first column of the inputs) %%%
x = double(X(:,1));
y = double(Y(:,1));
if ~issorted(x) || ~issorted(y) || ...
        isnan(x(end)) || isnan(y(end)) || ...
        isinf(x(end)) || isinf(y(end))
            error(message('bioinfo:samplealign:invalidReferenceDimension'))
end

if showAlignment % save dimensions that are to be plotted in the showAlignment figure
    xa = X(:,showAlignment);
    ya = Y(:,showAlignment);
end

%%% Calculate position dependent gap terms %%%
if isa(gapX,'function_handle')
    gapXf = gapX;
    try
        gapX = gapXf(X);
    catch theException
        error(message('bioinfo:samplealign:ErrorInUserGapXFunction', func2str( gapXf ), theException.message));
    end
    if ~isnumeric(gapX) || ~(isscalar(gapX) || (isvector(gapX)&&(size(gapX,1)==nX)))
        error(message('bioinfo:samplealign:UserGapXFunctionBadReturn', func2str( gapXf )));
    end
end
if isa(gapY,'function_handle')
    gapYf = gapY;
    try
        gapY = gapYf(Y);
    catch theException
        error(message('bioinfo:samplealign:ErrorInUserGapYFunction', func2str( gapYf ), theException.message));
    end
    if ~isnumeric(gapY) || ~(isscalar(gapY) || (isvector(gapY)&&(size(gapY,1)==nY)))
        error(message('bioinfo:samplealign:UserGapYFunctionBadReturn', func2str( gapYf )));
    end
end

%%% Reduce and weight observations, used later for computing distances %%%
if ~all(weights)
    h = weights>0;
    X = X(:,h);
    Y = Y(:,h);
    weights = weights(h);
    if isempty(weights)
        error(message('bioinfo:samplealign:tooFewDimensions'))
    end
end
if ~islogical(weights)
    X = bsxfun(@times,X,weights');
    Y = bsxfun(@times,Y,weights');
end
if any(any(isnan(X))|any(isinf(X))|any(isnan(Y))|any(isinf(Y)))
    error(message('bioinfo:samplealign:nansorinfsInInputs'))
end

%%% Find the likely matches that comply with the BAND constraint %%%
h = zeros(nX,1); % contains first valid y for each x
g = zeros(nX,1); % contains last valid y for each x
up=1; bot=1;
if isa(band,'function_handle')
    try
        for i = 1:nX
            while (up<=nY) && (x(i)-y(up) > band((x(i)+y(up))/2))
                up = up+1;
            end
            while (bot<=nY) && (y(bot)-x(i) <= band((y(bot)+x(i))/2))
                bot = bot+1;
            end
            h(i) = up;
            g(i) = bot-1;
        end
    catch topErr
        try
            ev1 = band((x(i)+y(up))/2);
        catch theException
            error(message('bioinfo:samplealign:ErrorInBandFunction', func2str( band ), sprintf( '%f', (x( i ) + y( up ))/2 ), theException.message));
        end
        try
            ev2 = band((y(bot)+x(i))/2);
        catch theException
            error(message('bioinfo:samplealign:ErrorInBandFunction', func2str( band ), sprintf( '%f', (y( bot ) + x( i ))/2 ), theException.message));
        end
        if ~isscalar(ev1) || ~isscalar(ev2)
            error(message('bioinfo:samplealign:BandFunctionReturnsIncorrectSize', func2str( band )))
        end
        rethrow(topErr)
    end
elseif band(1)>(max(x(end),y(end))-min(x(1),y(1))) % from band to band(1)
    h(:) = 1;
    g(:) = nY;
else
    % So what happens if we try to introduce a variable (i.e. ppm-like)
    % band tolerance thing... Need to change the code slightly to make band
    % depend on the m/z values... If numel(band) is 1 then we use it
    % 'fixed', if numel(band) isn't 1 then is needs to be the same length
    % as the cmz vector.  Originally this would induce an error.
    if numel(band) == 1    
        % This is the original code            
        for i = 1:nX
            while (up<=nY) && (x(i)-y(up) > band)
                up = up+1;
            end
            while (bot<=nY) && (y(bot)-x(i) <= band)
                bot = bot+1;
            end
            h(i) = up;
            g(i) = bot-1;
        end
        
    elseif numel(band) == nX
        % This duplicates the code above and changes band to band(i)
        for i = 1:nX
            while (up<=nY) && (x(i)-y(up) > band(i))
                up = up+1;
            end
            while (bot<=nY) && (y(bot)-x(i) <= band(i))
                bot = bot+1;
            end
            h(i) = up;
            g(i) = bot-1;
        end
        
    else
        error('incorrect size of band shift vector');
    end
end

%%% Find the likely matches that comply with the WIDTH constraints %%%
if widthX>=nX || widthY>=nY % each x gets all the samples in y
    c = ones(nX,1);
    d = nY(ones(nX,1));
else
    % find the first and last valid x for each y and put them in bs and be
    keps = mean(diff(x))/1e10;
    t = sortrows([filter(accumarray([1;widthX+1],[1 1],[widthX+1 1]),2,x)+keps ones(nX,1);y zeros(nY,1)])*[0;1];
    ct =  cumsum(t);
    bs = max(1,ct(~t)-widthX+1);
    r = 1;
    while r
        r = find((x(bs)==x(max(1,bs-1)))&(bs>1));
        bs(r) = bs(r)-1;
    end
    be = max(widthX+1,ct(~t));
    r = 1;
    while r
        r = find((max(y-x(bs),x(be)-y)>=x(min(nX,be+1))-y-keps)&(be<nX));
        be(r) = be(r)+1;
    end
    
    % find the first and last valid y for each x and put them in c and d
    keps = mean(diff(y))/1e10;
    t = sortrows([filter(accumarray([1;widthY+1],[1 1],[widthY+1 1]),2,y)+keps ones(nY,1);x zeros(nX,1)])*[0;1];
    ct =  cumsum(t);
    c = max(1,ct(~t)-widthY+1);
    r = 1;
    while r
        r = find((y(c)==y(max(1,c-1)))&(c>1));
        c(r) = c(r)-1;
    end
    d = max(widthY,ct(~t));
    r = 1;
    while r
        r = find((max(x-y(c),y(d)-x)>=y(min(nY,d+1))-x-keps)&(d<nY));
        d(r) = d(r)+1;
    end
    
    % Coalesce bs and be into c and d using an 'or' logic
    be = cumsum(accumarray(be(be<nX),1,[nX 1]))+1;
    bs = cumsum(accumarray(bs,1,[nX 1]));
    t = be<bs;
    c(t) = min(be(t),c(t));
    d(t) = max(bs(t),d(t));
end

if showConstraints
    fhCon1 = figure; hold on; axis equal
    ahCon1 = findobj(fhCon1,'type','axes');
    set(ahCon1,'xlimmode','manual','ylimmode','manual','tag','showConstraintsAxes1')
    yy = bsxfun(@plus,[0 h'-1 nY nY g(end:-1:1)' 0],[0.5;0.5]);
    zz = bsxfun(@plus,[0 c'-1 nY nY d(end:-1:1)' 0],[0.5;0.5]);
    xx = [bsxfun(@plus,0:nX+1,[-0.5;0.5]) bsxfun(@plus,nX+1:-1:0,[0.5;-0.5])];
    
    %%% Set the color scheme for the plot.
    %%% Note that we use transparency to display the overlapping regions so
    %%% in order to get the legend color correct we must calculate the RGB
    %%% values that are displayed.
    
    bandColor = [1 0 0];
    widthColor = [0 0 1 ] ;
    falpha = .5 ;
    whiteColor = [1 1 1];
    legendColor = falpha*bandColor + (1-falpha)*whiteColor;
    intersectColor = falpha*widthColor + (1-falpha)*bandColor;
    
    %%% End of color setup
    
    hp1 = patch(xx(:),yy(:),bandColor,'facealpha',falpha,'EdgeColor','none'); %#ok<NASGU>
    setappdata(hp1,'legend_hgbehavior',0) % This patch does not appear in the legend
    set(hggetbehavior(hp1,'DataCursor'),'Enable',0)
    hp2 = patch(xx(:),zz(:),widthColor,'EdgeColor','none');
    set(hggetbehavior(hp2,'DataCursor'),'Enable',0)
    % Create two dummy patches so that we can set the legend color
    % correctly.
    hp3 = patch([0 0 -1],[0 -1 0],intersectColor,'EdgeColor',intersectColor);
    set(hggetbehavior(hp3,'DataCursor'),'Enable',0)
    hp4 = patch([0 0 -1],[0 -1 0],legendColor,'EdgeColor',legendColor);
    set(hggetbehavior(hp4,'DataCursor'),'Enable',0)
    xlabel('Index of input X')
    ylabel('Index of input Y')
    title('Constraints in the Index Space')
    set(gca,'Children',circshift(get(gca,'Children'),3)) % reorder so legend preserves the right order and it can be switched on/off
    legend({'Band','Width','Combined'},'Location','BestOutside')
    axis([.5 nX+.5 0.5 nY+.5])
    resetplotview(gca,'InitializeCurrentView');
    if axisLink
        setupSamplealignListeners(@indexConsChanged,@indexConsChanged,fhCon1,ahCon1)
    end
    fhCon2 = figure; hold on; axis equal
    ahCon2 = findobj(fhCon2,'type','axes');
    set(ahCon2,'xlimmode','manual','ylimmode','manual','tag','showConstraintsAxes2')
    if issparse(y)
        y = full(y);
    end
    hp1 = patch(interp1(1:nX,x,xx(:),'pchip'),interp1(1:nY,y,yy(:),'pchip'),bandColor,'EdgeColor','none','facealpha',falpha); %#ok<NASGU>
    setappdata(hp1,'legend_hgbehavior',0) % This patch does not appear in the legend
    hp2 = patch(interp1(1:nX,x,xx(:),'pchip'),interp1(1:nY,y,zz(:),'pchip'),widthColor,'EdgeColor','none');
    set(hggetbehavior(hp2,'DataCursor'),'Enable',0)
    % Create two dummy patches so that we can set the legend color
    % correctly.
    hp3 = patch(interp1(1:nX,x,[0 0 -1],'pchip'),interp1(1:nY,y,[0 -1 0],'pchip'),intersectColor,'EdgeColor',intersectColor);
    set(hggetbehavior(hp3,'DataCursor'),'Enable',0)
    hp4 = patch([0 0 -1],[0 -1 0],legendColor,'EdgeColor',legendColor);
    set(hggetbehavior(hp4,'DataCursor'),'Enable',0)
    xlabel('Reference dimension of input X')
    ylabel('Reference dimension of input Y')
    title('Constraints in the Reference Dimension')
    set(gca,'Children',circshift(get(gca,'Children'),3)) % reorder so legend preserves the right order and it can be switched on/off
    legend({'Band','Width','Combined'},'Location','BestOutside')
    axis([interp1(1:nX,x,[.5 nX+.5],'pchip') interp1(1:nY,y,[0.5 nY+.5],'pchip')])
    resetplotview(gca,'InitializeCurrentView');
    if axisLink
        setupSamplealignListeners(@referenceConsChanged,@referenceConsChanged,fhCon2,ahCon2)
    end
    % Coalesce c and d into h and g using an 'and' logic
    h = max(h,c);
    g = min(g,d);
    xf = g>=h; % values in h and g that represent rows with valid matches
    nM = sum(g(xf)-h(xf)+1); % number of matches
    figure(fhCon1)
    text(min(xlim),max(ylim),sprintf('  Number of nodes: %d',nM),'Vertical','Top')
    figure(fhCon2)
    text(min(xlim),max(ylim),sprintf('  Number of nodes: %d',nM),'Vertical','Top')
    if ~showAlignment && ~showNetwork && nargout==0
        % we allow the user to exit the function early without finishing
        % the algorithm, because if constraints are not appropriate, it's
        % very easy to run out of memory, by this the user can first assure
        % that the problem is trackable before running out of memory.
        if axisLink
            setupSampleAlignAppData({fhCon1,fhCon2,fhNet,fhAli},x,y)
        end
        return
    end
end

%%% Coalesce c and d into h and g, i.e. intersect constrained spaces %%%
h = max(h,c);
g = min(g,d);
clear be bs ct c d t % some memory clean up before going on

%%% Find nodes that represent matched observations %%%
xf = g>=h; % values in h and g that represent rows with valid matches
nM = double(sum(g(xf)-h(xf)+1)); % number of matches
mx = zeros(nM,1,'uint32');  % list of matches in X
my = zeros(nM,1,'uint32');  % list of matches in Y
mx(cumsum(g(xf)-h(xf)+1)) = find(xf);
my(cumsum(g(xf)-h(xf)+1)) = g(xf);
for i=nM:-1:1
    if ~mx(i)
        mx(i) = mx(i+1);
        my(i) = my(i+1)-1;
    end
end

%%% Find nodes that need to be added to join unconnected components %%%
vg = g.*~xf+(h-1).*xf;                       % filling vertical gaps
hg = cumsum(accumarray(g(g<nY)+1,1,[nY,1])); % filling horizontal gaps

%%% Create a hash table to easy recover nodes in the graph %%
numNodes = nM+nX+nY+1;
numEdges = 2*numel(my)+numNodes;
nodes = sortrows([0 0;my mx;vg (1:nX)';(1:nY)' hg]);
hT = sparse(double(nodes(:,1).*(nX+1)+nodes(:,2)+1),...
    1,1:numNodes,(nX+1)*(nY+1),1,numNodes);

%%% Score the matches (only if needed) %%%
% Store distances only if we'll use them later otherwise we'll plug them
% directly to the graph later in order to save memory space
if computeQuantile || (showNetwork && numEdges<=500000)
    bSize = floor((12500000/size(X,2))); % bSize in rows
    matchDistances = zeros(nM,1);
    for i = 0:bSize:nM
        j = min(i+bSize,nM);
        try
            % Note that this function has been modified to explicitly
            % exclude the intensity information (unlike before where it was
            % included in the distance calculation).
            %
            %
            %
            tD = distance(X(mx(i+1:j),1),Y(my(i+1:j),1));
            %
            %
            %
            %
            
        catch theException
            error(message('bioinfo:samplealign:ErrorInDistanceFunction', func2str( distance ), theException.message));
        end
        if ~isnumeric(tD) || ~(isscalar(tD) || (isvector(tD)&&(size(tD,1)==(j-i))))
            error(message('bioinfo:samplealign:DistanceFunctionBadReturn', func2str( distance )));
        end
        matchDistances(i+1:j) = tD;
    end
    % making sure there are not zero valued or negative edges
    matchDistances = max(matchDistances,eps);
end

%%% Adjust gap penalties by QMS when needed: %%%
if computeQuantile
    if numNodes<500000  % use stats quantile...
        QMS = quantile(matchDistances,quantileValue);
    else % use a quick quantile approx which uses accumarray...
        QMS = myQuantile(matchDistances,quantileValue,10000);
    end
    gapX = gapX.*double(QMS);
    gapY = gapY.*double(QMS);
end

%%% making sure there are not zero valued or negative edges %%%
gapX = max(eps,gapX);
gapY = max(eps,gapY);

if showNetwork
    fhNet = figure; hold on; axis equal
    ahNet = findobj(fhNet,'type','axes');
    set(ahNet,'xlimmode','manual','ylimmode','manual','tag','showNetworkAxes')
    if numEdges>1000000
        warning(message('bioinfo:samplealign:TooManyEdgesForGraph'))
        if nargout==0
            warning(message('bioinfo:samplealign:TooManyEdgesForGraphExtra'))
        end
    elseif numEdges>500000
        warning(message('bioinfo:samplealign:TooManyEdgesForColoredGraph'))
        if nargout==0
            warning(message('bioinfo:samplealign:TooManyEdgesForColoredGraphExtra'))
        end
        ind = reshape(repmat(1:nM,3,1),nM*3,1);
        delta = reshape([ones(1,nM);zeros(1,nM);nan(1,nM)],nM*3,1);
        
        % draw edges for matches
        plot(double(mx(ind))-delta,double(my(ind))-delta,'b-','LineWidth',3)
        % draw edges for vertical gaps that lead to match nodes
        plot(mx(ind),double(my(ind))-delta,'g-','LineWidth',3)
        % draw edges for horizontal gaps that lead to match nodes
        plot(double(mx(ind))-delta,my(ind),'c-','LineWidth',3)
        % draw edges for all other vertical gaps
        ind = reshape(repmat(1:nY,3,1),nY*3,1);
        delta = reshape([ones(1,nY);zeros(1,nY);nan(1,nY)],nY*3,1);
        plot(hg(ind),ind-delta,'g-','LineWidth',3)
        % draw edges for all other horizontal gaps
        ind = reshape(repmat(1:nX,3,1),nX*3,1);
        delta = reshape([ones(1,nX);zeros(1,nX);nan(1,nX)],nX*3,1);
        plot(ind-delta,vg(ind),'c-','LineWidth',3)
        
    else
        ind = reshape(repmat(1:nM,3,1),nM*3,1);
        delta = reshape([ones(1,nM);zeros(1,nM);nan(1,nM)],nM*3,1);
        
        % draw edges for matches
        patch(double(mx(ind))-delta,double(my(ind))-delta,matchDistances(ind),...
            'LineWidth',3,'EdgeColor','flat','FaceColor','none','VertexNormals',[])
        
        % draw edges for vertical gaps that lead to match nodes
        if isscalar(gapY)
            gapY = gapY(ones(nY,1));
        end
        patch(mx(ind),double(my(ind))-delta,gapY(my(ind)),...
            'LineWidth',3,'EdgeColor','flat','FaceColor','none','VertexNormals',[])
        % draw edges for horizontal gaps that lead to match nodes
        if isscalar(gapX)
            gapX = gapX(ones(nX,1));
        end
        patch(double(mx(ind))-delta,my(ind),gapX(mx(ind)),...
            'LineWidth',3,'EdgeColor','flat','FaceColor','none','VertexNormals',[])
        % draw edges for all other vertical gaps
        ind = reshape(repmat(1:nY,3,1),nY*3,1);
        delta = reshape([ones(1,nY);zeros(1,nY);nan(1,nY)],nY*3,1);
        patch(hg(ind),ind-delta,gapY(ind),...
            'LineWidth',3,'EdgeColor','flat','FaceColor','none','VertexNormals',[])
        % draw edges for all other horizontal gaps
        ind = reshape(repmat(1:nX,3,1),nX*3,1);
        delta = reshape([ones(1,nX);zeros(1,nX);nan(1,nX)],nX*3,1);
        patch(ind-delta,vg(ind),gapX(ind),...
            'LineWidth',3,'EdgeColor','flat','FaceColor','none','VertexNormals',[])
        ylabel(colorbar,'Gap and Match Scores')
        % We intercept the callbacks because the colorbar is specially formatted
        % for this figure
        set(findall(fhNet,'type','uimenu','tag','figMenuInsertColorbar'),'Callback',@myNetColorbarCallback)
        set(findall(fhNet,'Tag','Annotation.InsertColorbar'),'ClickedCallback',@myNetColorbarCallback)
    end
    % draw nodes
    plot([0;(1:nX)';hg],[0;vg;(1:nY)'],'ko','MarkerFaceColor','w')
    plot(mx,my,'ks','MarkerFaceColor','w')
    axis([-.5 nX+.5 -0.5 nY+.5])
    resetplotview(gca,'InitializeCurrentView');
    if axisLink
        setupSamplealignListeners(@netChanged,@netChanged,fhNet,ahNet)
    end
    xlabel('Common m/z vector index')
    ylabel('Target pixel index')
    title('Dynamic Programming Network')
    if ~showAlignment && nargout==0
        % we allow the user to exit the function early without finishing
        % the algorithm, because if constraints are not appropriate, it's
        % very easy to run out of memory, by this the user can first assure
        % that the problem is trackable before running out of memory.
        if axisLink
            setupSampleAlignAppData({fhCon1,fhCon2,fhNet,fhAli},x,y)
        end
        return
    end
end

if showAlignment
    fhAli = figure('Units','normalized',...
        'Position',[0.54 0.54 0.36 0.36]); hold on
    ahAli = findobj(fhAli,'type','axes');
    set(ahAli,'xlimmode','manual','ylimmode','manual','tag','showAlignmentAxes')
    if numNodes>100000
        warning(message('bioinfo:samplealign:TooManyNodesForGraph'))
        if nargout==0
            warning(message('bioinfo:samplealign:TooManyNodesForGraphExtra'))
        end
    else
        hlPotMat = plot([x(mx) y(my)]',[xa(mx) ya(my)]',...
            'Color',[.8 .8 .8],...
            'LineWidth',4);

        for k = 2:numel(hlPotMat)
           setappdata(hlPotMat(k),'legend_hgbehavior',0) 
        end
    end
    
    hlPoints(2,1) = plot(x,xa,'bo',...
        'MarkerSize',10,...
        'Linewidth',1,...
        'MarkerFaceColor','blue',...
        'MarkerEdgeColor','blue');
    
    hlPoints(1,1) = plot(y,ya,'ro',...
        'MarkerSize',10,...
        'Linewidth',1,...
        'MarkerFaceColor','red',...
        'MarkerEdgeColor','red');
    
    axis([min(min(x),min(y)) max(max(x),max(y)) min(min(xa),min(ya)) max(max(xa),max(ya))])
    resetplotview(gca,'InitializeCurrentView');
    
    if nX>500 || nY>500
        warning(message('bioinfo:samplealign:TooManyObservationsForGraph'))
    else
        text(x,xa,num2str((1:nX)'),'color','b','fontsize',8,'clipping','on','verticalalignment','top')
        text(y,ya,num2str((1:nY)'),'color',[0 .5 0],'fontsize',8,'clipping','on','verticalalignment','bottom')
    end
    xlabel('m/z','FontSize',18,'FontWeight','bold');
    ylabel('Intensity','FontSize',18,'FontWeight','bold');
    set(gca,'FontSize',14);
    %ylabel(sprintf('Dimension %d',showAlignment))
    if axisLink
        setupSamplealignListeners(@alignChanged,[],fhAli,ahAli)
    end
    %title('Sample Matching')
    str2 = sprintf('Samples of input X (%d)',nX);
    str3 = sprintf('Samples of input Y (%d)',nY);
    str1 = sprintf('Potential Matches (%d)',nM);
    if numNodes>100000 || nM==0
        %legend({str1,str2})
    else
        %legend({str1,str2,str3})
    end
    if nargout==0
        % we allow the user to exit the function early without finishing
        % the algorithm, because if constraints are not appropriate, it's
        % very easy to run out of memory, by this the user can first assure
        % that the problem is trackable before running out of memory.
        if axisLink
            setupSampleAlignAppData({fhCon1,fhCon2,fhNet,fhAli},x,y)
        end
        return
    end
end

%%% Create the graph with all the gap penalties %%%
if isscalar(gapX) && isscalar(gapY) && gapX==gapY
    graph = sparse(hT([my-1;(0:nY-1)';my;vg].*(nX+1)+[mx;hg;mx-1;(0:nX-1)']+1),...
        hT([my;  (1:nY)';  my;vg].*(nX+1)+[mx;hg;mx;  (1:nX)']  +1),...
        gapX,numNodes,numNodes,numEdges);
else
    if isscalar(gapX)
        gapX = gapX(ones(nX,1));
    end
    if isscalar(gapY)
        gapY = gapY(ones(nY,1));
    end
    graph = sparse(hT([my-1;(0:nY-1)';my;vg].*(nX+1)+[mx;hg;mx-1;(0:nX-1)']+1),...
        hT([my;  (1:nY)';  my;vg].*(nX+1)+[mx;hg;mx;  (1:nX)']  +1),...
        [gapY([my;(1:nY)']);gapX([mx;(1:nX)'])],...
        numNodes,numNodes,numEdges);
end

%%% Insert the match scores into the previous graph %%%
if computeQuantile || (showNetwork && numEdges<=500000) % match distances are already computed?
    graph = graph + sparse(hT((my-1).*(nX+1)+(mx-1)+1),hT(my.*(nX+1)+mx+1),...
        double(matchDistances),numNodes,numNodes,nM);
else
    bSize = floor((12500000/size(X,2))); % bSize in rows
    for i = 0:bSize:nM
        j = min(i+bSize,nM);
        try
            % Need to change the distance calculation here too, to just
            % include the m/z information rather than the intensity as
            % well.
            %
            %
            %
            tD = distance(X(mx(i+1:j),1),Y(my(i+1:j),1));
            %
            %
            %
            %
            
        catch theException
            error(message('bioinfo:samplealign:ErrorInDistanceFunction', func2str( distance ), theException.message));
        end
        if ~isnumeric(tD) || ~(isscalar(tD) || (isvector(tD)&&(size(tD,1)==(j-i))))
            error(message('bioinfo:samplealign:DistanceFunctionBadReturn', func2str( distance )));
        end
        graph = graph + sparse(hT((my(i+1:j)-1).*(nX+1)+(mx(i+1:j)-1)+1),...
            hT(my(i+1:j).*(nX+1)+mx(i+1:j)+1),...
            double(max(eps,tD)),numNodes,numNodes);
    end
end

%%% Solve graph shortest path problem %%%%
[d,path] = graphshortestpath(graph,1,numNodes);
clear graph hashTable % some memory clean up before continuing

%%% Draw winning path on the Dynamic Programming Network %%%
if showNetwork
    figure(fhNet)
    plot(nodes(path,2),nodes(path,1),'r-','MarkerSize',80,'LineWidth',5)
    title('Dynamic Programming Network and Shortest Path')
end

%%% Setting up and checking the outputs %%%
j = nodes(path,1);
i = nodes(path,2);
k = find((diff(i)==1) & (diff(j)==1));
if isempty(k)
    if nM
        warning(message('bioinfo:samplealign:NoMatchesFound'))
    else
        warning(message('bioinfo:samplealign:NoPossibleMatchesFound'))
    end
end
I = double(i(k+1));
J = double(j(k+1));

%%% Draw the aligned signals %%%
if showAlignment
    figure(fhAli)
    hlMatches = plot([x(I) y(J)]',[xa(I) ya(J)]','color','r',...
        'LineWidth',4);
    for kk = 2:numel(hlMatches)
        setappdata(hlMatches(kk),'legend_hgbehavior',0) 
    end
    str4 = sprintf('Selected Matches (%d)',numel(k));
    if numNodes>100000 || nM==0
        if isempty(k)
            legend(hlPoints,{str1,str2})
        else
            legend([hlPoints;hlMatches(1)],{str1,str2,str4})
        end
    elseif isempty(k)
        legend({str1,str2,str3})
    else
        legend({str1,str2,str3,str4})
    end
    box on;
    legend off;
end

if axisLink
    setupSampleAlignAppData({fhCon1,fhCon2,fhNet,fhAli},x,y)
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function th = myQuantile(P,quan_int,res_int)
% MYQUANTILE computes a quick coarse quantile using accumarray
imi = min(P);
ima = max(P);
in2idx = @(x,r) round((x - imi) / (ima-imi) * (r-1) + .5);
idx2in = @(x,r) (x-.5) / (r-1) * (ima-imi) + imi;
inva = accumarray(in2idx(P,res_int),1,[res_int 1]);
th = idx2in(interp1q(cumsum(inva)/sum(inva),(1:res_int)',quan_int),res_int);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
function myNetColorbarCallback(~,~)
     insertmenufcn(gcbf,'Colorbar')
     hc = findall(gcbf,'type','axes','tag','Colorbar');
     if ~isempty(hc)
         ylabel(hc,'Gap and Match Scores')
     end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function setupSampleAlignAppData(fhs,x,y)
% helper function to set up appdata used in figure listeners
for i = 1:numel(fhs)
    fh = fhs{i};
    if ishghandle(fh)
        setappdata(fh,'samplealignFigureHandles',fhs)
        setappdata(fh,'samplealignReferenceX',x)
        setappdata(fh,'samplealignReferenceY',y)
    end
end

% arrayfun(@(fh) setappdata(fh,'samplealignFigureHandles',fhs),nonzeros(fhs))
% arrayfun(@(fh) setappdata(fh,'samplealignReferenceX',x),nonzeros(fhs))
% arrayfun(@(fh) setappdata(fh,'samplealignReferenceY',y),nonzeros(fhs))

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function setupSamplealignListeners(fhX,fhY,hFig,hAxes)
% helper function to set up listeners and X and Y axes, pass empty to do
% not set a listener

% listens when the Ylim of axes has changed
if nargin>1 && ~isempty(fhY)
    YLimListener = addlistener(hAxes,'YLim',...
        'PostSet',@(hSrc,event)fhY(hSrc,event,hFig,hAxes));
else
    YLimListener = [];
end
% listens when the Xlim of axes has changed
if ~isempty(fhX)
    XLimListener = addlistener(hAxes,'XLim',...
        'PostSet',@(hSrc,event)fhX(hSrc,event,hFig,hAxes));
else
    XLimListener = [];
end
% store the listeners in current figure appdata
setappdata(hFig,'samplealignListeners',[YLimListener, XLimListener]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function switchSamplealignListeners(fh,str)
for i = 1:numel(fh)
    if ishghandle(fh(i))
        % set(getappdata(fh(i),'samplealignListeners'),'Enabled',str)
        bioinfoprivate.bioToggleListenerState(getappdata(fh(i),'samplealignListeners'),str);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function indexConsChanged(hSrc,event,hFig,ha) %#ok
[fh,x,y] = listenerBoilerPlate(hFig);
ta = findobj(fh,'Type','axes','Tag','showConstraintsAxes2');
if numel(ta)==1
    xlim(ta,interp1(1:numel(x),x,get(ha,'Xlim'),'pchip'))
    ylim(ta,interp1(1:numel(y),y,get(ha,'Ylim'),'pchip'))
end
ta = findobj(fh,'Type','axes','Tag','showNetworkAxes');
if numel(ta)==1
    xlim(ta,get(ha,'Xlim')-[1 0])
    ylim(ta,get(ha,'Ylim')-[1 0])
end
ta = findobj(fh,'Type','axes','Tag','showAlignmentAxes');
if numel(ta)==1
    xl = interp1(1:numel(x),x,get(ha,'Xlim'),'pchip');
    yl = interp1(1:numel(y),y,get(ha,'Ylim'),'pchip');
    xlim(ta,[min(xl(1),yl(1)) max(xl(2),yl(2))])
end
switchSamplealignListeners(fh,'on')


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function referenceConsChanged(hSrc,event,hFig,ha) %#ok
[fh,x,y] = listenerBoilerPlate(hFig);
ta = findobj(fh,'Type','axes','Tag','showConstraintsAxes1');
if numel(ta)==1
    xlim(ta,interp1(x,1:numel(x),get(ha,'Xlim'),'pchip'))
    ylim(ta,interp1(y,1:numel(y),get(ha,'Ylim'),'pchip'))
end
ta = findobj(fh,'Type','axes','Tag','showNetworkAxes');
if numel(ta)==1
    xlim(ta,interp1(x,1:numel(x),get(ha,'Xlim'),'pchip')-[1 0])
    ylim(ta,interp1(y,1:numel(y),get(ha,'Ylim'),'pchip')-[1 0])
end
ta = findobj(fh,'Type','axes','Tag','showAlignmentAxes');
if numel(ta)==1
    xl = xlim;
    yl = ylim;
    xlim(ta,[min(xl(1),yl(1)) max(xl(2),yl(2))])
end
switchSamplealignListeners(fh,'on')


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function netChanged(hSrc,event,hFig,ha) %#ok
[fh,x,y] = listenerBoilerPlate(hFig);
ta = findobj(fh,'Type','axes','Tag','showConstraintsAxes1');
if numel(ta)==1
    xlim(ta,get(ha,'Xlim')+[1 0])
    ylim(ta,get(ha,'Ylim')+[1 0])
end
ta = findobj(fh,'Type','axes','Tag','showConstraintsAxes2');
if numel(ta)==1
    xlim(ta,interp1(1:numel(x),x,get(ha,'Xlim')+[1 0],'pchip'))
    ylim(ta,interp1(1:numel(y),y,get(ha,'Ylim')+[1 0],'pchip'))
end
ta = findobj(fh,'Type','axes','Tag','showAlignmentAxes');
if numel(ta)==1
    xl = interp1(1:numel(x),x,get(ha,'Xlim')+[1 0],'pchip');
    yl = interp1(1:numel(y),y,get(ha,'Ylim')+[1 0],'pchip');
    xlim(ta,[min(xl(1),yl(1)) max(xl(2),yl(2))])
end
switchSamplealignListeners(fh,'on')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function alignChanged(hSrc,event,hFig,ha) %#ok
[fh,x,y] = listenerBoilerPlate(hFig);
ta = findobj(fh,'Type','axes','Tag','showConstraintsAxes1');
if numel(ta)==1
    xlim(ta,interp1(x,1:numel(x),get(ha,'Xlim'),'pchip'))
    ylim(ta,interp1(y,1:numel(y),get(ha,'Xlim'),'pchip'))
end
ta = findobj(fh,'Type','axes','Tag','showConstraintsAxes2');
if numel(ta)==1
    xlim(ta,interp1(1:numel(x),x,interp1(x,1:numel(x),get(ha,'Xlim'),'pchip'),'pchip'))
    ylim(ta,interp1(1:numel(y),y,interp1(y,1:numel(y),get(ha,'Xlim'),'pchip'),'pchip'))
end
ta = findobj(fh,'Type','axes','Tag','showNetworkAxes');
if numel(ta)==1
    xlim(ta,interp1(x,1:numel(x),get(ha,'Xlim')-[1 0],'pchip'))
    ylim(ta,interp1(y,1:numel(y),get(ha,'Xlim')-[1 0],'pchip'))
end
switchSamplealignListeners(fh,'on')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [fh,x,y] = listenerBoilerPlate(hFig)
fh = getappdata(hFig,'samplealignFigureHandles');
lv = true(numel(fh),1);
for i = 1:numel(fh)
    if ~ishghandle(fh{i})
        lv(i) = false;
    end
end
fh = [fh{lv}];
switchSamplealignListeners(fh,'off')
x = getappdata(hFig,'samplealignReferenceX');
y = getappdata(hFig,'samplealignReferenceY');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [band,bandIsDefault,widthX,widthY,widthIsDefault,gapX,gapY, ...
    distance,weights, showConstraints, showAlignment,showNetwork, ...
    quantileValue,computeQuantile,axisLink] = parse_inputs(nD,varargin)

% Parse the varargin parameter/value inputs

% Check that we have the right number of inputs
if rem(nargin,2)== 0
    error(message('bioinfo:samplealign:IncorrectNumberOfArguments', mfilename));
end

% The allowed inputs
okargs = {'band','width','gap','distance','weights',...
    'showconstraints','constraints',...
    'showalignment','alignment',...
    'shownetwork','network','quantile','linkaxes'};

%%% Set defaults for input parameters %%%
band = inf;
bandIsDefault = true;
widthIsDefault = true;
quantileValue = 0.75;
computeQuantile = true;
    
% This is the 'original' distance function, but is somewhat irrelevant now
% considering that the distances are only calculated using the first
% column, which for MS is the m/z vector. Thus the squaring weights it
% somewhat. This may of course work, but the function has been tested with
% simultated datasets using the simple absolute distance which is greyed
% out below. Obvs this is passed as an input function so the definition
% here is just as the default.
distance = @(R,S) sqrt(sum((R-S).^2,2));
%distance = @(R,S) abs(sum((R-S),2));
            
gapX = 1;
gapY = 1;
weights = true(nD,1);

showAlignment = false;
showConstraints = false;
showNetwork = false;

axisLink = true;

% Loop over the values

for j=1:2:nargin-1
    % Lookup the pair
    [k, pval] = pvpair(varargin{j}, varargin{j+1}, okargs, mfilename);
    switch(k)
        
        case 1 % BAND
            if isa(pval,'function_handle')
                band = pval;
                bandIsDefault = false;
            elseif isscalar(pval) && pval>0
                band = pval;
                bandIsDefault = false;
            else
                % THis has been seriously modified!
                band = pval;
                bandIsDefault = false;
                %error(message('bioinfo:samplealign:InvalidBand'))
            end
        case 2 % WIDTH
            if isvector(pval) && numel(pval)==2 && all(pval>0)
                widthX = pval(1);
                widthY = pval(2);
                widthIsDefault = false;
            elseif isscalar(pval) && pval>0
                widthX = pval;
                widthY = pval;
                widthIsDefault = false;
            else
                error(message('bioinfo:samplealign:InvalidWidth'))
            end
        case 3 % GAP
            if isscalar(pval) && (isnumeric(pval)||isa(pval,'function_handle'))
                % undocumented handy option
                gapX = pval;
                gapY = pval;
            elseif numel(pval)==2 && isnumeric(pval)
                % undocumented handy option
                gapX = pval(1);
                gapY = pval(2);
            elseif iscell(pval) && any(numel(pval)==[1 2])
                % documented correct syntax
                if numel(pval)==1;
                    pval = pval([1 1]);
                end
                if isa(pval{1},'function_handle')
                    gapX = pval{1};
                elseif isnumeric(pval{1}) && isscalar(pval{1})
                    gapX = pval{1};
                else
                    error(message('bioinfo:samplealign:InvalidGapX'))
                end
                if isa(pval{2},'function_handle')
                    gapY = pval{2};
                elseif isnumeric(pval{2}) && isscalar(pval{2})
                    gapY = pval{2};
                else
                    error(message('bioinfo:samplealign:InvalidGapY'))
                end
            else
                error(message('bioinfo:samplealign:InvalidSizeGap'))
            end
            
        case 4 % DISTANCE
            if isa(pval,'function_handle')
                distance = pval;
            else
                error(message('bioinfo:samplealign:InvalidDistance'))
            end
        case 5 % WEIGHTS
            if isvector(pval) && numel(pval)==nD;
                weights = pval(:);
            else
                error(message('bioinfo:samplealign:InvalidWeights'))
            end
        case {6,7} % SHOWCONSTRAINTS
            showConstraints  = opttf(pval,okargs{k},mfilename);
        case {8,9} % SHOWALIGNMENT
            if islogical(pval)
                if all(pval)
                    pval = 2;
                else
                    pval = 0;
                end
            end
            if ischar(pval)
                if any(strcmpi(pval,{'true','yes','on','t'}))
                    pval = 2;
                elseif any(strcmpi(pval,{'false','no','off','f'}))
                    pval = 0;
                end
            end
            if isscalar(pval) && pval==0
                showAlignment = 0;
            elseif isscalar(pval) && ~rem(pval,1) && pval>1 && pval<=nD
                showAlignment = pval;
            else
                if pval>nD
                    error(message('bioinfo:samplealign:showAlignmentTooLarge', pval, nD))
                else
                    error(message('bioinfo:samplealign:showAlignmentInvalid'))
                end
            end
        case {10,11} % SHOWNETWORK
            showNetwork  = opttf(pval,okargs{k},mfilename);
        case 12 % QUANTILE
            if isempty(pval)
                computeQuantile = false;
            elseif isscalar(pval) && pval>=0 && pval<=1
                quantileValue = pval;
            else
                error(message('bioinfo:samplealign:InvalidQuantile'))
            end
        case 13 %LINKAXES (undocummented)
            axisLink  = opttf(pval,okargs{k},mfilename);
    end
end
%%% Set defaults that are dependent of input arguments %%%
if widthIsDefault
    if bandIsDefault
        widthX = 10;
        widthY = 10;
    else
        widthX = Inf;
        widthY = Inf;
    end
end

