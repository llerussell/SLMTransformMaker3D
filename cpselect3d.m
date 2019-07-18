function movingPoints = cpselect3d(movingStack, fixedPoints)
% Lloyd Russell 2018


% get stuff ready
fixedPoints = fixedPoints(:,1:3);
allPoints = [fixedPoints nan(size(fixedPoints))];
zPlanes = unique(fixedPoints(:,3));
numZPlanes = numel(zPlanes);
numSlices = size(movingStack,3);
currentPlaneIdx = 1;
currentPlane = zPlanes(currentPlaneIdx);
currentSlice = 1;
currentSliceUM = 0;
stackRange = [];


% make figure
BGCOLOR = [.9 .9 .9];
fig = figure('name','3D SLM calibration', 'numbertitle','off', 'menubar','none', 'toolbar','none', 'Position',[50 50 1000 1000], 'color',BGCOLOR, 'WindowKeyPressFcn',@windowKeyPressFcn);
mainTitle = uicontrol('style','text', 'units','normalized', 'position',[.05 .85 .35 .1], 'horizontalalignment','left', 'fontsize',18, 'backgroundcolor',BGCOLOR);


% TARGETS
% -------
ax = subplot(3,3,[1 4]);
fixedPointsPlot = plot3(fixedPoints(:,1), fixedPoints(:,2), fixedPoints(:,3), 'k.');
hold on
movingPointsPlot = plot3(nan, nan, nan, 'r+');
activeFixedPlot = plot3(nan, nan, nan, 'ko', 'markerfacecolor','k');
activeMovingPlot = plot3(nan, nan, nan, 'markeredgecolor','k');
% zeroPlanePatch = patch([1 512 512 1],[1 1 512 512],[0 0 0 0], 'w-', 'facealpha',0.5);
movingPlanePatch = patch([1 512 512 1],[1 1 512 512],[0 0 0 0], 'k-', 'facealpha',0.1, 'edgecolor','w', 'edgealpha',0);
ax.XColor = [.6 .6 .6];
ax.YColor = [.6 .6 .6];
ax.ZColor = [.6 .6 .6];
xlim([1 512])
ylim([1 512])
axis square
box on
xlabel('X')
ylabel('Y')
zlabel('Z')
title('SLM targets')


% 2P STACK
% --------
imgAx = axes('position',[.4 .4 .5 .5]);
minImg = min(movingStack,[],3);
img = imagesc(movingStack(:,:,currentSlice));
hold on
axis square
xticks([])
yticks([])
colormap(gray)
caxis([min(minImg(:)) max(minImg(:))])
title('2P stack')
ROImarker = scatter(256,256, 200,'bo', 'HitTest','on', 'ButtonDownFcn',@MouseClickPoint, 'tag','roi');
% ROItrace = ROItrace-haloTrace;
for i = 1:numZPlanes
    movingPointPlots(i) = plot(nan,nan, 'r+', 'HitTest','on', 'ButtonDownFcn',@MouseClickPoint);
end


% TABLE
% -----
pointsTable = uitable('data', allPoints, 'ColumnName',{'X1','Y1','Z1','X2','Y2','Z2'}, 'ColumnWidth',{30}, 'units','normalized','position',[0.05 0.1 0.25 0.3]);
tableTitle = uicontrol('style','text', 'string','All points', 'units','normalized', 'position',[0.05 0.4 0.25 0.03], 'horizontalalignment','center', 'fontsize',14, 'backgroundcolor',BGCOLOR);


% ROI TRACE
% ---------
roiAx = axes('position',[.4 .1 .5 .2]);
hold on
box off
xlim([1 size(movingStack,3)])
xlabel('Z (um)')
ylabel('Intensity')
title('ROI profile')
roiTracePlot = plot(nan, 'b', 'linewidth',1);
for i = 1:numZPlanes
    setPlanePlots(i) = plot([nan nan],[nan nan],'r-','linewidth',2);
end
sliceMarkerLine = plot([1 1], ylim, 'k-');


% STACK SLIDER
% ------------ 
slider = uicontrol('style','slider', 'units','normalized', 'Position',[.4 .37 .5 .02]);   %[.91 .4 .02 .5]
slider.Min = 1;
slider.Max = numSlices;
slider.Value = 1;
slider.SliderStep = [1/numSlices 1/numSlices];
addlistener(slider, 'Value', 'PostSet',@sliderUpdate);
stackTopText = uicontrol('style','edit', 'string','100', 'units','normalized', 'Position',[.34 .37 .05 .02], 'Callback',@updateStackNumbers);
stackBottomText = uicontrol('style','edit', 'string','-100', 'units','normalized', 'Position',[.91 .37 .05 .02], 'Callback',@updateStackNumbers);
stackTopLabel = uicontrol('style','text', 'string','Start', 'units','normalized', 'Position',[.34 .39 .05 .02], 'backgroundcolor',BGCOLOR);
stackBottomLabel = uicontrol('style','text', 'string','Stop', 'units','normalized', 'Position',[.91 .39 .05 .02], 'backgroundcolor',BGCOLOR);


% PLANE BUTTONS
% -------------
setPlaneButton = uicontrol('style','pushbutton', 'string','Set Plane', 'units','normalized', 'Position',[.615 .95 .075 .025], 'Callback',@setPlaneButtonPress);
nextPlaneButton = uicontrol('style','pushbutton', 'string','Next >', 'units','normalized', 'Position',[.69 .95 .075 .025], 'Callback',@nextPlaneButtonPress);
prevPlaneButton = uicontrol('style','pushbutton', 'string','< Prev', 'units','normalized', 'Position',[.54 .95 .075 .025], 'Callback',@prevPlaneButtonPress);
resetPointsButton = uicontrol('style','pushbutton', 'string','Reset points', 'units','normalized', 'Position',[.83 .95 .075 .025], 'Callback',@resetPointsButtonPress);


% make cursor change to crosshair over image only
iptPointerManager(fig);
enterFcn = @(img, currentPoint) set(img, 'Pointer', 'crosshair');
iptSetPointerBehavior(img, enterFcn);
fig.WindowButtonMotionFcn = @MouseMove;


% update gui
updatePoints
updateROITrace
updateStackNumbers([],[])
sliderUpdate
updateMainTitle


% wait for user, return values
uiwait
movingPoints = allPoints(:,4:6);




% FUNCTIONS
% ---------
    function updateMainTitle
        titleString = {['Target plane: ' num2str(currentPlaneIdx) '/' num2str(numZPlanes) ' (' num2str(currentPlane) ' au)']...
            ['Stack slice: ' num2str(currentSlice) '/' num2str(numSlices) ' (' num2str(stackRange(currentSlice)) ' um)']};
        mainTitle.String = titleString;
    end


    function setPlaneButtonPress(h,e)
        setPlanePlots(currentPlaneIdx).XData = [currentSlice currentSlice];
        setPlanePlots(currentPlaneIdx).YData = roiAx.YLim;
        
        % update z coords of moving targets
        indices = fixedPoints(:,3) == currentPlane;
        allPoints(indices, 6) = currentSliceUM;
        
        % update scatter
        currentXY = allPoints(indices,4:5);
        if all(isnan(currentXY))
            allPoints(indices,4:5) = allPoints(indices,1:2);
        end
        movingPointPlots(currentPlaneIdx).XData = allPoints(indices,4);
        movingPointPlots(currentPlaneIdx).YData = allPoints(indices,5);
        movingPointPlots(currentPlaneIdx).Visible = 'on';

        
        updatePoints
    end


    function nextPlaneButtonPress(h,e)
        if currentPlaneIdx < numZPlanes
            currentPlaneIdx = currentPlaneIdx + 1;
            currentPlane = zPlanes(currentPlaneIdx);
            indices = find(allPoints(:,3)==currentPlane);
            if all(~isnan(allPoints(indices,6)))  % haven't set this plane
                slider.Value = numSlices - (find(stackRange==allPoints(indices(1),6))-1);
            end
            updateMainTitle
            updatePoints
        end
    end


    function prevPlaneButtonPress(h,e)
        if currentPlaneIdx > 1
            currentPlaneIdx = currentPlaneIdx - 1;
            currentPlane = zPlanes(currentPlaneIdx);
            indices = find(allPoints(:,3)==currentPlane);
            if all(~isnan(allPoints(indices,6)))  % haven't set this plane
                slider.Value = numSlices - (find(stackRange==allPoints(indices(1),6))-1);
            end
            updateMainTitle
            updatePoints
        end
    end


    function resetPointsButtonPress(h,e)
        indices = fixedPoints(:,3) == currentPlane;
        if all(~isnan(allPoints(indices,4:6)))
            allPoints(indices,4:5) = allPoints(indices,1:2);
            movingPointPlots(currentPlaneIdx).XData = allPoints(indices,4);
            movingPointPlots(currentPlaneIdx).YData = allPoints(indices,5);
        end
        updatePoints
    end


    function sliderUpdate(h,e)
        if slider.Value > slider.Max
            slider.Value = slider.Max;
        elseif slider.Value < slider.Min
            slider.Value = slider.Min;
        end
        currentSlice = round(slider.Value);  % because slider goes from bottom to top otherwise...
        currentSliceUM = stackRange(currentSlice);
        img.CData = movingStack(:,:,currentSlice);
        sliceMarkerLine.XData = [currentSlice currentSlice];
        sliceMarkerLine.YData = roiAx.YLim;
        movingPlanePatch.ZData = [currentSliceUM currentSliceUM currentSliceUM currentSliceUM];
        updateMainTitle();
        updatePoints
    end


    function updateStackNumbers(h,e)
        stackTop = str2double(stackTopText.String);
        stackBottom = str2double(stackBottomText.String);
        stackLimits = abs(diff([stackTop stackBottom]));
        stackSpacing = stackLimits / (numSlices-1);
        stackRange = stackTop:stackSpacing*sign(diff([stackTop stackBottom])):stackBottom;
        zeroSlice = find(stackRange==0);
        roiAx.XTick = [1 zeroSlice numSlices];
        roiAx.XTickLabels = {num2str(stackTop) '0' num2str(stackBottom)};
        sliderUpdate
        updateMainTitle
    end


    function updateROITrace
        centroid = [];
        centroid.x = ROImarker.XData;
        centroid.y = ROImarker.YData;
        ROI = dilateCentroidsSimple(centroid,5);
        [ROItrace,~] = extractTraces(movingStack,ROI,ROI,'mean');
        roiTracePlot.YData = ROItrace;
        roiAx.YLim = [min(ROItrace) max(ROItrace)];
        sliceMarkerLine.YData = roiAx.YLim;
        for j = 1:numZPlanes
            setPlanePlots(j).YData = roiAx.YLim;
        end
    end


    function CurrentPoint = FindClosestPoint()
        [currentX,currentY] = getXY();
        currentCoord = [currentX,currentY];
        indices = fixedPoints(:,3) == currentPlane;
        allCoords = allPoints(indices,4:5);
        distances = sqrt(sum(bsxfun(@minus, allCoords, currentCoord).^2,2));
        [~, CurrentPoint] = min(distances);
    end


    function MouseClickPoint(h,e)
        % find closest point
        currentPoint = FindClosestPoint();
        switch get(fig,'SelectionType')
            case 'normal'  % Left click
                fig.WindowButtonMotionFcn = {@MouseDrag, h, currentPoint};
                fig.WindowButtonUpFcn = {@MouseRelease, h};
        end
    end


    function MouseDrag(h,e,src,currentPoint)
        [x,y] = getXY();
        if strcmpi(src.Tag, 'roi')
            % set new data
            src.XData = x;
            src.YData = y;
            updateROITrace
        else  % assume it must be the moving scatter points
            indices = find(allPoints(:,6) == currentSliceUM);
            src.XData(currentPoint) = x;
            src.YData(currentPoint) = y;
            allPoints(indices(currentPoint),4) = x;
            allPoints(indices(currentPoint),5) = y;
            updatePoints
        end
    end


    function MouseMove(h,e)
        % Updates the cursor location text. Called whenever mouse is moving
        [x,y] = getXY();
    end


    function [x,y] = getXY()
        coords = get(imgAx,'currentpoint');
        x = round(coords(1,1,1));
        y = round(coords(1,2,1));
        
        % set edge limit
        if x < 1
            x = 1;
        elseif x > imgAx.XLim(2)-0.5
            x = imgAx.XLim(2)-0.5;
        end
        if y < 1
            y = 1;
        elseif y > imgAx.YLim(2)-0.5
            y = imgAx.YLim(2)-0.5;
        end
    end


    function MouseRelease(h,e,src)
        h.WindowButtonMotionFcn = @MouseMove;
        h.WindowButtonUpFcn = '';
    end


    function updatePoints
        updatePointsTable
        updateMovingPoints_Preview
        updateMovingPoints_Stack
        updateActiveMovingPlot
        updateActiveFixedPlot
    end


    function updatePointsTable
        % columns: x1,y1,z1, x2,y2,z2
        pointsTable.Data = allPoints;
    end


    function updateMovingPoints_Preview
        movingPointsPlot.XData = allPoints(:,4);
        movingPointsPlot.YData = allPoints(:,5);
        movingPointsPlot.ZData = allPoints(:,6);
    end


    function updateMovingPoints_Stack
        for j = 1:numZPlanes
            indices = fixedPoints(:,3) == zPlanes(j);
            if any(currentSliceUM == allPoints(indices,6))
                movingPointPlots(j).Visible = 'on';
                activeMovingPlot.XData = allPoints(indices,4);
                activeMovingPlot.YData = allPoints(indices,5);
                activeMovingPlot.ZData = allPoints(indices,6);

            else
                movingPointPlots(j).Visible = 'off';
                activeMovingPlot.XData = nan;
                activeMovingPlot.YData = nan;
                activeMovingPlot.ZData = nan;
            end
        end
    end


    function updateActiveMovingPlot
        indices = allPoints(:,6) == currentSliceUM;
        if any(indices)
            activeMovingPlot.XData = allPoints(indices,4);
            activeMovingPlot.YData = allPoints(indices,5);
            activeMovingPlot.ZData = allPoints(indices,6);
        else
            activeMovingPlot.XData = nan;
            activeMovingPlot.YData = nan;
            activeMovingPlot.ZData = nan;
        end
    end


    function updateActiveFixedPlot
        indices = allPoints(:,3) == currentPlane;
        activeFixedPlot.XData = allPoints(indices,1);
        activeFixedPlot.YData = allPoints(indices,2);
        activeFixedPlot.ZData = allPoints(indices,3);
    end

    function windowKeyPressFcn(hObject, eventdata, handles)
        keyPressed = eventdata.Key;
        if strcmpi(keyPressed,'rightarrow')
            nextPlaneButtonPress([],[]);
        elseif strcmpi(keyPressed,'leftarrow')
            prevPlaneButtonPress([],[]);
        elseif strcmpi(keyPressed,'uparrow')
            slider.Value = slider.Value + 1;
            sliderUpdate([],[]);
        elseif strcmpi(keyPressed,'downarrow')
            slider.Value = slider.Value - 1;
            sliderUpdate([],[]);
        elseif strcmpi(keyPressed, 'return')
            setPlaneButtonPress
        end
    end

end