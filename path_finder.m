function liveAstarSolver
    % Set up grid dimensions and initialize grid
    gridSize = [50, 50];
    data.grid = zeros(gridSize);  % 0: free, 1: obstacle, 2: start, 3: goal, 5: penalty
    data.start = [];
    data.goal  = [];
    data.isMouseDown = false;
    data.drawMode = '';  % 'draw' or 'erase'
    data.lastCell = [];
    data.pathLine = [];  % handle for the plotted path line
    
    % Create figure and axes for interactive grid display
    hFig = figure('Name', 'Live A* Solver', 'NumberTitle', 'off');
    hAx = axes('Parent', hFig);
    data.hImg = imagesc(data.grid, 'Parent', hAx);
    % Define colormap: free=white, obstacle=black, start=green, goal=red, path will be drawn, penalty=yellow.
    colormap(hAx, [1 1 1; 0 0 0; 0 1 0; 1 0 0; 0 0 1; 1 1 0]);
    axis(hAx, 'equal', 'tight');
    title(hAx, ['Left click & drag: draw/erase obstacles; ' ...
                'Press "z" then click & drag for penalty zones; ' ...
                'Press "s" then click for start; ' ...
                'Press "g" then click for goal; ' ...
                'Press "r" to run solver; ' ...
                'Press "q" to clear path; ' ...
                'Press "c" to clear grid.']);
    data.mode = 'obstacle';  % default mode
    
    % Set callbacks for mouse events and key press
    set(hFig, 'WindowButtonDownFcn', @mouseButtonDown);
    set(hFig, 'WindowButtonMotionFcn', @mouseDrag);
    set(hFig, 'WindowButtonUpFcn', @mouseButtonUp);
    set(hFig, 'KeyPressFcn', @keyPress);
    
    % Store data in the figure's guidata
    guidata(hFig, data);
    
    %% Callback: Mouse button down
    function mouseButtonDown(~, ~)
        data = guidata(hFig);
        cp = get(hAx, 'CurrentPoint');
        x = round(cp(1,1));
        y = round(cp(1,2));
        % Check if click is within grid bounds
        if x < 1 || y < 1 || x > gridSize(2) || y > gridSize(1)
            return;
        end
        
        if strcmp(data.mode, 'obstacle')
            % Begin drawing/erasing obstacles
            data.isMouseDown = true;
            data.lastCell = [y, x];
            % Toggle cell: if free then draw obstacle, if obstacle then erase (do not change start/goal/penalty)
            if data.grid(y, x) == 0
                data.drawMode = 'draw';
                data.grid(y, x) = 1;
            elseif data.grid(y, x) == 1
                data.drawMode = 'erase';
                data.grid(y, x) = 0;
            end
        elseif strcmp(data.mode, 'penalty')
            % Begin drawing/erasing penalty zones
            data.isMouseDown = true;
            data.lastCell = [y, x];
            % Only toggle free (0) or penalty (5) cells (leave start, goal, obstacles unchanged)
            if data.grid(y, x) == 0
                data.drawMode = 'draw';
                data.grid(y, x) = 5;
            elseif data.grid(y, x) == 5
                data.drawMode = 'erase';
                data.grid(y, x) = 0;
            end
        elseif strcmp(data.mode, 'set_start')
            % Set start point (cell value 2)
            if ~isempty(data.start)
                if data.grid(data.start(1), data.start(2)) == 2
                    data.grid(data.start(1), data.start(2)) = 0;
                end
            end
            data.start = [y, x];
            data.grid(y, x) = 2;
            data.mode = 'obstacle';  % revert to obstacle mode
        elseif strcmp(data.mode, 'set_goal')
            % Set goal point (cell value 3)
            if ~isempty(data.goal)
                if data.grid(data.goal(1), data.goal(2)) == 3
                    data.grid(data.goal(1), data.goal(2)) = 0;
                end
            end
            data.goal = [y, x];
            data.grid(y, x) = 3;
            data.mode = 'obstacle';
        end
        set(data.hImg, 'CData', data.grid);
        guidata(hFig, data);
    end % End of mouseButtonDown

    %% Callback: Mouse drag (motion while button is down)
    function mouseDrag(~, ~)
        data = guidata(hFig);
        if ~data.isMouseDown || ~(strcmp(data.mode, 'obstacle') || strcmp(data.mode, 'penalty'))
            return;
        end
        cp = get(hAx, 'CurrentPoint');
        x = round(cp(1,1));
        y = round(cp(1,2));
        if x < 1 || y < 1 || x > gridSize(2) || y > gridSize(1)
            return;
        end
        % Only update if the cell is different from the last updated
        if ~isequal([y, x], data.lastCell)
            % Avoid altering start (2) or goal (3)
            if data.grid(y, x) ~= 2 && data.grid(y, x) ~= 3
                if strcmp(data.mode, 'obstacle')
                    if strcmp(data.drawMode, 'draw')
                        data.grid(y, x) = 1;
                    elseif strcmp(data.drawMode, 'erase')
                        data.grid(y, x) = 0;
                    end
                elseif strcmp(data.mode, 'penalty')
                    if strcmp(data.drawMode, 'draw')
                        data.grid(y, x) = 5;
                    elseif strcmp(data.drawMode, 'erase')
                        data.grid(y, x) = 0;
                    end
                end
            end
            data.lastCell = [y, x];
            set(data.hImg, 'CData', data.grid);
        end
        guidata(hFig, data);
    end % End of mouseDrag

    %% Callback: Mouse button up
    function mouseButtonUp(~, ~)
        data = guidata(hFig);
        data.isMouseDown = false;
        data.lastCell = [];
        guidata(hFig, data);
    end % End of mouseButtonUp

    %% Callback: Key press handler
    function keyPress(~, event)
        data = guidata(hFig);
        switch event.Key
            case 's'
                data.mode = 'set_start';
                disp('Click on grid to set START point.');
            case 'g'
                data.mode = 'set_goal';
                disp('Click on grid to set GOAL point.');
            case 'z'
                data.mode = 'penalty';
                disp('Penalty mode activated: click & drag to draw/erase penalty zones.');
            case 'r'
                if isempty(data.start) || isempty(data.goal)
                    disp('Please set both start and goal points.');
                else
                    % Remove any existing path line before drawing a new one
                    if ishandle(data.pathLine)
                        delete(data.pathLine);
                    end
                    disp('Running A* solver...');
                    [path, success] = astar(data.grid, data.start, data.goal);
                    if success
                        % Plot the computed path as a blue line.
                        % Use column (x) and row (y) coordinates.
                        data.pathLine = line(path(:,2), path(:,1), 'Color', 'b', 'LineWidth', 2);
                        disp('Path found.');
                    else
                        disp('No path found.');
                    end
                end
            case 'c'
                data.grid = zeros(gridSize);
                data.start = [];
                data.goal  = [];
                % Remove the path line if it exists
                if ishandle(data.pathLine)
                    delete(data.pathLine);
                end
                data.pathLine = [];
                disp('Grid cleared.');
            case 'q'
                % Clear only the path line
                if ishandle(data.pathLine)
                    delete(data.pathLine);
                end
                data.pathLine = [];
                disp('Path cleared.');
        end
        set(data.hImg, 'CData', data.grid);
        guidata(hFig, data);
    end % End of keyPress

    %% A* Algorithm Function
    function [path, success] = astar(grid, start, goal)
        [rows, cols] = size(grid);
        closed = false(rows, cols);
        g = inf(rows, cols);
        f = inf(rows, cols);
        parent = cell(rows, cols);
        
        start_r = start(1);
        start_c = start(2);
        goal_r  = goal(1);
        goal_c  = goal(2);
        
        g(start_r, start_c) = 0;
        f(start_r, start_c) = heuristic(start, goal);
        openList = [start_r, start_c];
        
        success = false;
        while ~isempty(openList)
            % Find the node in openList with the lowest f score
            currentIdx = 1;
            current = openList(1,:);
            for i = 2:size(openList,1)
                if f(openList(i,1), openList(i,2)) < f(current(1), current(2))
                    current = openList(i,:);
                    currentIdx = i;
                end
            end
            
            % Remove current node from openList and mark it closed
            openList(currentIdx,:) = [];
            r = current(1);
            c = current(2);
            closed(r, c) = true;
            
            % Check if goal is reached
            if r == goal_r && c == goal_c
                success = true;
                break;
            end
            
            % Explore 8-connected neighbors
            neighbors = [r-1, c; r+1, c; r, c-1; r, c+1; r-1, c-1; r-1, c+1; r+1, c-1; r+1, c+1];
            for i = 1:size(neighbors, 1)
                nr = neighbors(i, 1);
                nc = neighbors(i, 2);
                if nr < 1 || nr > rows || nc < 1 || nc > cols
                    continue;
                end
                % Skip if cell is an obstacle or already closed
                if grid(nr, nc) == 1 || closed(nr, nc)
                    continue;
                end
                % Determine movement cost (orthogonal: 1, diagonal: sqrt(2))
                if abs(nr - r) + abs(nc - c) == 2
                    stepCost = sqrt(2);
                else
                    stepCost = 1;
                end
                % If neighbor is a penalty zone, multiply the cost by 1.3
                if grid(nr, nc) == 5
                    stepCost = stepCost * 1.3;
                end
                tentative_g = g(r, c) + stepCost;
                if tentative_g < g(nr, nc)
                    parent{nr, nc} = [r, c];
                    g(nr, nc) = tentative_g;
                    f(nr, nc) = tentative_g + heuristic([nr, nc], goal);
                    % Add neighbor to openList if not already there
                    if ~ismember([nr, nc], openList, 'rows')
                        openList = [openList; nr, nc];
                    end
                end
            end
        end
        
        if success
            % Reconstruct the path by backtracking from goal to start
            path = goal;
            current = goal;
            while ~(current(1) == start(1) && current(2) == start(2))
                current = parent{current(1), current(2)};
                path = [current; path];
            end
        else
            path = [];
        end
    end % End of astar

    %% Heuristic function: Euclidean distance
    function h = heuristic(p, goal)
        h = sqrt((p(1) - goal(1))^2 + (p(2) - goal(2))^2);
    end % End of heuristic

end % End of liveAstarSolver
