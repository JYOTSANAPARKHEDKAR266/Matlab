function photoPuzzleGUI()
% PHOTO PUZZLE GUI WITH INTELLIGENT SUGGESTIONS
% - Load an image
% - Cut into N x N tiles
% - Drag & drop pieces with the mouse
% - Get auto-suggestions using:
%     * Edge matching
%     * Color histogram similarity
%     * SURF keypoint matching
% - Show progress: how many moves/tiles away from the solution
%
% REQUIREMENTS:
% - MATLAB
% - Computer Vision Toolbox (for SURF + matchFeatures)

    % Main state struct
    S = struct();
    S.img              = [];
    S.tiles            = {};    % cell array of tile images
    S.rows             = 0;
    S.cols             = 0;
    S.N                = 0;
    S.currentOrder     = [];    % rows x cols matrix of tile indices
    S.tileHandles      = [];    % rows x cols handles to images
    S.features         = [];    % per-tile features (edge, hist, SURF)
    S.selectedTile     = [];    % currently selected tile index
    S.drag             = [];    % drag state
    S.highlightHandles = [];    % suggestions highlight graphics
    S.txtProgress      = [];    % progress text handle
    
    % Create figure (slightly tinted background)
    S.fig = figure('Name','Intelligent Photo Puzzle',...
                   'NumberTitle','off',...
                   'MenuBar','none',...
                   'ToolBar','none',...
                   'Color',[0.92 0.94 0.97],...
                   'Units','normalized',...
                   'Position',[0.1 0.1 0.8 0.8]);

    % Axes for puzzle
    S.ax = axes('Parent',S.fig,...
                'Units','normalized',...
                'Position',[0.05 0.1 0.6 0.85],...
                'XTick',[], 'YTick',[],...
                'XColor','none','YColor','none',...
                'Box','on',...
                'FontSize',12,...
                'LineWidth',1.2);
    axis(S.ax,'ij'); % row 1 at top
    title(S.ax,'Load an image to begin','FontSize',14,'FontWeight','bold');

    % ========= RIGHT SIDE UI CONTROLS =========
    commonBG = [0.92 0.94 0.97];
    headerFontSize = 14;
    labelFontSize  = 11;
    textFontSize   = 11;
    buttonFontSize = 11;

    % Header text
    uicontrol('Style','text',...
              'Parent',S.fig,...
              'Units','normalized',...
              'Position',[0.68 0.9 0.29 0.05],...
              'String','Photo Puzzle Controls',...
              'FontSize',headerFontSize,...
              'FontWeight','bold',...
              'ForegroundColor',[0 0 0.4],...
              'BackgroundColor',commonBG,...
              'HorizontalAlignment','center');

    % Grid size input label
    uicontrol('Style','text',...
              'Parent',S.fig,...
              'Units','normalized',...
              'Position',[0.68 0.84 0.15 0.04],...
              'String','Grid size (N x N):',...
              'HorizontalAlignment','left',...
              'FontSize',labelFontSize,...
              'FontWeight','bold',...
              'ForegroundColor',[0 0 0],...
              'BackgroundColor',commonBG);

    % Grid size edit box
    S.editGrid = uicontrol('Style','edit',...
              'Parent',S.fig,...
              'Units','normalized',...
              'Position',[0.83 0.84 0.12 0.04],...
              'String','4',... % default 4x4
              'FontSize',labelFontSize,...
              'BackgroundColor',[1 1 1]);

    % Load image button
    uicontrol('Style','pushbutton',...
              'Parent',S.fig,...
              'Units','normalized',...
              'Position',[0.68 0.78 0.27 0.05],...
              'String','Load Image & Create Puzzle',...
              'FontSize',buttonFontSize,...
              'FontWeight','bold',...
              'BackgroundColor',[0.8 0.88 1],...
              'ForegroundColor',[0 0 0.4],...
              'Callback',@(src,evt)onLoadImage(src,evt));

    % Shuffle button
    S.btnShuffle = uicontrol('Style','pushbutton',...
              'Parent',S.fig,...
              'Units','normalized',...
              'Position',[0.68 0.71 0.27 0.05],...
              'String','Shuffle Pieces',...
              'FontSize',buttonFontSize,...
              'FontWeight','bold',...
              'BackgroundColor',[0.8 0.95 0.8],...
              'ForegroundColor',[0 0.3 0],...
              'Enable','off',...
              'Callback',@(src,evt)onShuffle(src,evt));

    % Suggest button
    S.btnSuggest = uicontrol('Style','pushbutton',...
              'Parent',S.fig,...
              'Units','normalized',...
              'Position',[0.68 0.64 0.27 0.05],...
              'String','Suggest Neighbors',...
              'FontSize',buttonFontSize,...
              'FontWeight','bold',...
              'BackgroundColor',[1 0.88 0.7],...
              'ForegroundColor',[0.5 0.25 0],...
              'Enable','off',...
              'Callback',@(src,evt)onSuggest(src,evt));

    % Progress text (NEW) - bigger, bold, green-ish
    S.txtProgress = uicontrol('Style','text',...
              'Parent',S.fig,...
              'Units','normalized',...
              'Position',[0.68 0.58 0.27 0.05],...
              'String','Progress: Load an image to begin.',...
              'HorizontalAlignment','left',...
              'FontSize',labelFontSize,...
              'FontWeight','bold',...
              'ForegroundColor',[0 0.45 0],...
              'BackgroundColor',commonBG);

    % Info text (instructions)
    S.txtInfo = uicontrol('Style','text',...
              'Parent',S.fig,...
              'Units','normalized',...
              'Position',[0.68 0.46 0.27 0.11],...
              'String',['Instructions:' newline ...
                        '• Load an image' newline ...
                        '• Shuffle the pieces' newline ...
                        '• Click & drag tiles' newline ...
                        '• Select a tile then click "Suggest"' ],...
              'HorizontalAlignment','left',...
              'FontSize',textFontSize,...
              'ForegroundColor',[0.1 0.1 0.1],...
              'BackgroundColor',commonBG);

    % Suggestions text (make it larger & clearer)
    S.txtSuggest = uicontrol('Style','text',...
              'Parent',S.fig,...
              'Units','normalized',...
              'Position',[0.68 0.1 0.27 0.35],...
              'String','Suggestions will appear here.',...
              'HorizontalAlignment','left',...
              'FontSize',textFontSize,...
              'ForegroundColor',[0.1 0.1 0.3],...
              'BackgroundColor',[0.95 0.97 1]);

    % Store initial state
    guidata(S.fig,S);

    %% --- Callback: Load Image & Create Puzzle ---
    function onLoadImage(~,~)
        S = guidata(gcf);
        
        [file,path] = uigetfile({'*.jpg;*.jpeg;*.png;*.bmp','Image Files'},...
                                'Select an image');
        if isequal(file,0)
            return;
        end
        img = imread(fullfile(path,file));
        if size(img,3)==1
            img = repmat(img,[1 1 3]); % ensure RGB
        end

        % Resize to manageable size if too large
        maxDim = 600;
        [h0,w0,~] = size(img);
        scale = min(maxDim/h0, maxDim/w0);
        if scale < 1
            img = imresize(img,scale);
        end
        
        % Read grid size N
        N_str = get(S.editGrid,'String');
        N_val = str2double(N_str);
        if isnan(N_val) || N_val < 3
            N_val = 4;
            set(S.editGrid,'String','4');
        end
        
        S.rows = N_val;
        S.cols = N_val;
        S.N    = S.rows * S.cols;
        S.img  = img;

        % Cut into tiles
        [S.tiles, tileH, tileW] = cutIntoTiles(img,S.rows,S.cols); %#ok<ASGLU>
        
        % Precompute features
        S.features = computeAllFeatures(S.tiles);
        
        % Prepare axes grid: coordinates [0,cols] x [0,rows]
        cla(S.ax);
        axis(S.ax,[0 S.cols 0 S.rows]);
        axis(S.ax,'ij');
        hold(S.ax,'on');
        S.tileHandles = gobjects(S.rows,S.cols);
        
        % Create shuffled order
        perm = randperm(S.N);
        S.currentOrder = reshape(perm,S.rows,S.cols);
        
        % Place tiles in grid
        for r = 1:S.rows
            for c = 1:S.cols
                idx = S.currentOrder(r,c);
                thisTile = S.tiles{idx};
                xData = [c-1 c];
                yData = [r-1 r];
                hImg = image('CData',thisTile,...
                             'XData',xData,...
                             'YData',yData,...
                             'Parent',S.ax,...
                             'ButtonDownFcn',@(h,e)onTileClick(h,e),...
                             'PickableParts','all',...
                             'HitTest','on');
                setappdata(hImg,'tileIdx', idx);
                S.tileHandles(r,c) = hImg;
            end
        end
        hold(S.ax,'off');
        title(S.ax,'Drag pieces to solve the puzzle','FontSize',14,'FontWeight','bold');
        
        % Enable buttons
        set(S.btnShuffle,'Enable','on');
        set(S.btnSuggest,'Enable','on');
        
        % Clear selection & highlights
        S.selectedTile = [];
        deleteHighlights(S);
        
        % Update progress
        updateProgress(S);
        
        % Set figure-level callbacks for dragging
        set(S.fig,'WindowButtonMotionFcn',@(src,evt)onDrag(src,evt));
        set(S.fig,'WindowButtonUpFcn',@(src,evt)onDrop(src,evt));
        
        guidata(S.fig,S);
    end

    %% --- Cut image into tiles (rows x cols) ---
    function [tiles, tileH, tileW] = cutIntoTiles(img,rows,cols)
        [H,W,~] = size(img);
        tileH = floor(H/rows);
        tileW = floor(W/cols);
        tiles = cell(rows*cols,1);
        k = 1;
        for r = 1:rows
            for c = 1:cols
                r1 = (r-1)*tileH + 1;
                c1 = (c-1)*tileW + 1;
                if r == rows
                    r2 = H;
                else
                    r2 = r*tileH;
                end
                if c == cols
                    c2 = W;
                else
                    c2 = c*tileW;
                end
                tiles{k} = img(r1:r2,c1:c2,:);
                k = k + 1;
            end
        end
    end

    %% --- Precompute features for all tiles ---
    function feats = computeAllFeatures(tiles)
        n = numel(tiles);
        feats(n).edgeVec = [];
        feats(n).histVec = [];
        feats(n).surfDesc = [];
        
        for k = 1:n
            I = tiles{k};
            feats(k).edgeVec = computeEdgeDescriptor(I);
            feats(k).histVec = computeColorHistogram(I);
            feats(k).surfDesc = computeSURFFeaturesTile(I);
        end
    end

    %% --- Edge descriptor: borders of tile in grayscale ---
    function edgeVec = computeEdgeDescriptor(I)
        gray = rgb2gray(I);
        gray = double(gray);
        top    = gray(1,:);
        bottom = gray(end,:);
        left   = gray(:,1)';
        right  = gray(:,end)';
        edgeVec = [top, bottom, left, right]; % row vector
    end

    %% --- Color histogram (simple RGB histograms) ---
    function hVec = computeColorHistogram(I)
        I = im2double(I);
        nbins = 16;
        % R, G, B individually
        R = I(:,:,1);
        G = I(:,:,2);
        B = I(:,:,3);
        edges = linspace(0,1,nbins+1);
        hR = histcounts(R(:),edges);
        hG = histcounts(G(:),edges);
        hB = histcounts(B(:),edges);
        h = [hR hG hB];
        h = h / (norm(h)+eps); % normalize
        hVec = h;
    end

    %% --- SURF features for tile ---
    function desc = computeSURFFeaturesTile(I)
        try
            gray = rgb2gray(I);
            points = detectSURFFeatures(gray);
            if points.Count < 4
                desc = [];
                return;
            end
            [features,~] = extractFeatures(gray,points);
            desc = features;
        catch
            % If CV toolbox not available, just return empty
            desc = [];
        end
    end

    %% --- Callback: Shuffle pieces ---
    function onShuffle(~,~)
        S = guidata(gcf);
        if isempty(S.tiles)
            return;
        end
        
        perm = randperm(S.N);
        S.currentOrder = reshape(perm,S.rows,S.cols);
        
        for r = 1:S.rows
            for c = 1:S.cols
                idx = S.currentOrder(r,c);
                thisTile = S.tiles{idx};
                xData = [c-1 c];
                yData = [r-1 r];
                hImg = S.tileHandles(r,c);
                set(hImg,'CData',thisTile,...
                         'XData',xData,...
                         'YData',yData);
                setappdata(hImg,'tileIdx',idx);
            end
        end
        
        S.selectedTile = [];
        deleteHighlights(S);
        title(S.ax,'Puzzle shuffled! Drag pieces to solve.','FontSize',14,'FontWeight','bold');
        
        % Update progress
        updateProgress(S);
        
        guidata(S.fig,S);
    end

    %% --- Tile click: start drag + select tile ---
    function onTileClick(hImg,~)
        S = guidata(gcf);
        if isempty(S.tiles)
            return;
        end
        
        % Mark selected tile
        idx = getappdata(hImg,'tileIdx');
        S.selectedTile = idx;
        
        % Set drag state
        cp = get(S.ax,'CurrentPoint');
        S.drag.isDragging  = true;
        S.drag.handle      = hImg;
        S.drag.startPoint  = cp(1,1:2);
        S.drag.startXData  = get(hImg,'XData');
        S.drag.startYData  = get(hImg,'YData');
        
        % Update info text
        set(S.txtInfo,'String',sprintf(['Selected tile: %d\n' ...
                                        'Drag with mouse.\n' ...
                                        'Press "Suggest" for neighbors.'], idx));
        
        guidata(S.fig,S);
    end

    %% --- Figure motion: drag handler ---
    function onDrag(~,~)
        S = guidata(gcf);
        if ~isfield(S,'drag') || isempty(S.drag) || ~isfield(S.drag,'isDragging')
            return;
        end
        if ~S.drag.isDragging
            return;
        end
        if ~ishandle(S.drag.handle)
            return;
        end
        
        cp = get(S.ax,'CurrentPoint');
        currPt = cp(1,1:2);
        delta = currPt - S.drag.startPoint;
        
        newX = S.drag.startXData + delta(1);
        newY = S.drag.startYData + delta(2);
        
        set(S.drag.handle,'XData',newX,'YData',newY);
    end

    %% --- Figure mouse up: drop handler ---
    function onDrop(~,~)
        S = guidata(gcf);
        if ~isfield(S,'drag') || isempty(S.drag) || ~isfield(S,'drag') || ~isfield(S.drag,'isDragging')
            return;
        end
        if ~S.drag.isDragging
            return;
        end
        
        hImg = S.drag.handle;
        if ~ishandle(hImg)
            S.drag.isDragging = false;
            guidata(S.fig,S);
            return;
        end
        
        % Snap to nearest grid cell
        XData = get(hImg,'XData');
        YData = get(hImg,'YData');
        centerX = mean(XData);
        centerY = mean(YData);
        
        targetCol = round(centerX);
        targetRow = round(centerY);
        
        % Clamp to grid
        targetCol = max(1, min(S.cols, targetCol));
        targetRow = max(1, min(S.rows, targetRow));
        
        % Find the tile index for dragged piece
        idx = getappdata(hImg,'tileIdx');
        
        % Find old position of this tile in currentOrder
        [oldRow, oldCol] = find(S.currentOrder == idx);
        if isempty(oldRow)
            % Should not happen, but just in case
            S.drag.isDragging = false;
            guidata(S.fig,S);
            return;
        end
        
        % Swap tiles if another tile is in target cell
        idxOther = S.currentOrder(targetRow, targetCol);
        S.currentOrder(targetRow,targetCol) = idx;
        S.currentOrder(oldRow,oldCol)       = idxOther;
        
        % Move dragged tile to target cell
        set(hImg,'XData',[targetCol-1 targetCol],...
                 'YData',[targetRow-1 targetRow]);
        
        % Move the other tile (if different) back to old position
        if idxOther ~= idx
            % swap handles
            hTmp = S.tileHandles(oldRow,oldCol);
            S.tileHandles(oldRow,oldCol)       = S.tileHandles(targetRow,targetCol);
            S.tileHandles(targetRow,targetCol) = hTmp;
            
            % reposition the swapped tile
            hNowOther = S.tileHandles(oldRow,oldCol);
            set(hNowOther,'XData',[oldCol-1 oldCol],...
                          'YData',[oldRow-1 oldRow]);
        end
        
        S.drag.isDragging = false;
        
        % Update progress after each move
        updateProgress(S);
        
        guidata(S.fig,S);
        
        % Check if solved
        checkSolved();
    end

    %% --- Check if puzzle is solved ---
    function checkSolved()
        S = guidata(gcf);
        if isempty(S.currentOrder)
            return;
        end
        if isequal(S.currentOrder, reshape(1:S.N,S.rows,S.cols))
            title(S.ax,'Game Over: Puzzle Solved! 🎉','FontSize',14,'FontWeight','bold');
            set(S.txtInfo,'String','Puzzle solved! You can shuffle and play again.');
            set(S.txtProgress,'String','Game over: puzzle solved! 🎉');
        end
    end

    %% --- Callback: Suggest neighbors for selected tile ---
    function onSuggest(~,~)
        S = guidata(gcf);
        if isempty(S.tiles) || isempty(S.selectedTile)
            set(S.txtSuggest,'String','Select a tile first (click on one).');
            return;
        end
        
        deleteHighlights(S);
        
        k = S.selectedTile;
        feats = S.features;
        n = numel(feats);
        
        % Pre-allocate scores
        edgeDist = inf(1,n);
        histDist = inf(1,n);
        surfScore = zeros(1,n);
        
        % Feature of selected tile
        e0 = feats(k).edgeVec;
        h0 = feats(k).histVec;
        d0 = feats(k).surfDesc;
        
        for j = 1:n
            if j == k, continue; end
            
            % Edge distance (L2)
            ej = feats(j).edgeVec;
            if ~isempty(e0) && ~isempty(ej)
                edgeDist(j) = norm(e0 - ej);
            end
            
            % Histogram distance (1 - cosine similarity)
            hj = feats(j).histVec;
            if ~isempty(h0) && ~isempty(hj)
                sim = (h0 * hj') / (norm(h0)*norm(hj) + eps);
                histDist(j) = 1 - sim;
            end
            
            % SURF matching: number of matched features
            dj = feats(j).surfDesc;
            if ~isempty(d0) && ~isempty(dj)
                try
                    matches = matchFeatures(d0,dj,'Unique',true,...
                        'MatchThreshold',100,'MaxRatio',0.9);
                    surfScore(j) = size(matches,1);
                catch
                    surfScore(j) = 0;
                end
            else
                surfScore(j) = 0;
            end
        end
        
        % For edge and hist, smaller is better; for surf, larger is better
        % Ignore Inf entries
        [~,bestEdgeIdx] = min(edgeDist);
        [~,bestHistIdx] = min(histDist);
        [~,bestSurfIdx] = max(surfScore);
        
        % Get top-3 overall by combined normalized score
        eNorm = edgeDist;
        hNorm = histDist;
        sNorm = -surfScore; % negative so smaller is better
        
        % Replace Inf with large number
        if any(isinf(eNorm))
            eNorm(isinf(eNorm)) = max(eNorm(~isinf(eNorm))) + 1;
        end
        if any(isinf(hNorm))
            hNorm(isinf(hNorm)) = max(hNorm(~isinf(hNorm))) + 1;
        end
        
        % Normalize
        eNorm = eNorm / (max(eNorm)+eps);
        hNorm = hNorm / (max(hNorm)+eps);
        sNorm = sNorm / (max(abs(sNorm))+eps);
        
        combined = eNorm + hNorm + sNorm; % simple sum
        combined(k) = Inf; % ignore self
        [~,sortedIdx] = sort(combined,'ascend');
        topK = sortedIdx(1:min(3,numel(sortedIdx)));
        
        % Update suggestion text
        msg = sprintf('Selected tile: %d\n',k);
        msg = [msg sprintf('Best (edge) match: tile %d\n',bestEdgeIdx)];
        msg = [msg sprintf('Best (color hist) match: tile %d\n',bestHistIdx)];
        msg = [msg sprintf('Best (SURF) match: tile %d\n',bestSurfIdx)];
        msg = [msg sprintf('\nTop-3 combined suggestions: %s\n', mat2str(topK))];
        set(S.txtSuggest,'String',msg);
        
        % Highlight suggested tiles
        S = highlightTiles(S, [bestEdgeIdx bestHistIdx bestSurfIdx topK]);
        guidata(S.fig,S);
    end

    %% --- Highlight suggested tiles ---
    function S = highlightTiles(S, tileIdxList)
        tileIdxList = unique(tileIdxList);
        tileIdxList(isnan(tileIdxList)) = [];
        tileIdxList(tileIdxList==0) = [];
        
        for k = tileIdxList
            if k < 1 || k > S.N, continue; end
            % Find tile position (r,c) for index k
            [r,c] = find(S.currentOrder == k);
            if isempty(r), continue; end
            % Draw rectangle around tile
            x0 = c-1; x1 = c;
            y0 = r-1; y1 = r;
            hRect = line(S.ax,...
                         [x0 x1 x1 x0 x0],...
                         [y0 y0 y1 y1 y0],...
                         'LineWidth',2,...
                         'Color',[1 0 0]); % red border
            S.highlightHandles = [S.highlightHandles; hRect];
        end
    end

    %% --- Delete existing highlights ---
    function deleteHighlights(S)
        if isfield(S,'highlightHandles') && ~isempty(S.highlightHandles)
            for h = S.highlightHandles'
                if isvalid(h)
                    delete(h);
                end
            end
        end
        S.highlightHandles = [];
        guidata(S.fig,S);
    end

    %% --- Update progress text based on currentOrder ---
    function updateProgress(S)
        % Compute how many tiles are in the wrong position.
        if isempty(S.currentOrder) || S.N == 0
            set(S.txtProgress,'String','Progress: Load an image to begin.');
            return;
        end
        
        correctOrder = reshape(1:S.N, S.rows, S.cols);
        numCorrect   = sum(S.currentOrder(:) == correctOrder(:));
        numWrong     = S.N - numCorrect;
        
        % Puzzle solved case
        if numWrong == 0
            set(S.txtProgress,'String','Game over: puzzle solved! 🎉');
            return;
        end
        
        % Lower bound on number of swaps:
        % each swap can fix at most 2 misplaced tiles
        minSwaps = ceil(numWrong / 2);
        
        if minSwaps == 1
            msg = sprintf(['Progress: At least 1 swap remaining ' ...
                           'to reach the solution. (%d/%d tiles correct)'], ...
                           numCorrect, S.N);
        else
            msg = sprintf(['Progress: At least %d swaps remaining ' ...
                           'to reach the solution. (%d/%d tiles correct)'], ...
                           minSwaps, numCorrect, S.N);
        end
        
        set(S.txtProgress,'String', msg);
    end
end

