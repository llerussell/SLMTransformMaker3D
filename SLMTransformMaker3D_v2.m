%% SLMTransformMaker3D
% 3D SLM calibration routine
% Lloyd Russell 2018
% v2 include galvo positions


%% options
savePath = 'C:\Users\User\Dropbox\Bruker2\SLM\3Dcalibration';
cd(savePath)

slmPointSpacing = 20;
x = [-1 -1 -1 -1 0 1] *slmPointSpacing;
y = [-2 -1  0  1 1 1] *slmPointSpacing;
z = [-30 -15 0 15 30];  % nb on Bruker2 -100 goes -400, +50 goes +300

BurnZPlanesSeparately = true;

galvoGridMargin = 100;
galvoGridNumPoints = 3;
[galvoX, galvoY] = meshgrid(linspace(galvoGridMargin, 512-galvoGridMargin,galvoGridNumPoints),linspace(galvoGridMargin, 512-galvoGridMargin,galvoGridNumPoints)) ;  % in pixels
numGalvoLocations = numel(galvoX);


%% Make and save 3D SLM targets
fixedPoints = [];
for i = 1:numel(z)
    temp = [];
    for j = 1:numel(x)
        temp(j,:) = [x(j) y(j) z(i) 1];  % 4th element is 'I'
    end
    fixedPoints = [fixedPoints; temp];
end
timestamp = datestr(now, 'yyyymmdd_HHMM');
save(['FixedPointsfor3DTransform_' timestamp],'fixedPoints')


%% make all fixed Points, for each Galvo locations
allFixedPoints = {};
for g = 1:numGalvoLocations
    allFixedPoints{g} = fixedPoints + [galvoX(g) galvoY(g) 0 0];
end
    

%% Make and save phase mask(s)
if ~BurnZPlanesSeparately
    [PhaseMask, TransformedSLMTarget] = SLMPhaseMaskMakerCUDA3D(...
        'Points', fixedPoints + [256 256 0 0],...
        'Save', true,...
        'SaveName', ['3Dtargets_' timestamp '.tif'],...
        'Do2DTransform', false,...
        'Do3DTransform', false,...
        'AutoAdjustWeights', false);

else
    for i = 1:numel(z)
        thisZ = z(i);
        thesePoints = fixedPoints(fixedPoints(:,3)==thisZ,:);
        [PhaseMask, TransformedSLMTarget] = SLMPhaseMaskMakerCUDA3D(...
            'Points', thesePoints,...
            'Save', true,...
            'SaveName', [num2str(i, '%03d') '_Z=' num2str(thisZ, '%03d') '_3Dtargets_' timestamp '.tif'],...
            'Do2DTransform', false,...
            'Do3DTransform', false,...
            'AutoAdjustWeights', false);
    end
end


%% make galvo location file
isSpiral = 'True';
spiralDiameter = 40;
MarkPoints_GPLMaker(round(galvoX(:)), round(galvoY(:)), isSprial, spiralDiameter, 3, ['Transform3DGalvoPositions_' timestamp]);


%% plot the targets and mask
figure('Position',[100,100,1600,800])

subplot(1,2,1)
plot3(256,256,0, 'k+')
hold on
set(gca, 'ydir','reverse')

colours = hsv(numGalvoLocations+1);
for g = 1:numGalvoLocations
    c = colours(g, :);
    plot3(galvoX(g),galvoY(g), 0, '+', 'color','k')
    scatter3(allFixedPoints{g}(:,1), allFixedPoints{g}(:,2), allFixedPoints{g}(:,3), 'filled', 'markerfacecolor',c)
end
xlim([1 512])
ylim([1 512])
axis square
grid on
title('SLM targets')

% subplot(1,2,2)
% imagesc(PhaseMask{1})
% axis square
% axis off
% title('Phase mask')
% colormap(gray)


%% Load 2P stack of burnt targets
[fileName, pathName] = uigetfile('*.tif*', 'Select the moving stack (2P)');
movingStack = double(TiffReader([pathName filesep fileName]));

% Process (subtract background)
for i = 1:size(movingStack,3)
    background = imgaussfilt(movingStack(:,:,i),50);
    movingStack(:,:,i) = movingStack(:,:,i) ./ background;
end
movingStack = imgaussfilt3(movingStack,[1 1 1]);

% show min projection
minImg = min(movingStack,[],3);
figure
imagesc(minImg)
axis square
axis off
title('Minimum projection of processed stack')
colormap(gray)


%% Select the moving points (find SLM targets in 2P space)
movingStack = rand(512,512,100);
allConcatPoints = vertcat(allFixedPoints{:});
movingPoints = cpselect3d(movingStack, allConcatPoints);




%% break moving points up into cell array - one for each galvo location, offset the galvo position
for g = 1:numGalvoLocations
    numPointsPerPosition = (size(allConcatPoints,1)/numGalvoLocations);
    idx = [1:numPointsPerPosition] + ((g-1)*numPointsPerPosition);
    allMovingPoints{g} = movingPoints(idx,:) - [galvoX(g) galvoY(g) 0] + [256 256 0];  % offset galvo, put into centre (slm)
    offsetFixedPoints{g} = allFixedPoints{g} - [galvoX(g) galvoY(g) 0 0] + [256 256 0 0];
    galvoXY{g} = [galvoX(g) galvoY(g)];
end


%% Make and apply transforms
for g = 1:numGalvoLocations
    fp = offsetFixedPoints{g};
    mp = allMovingPoints{g};
    
    T{g} = makeAffineTransform3D(fp, mp);
    T{g}.galvoXY = galvoXY{g};
    Tinv{g} = makeAffineTransform3D(mp, fp);
    Tinv{g}.galvoXY = galvoXY{g};
end

for g = 1:numGalvoLocations
    fp = offsetFixedPoints{g};
    mp = allMovingPoints{g};
    
    transformedSpots{g}   = applyAffineTransform3D_GalvoOffset(mp, galvoXY{g}, T);
    compensatedTargets{g} = applyAffineTransform3D_GalvoOffset(fp, galvoXY{g}, T);
end

%% plot moving points
figure('Position',[100,100,1600,800])

subplot(1,2,1)
plot3(256,256,0, 'k+')
hold on
set(gca, 'ydir','reverse')

colours = hsv(numGalvoLocations+1);
for g = 1:numGalvoLocations
    c = colours(g, :);
    plot3(galvoX(g),galvoY(g), 0, '+', 'color','k')
    scatter3(allFixedPoints{g}(:,1), allFixedPoints{g}(:,2), allFixedPoints{g}(:,3), 'filled', 'markerfacecolor',c)
end
xlim([1 512])
ylim([1 512])
axis square
grid on
title('SLM targets')

subplot(1,2,2)
plot3(256,256,0, 'k+')
hold on
set(gca, 'ydir','reverse')

colours = hsv(numGalvoLocations+1);
for g = 1:numGalvoLocations
    c = colours(g, :);
    plot3(galvoX(g),galvoY(g), 0, '+', 'color','k')
    scatter3(allMovingPoints{g}(:,1) + galvoX(g) - 256, allMovingPoints{g}(:,2) + galvoY(g) - 256, allMovingPoints{g}(:,3), 'filled', 'markerfacecolor',c)
end
xlim([1 512])
ylim([1 512])
axis square
grid on
title('Burnt spots')



%% Save
timestamp = datestr(now, 'yyyymmdd_HHMM');
save(['3DTransform_' timestamp],'T', 'Tinv')


%% Plot results
% Plot all 3D points
figure
hold on
axis vis3d
axis square
box on
colours = hsv(numGalvoLocations+1);
for g = 1:numGalvoLocations
    
    thisXoffset = galvoX(g)-256;
    thisYoffset = galvoY(g)-256;
    
    c = colours(g, :);
    plot3(allFixedPoints{g}(:,1), allFixedPoints{g}(:,2), allFixedPoints{g}(:,3), 'b.', 'markersize',20)
    plot3(allMovingPoints{g}(:,1)+thisXoffset, allMovingPoints{g}(:,2)+thisYoffset, allMovingPoints{g}(:,3), 'r.', 'markersize',20)
    plot3(transformedSpots{g}(:,1)+thisXoffset, transformedSpots{g}(:,2)+thisYoffset, transformedSpots{g}(:,3), 'o', 'color','m', 'markersize',12, 'linewidth',2)
    plot3(compensatedTargets{g}(:,1)+thisXoffset, compensatedTargets{g}(:,2)+thisYoffset, compensatedTargets{g}(:,3), 'o', 'color','k', 'markersize',12, 'linewidth',2)
end
legend({'Targets','Spots','Transformed spots','Compensated targets'}, 'location', 'southoutside')
set(gca, 'ydir','reverse')
xlim([1 512])
ylim([1 512])
title('All points')
xlabel('X')
ylabel('Y')
zlabel('Z')

% Plot Z to AU and scale factor
figure
subplot(1,2,1)
hold on
for g = 1:numGalvoLocations
    c = colours(g, :);
    scatter(T{g}.testedZ, T{g}.measuredZ, 100, 'k', 'filled', 'markerfacecolor',c)
    x = [min(T{g}.testedZ):max(T{g}.testedZ)];
    y = interp1(T{g}.testedZ, T{g}.measuredZ, x, 'linear');
    plot(x,y, 'k-', 'linewidth',2, 'color',c)
end
axis square
xlabel('Algorithm displacement (au)', 'Color','b')
ylabel('Measured displacement (um)', 'Color','r')
title('Z calibration (au to um)')
grid on

subplot(1,2,2)
hold on
for g = 1:numGalvoLocations
    c = colours(g, :);
    scatter(T{g}.testedZ, T{g}.scaleFactors, 100, 'k', 'filled', 'markerfacecolor',c)
    x = [min(T{g}.testedZ):max(T{g}.testedZ)];
    y = interp1(T{g}.testedZ, T{g}.scaleFactors, x, 'linear');
    plot(x,y, 'k-', 'linewidth',2, 'color',c)
end
axis square
xlabel('Algorithm displacement (au)', 'Color','b')
ylabel('Scale factor (measured/target relative to plane=0)', 'Color','r')
title('Scale factor')
grid on


%% make a test 3d pattern
% spiral

% first make a circle
CentreXY = [256,256];
Npoints = 11;
Radius = 50;  % in pixels
Points = [];
Zrange = [-100 100];
Zrange = Zrange(1):diff(Zrange)/(Npoints-1):Zrange(2);

for i = 1:Npoints
    thisAngle = (360/Npoints)*(i-1);
    Points(i,:) = [CentreXY(1) + Radius*sind(thisAngle), CentreXY(2) + Radius*cosd(thisAngle), Zrange(i), 1];  % x,y,z,i
end

figure
plot3(Points(:,1),Points(:,2),Points(:,3), 'o-')
axis vis3d
OptionZ.FrameRate=30;
OptionZ.Duration=10;
OptionZ.Periodic=true;
CaptureFigVid([0,30; 180,30; 360,30], 'RotatingSpiral',OptionZ)

[PhaseMask, TransformedSLMTarget] = SLMPhaseMaskMakerCUDA3D(...
    'Points', Points,...
    'Save', true,...
    'SaveName', ['Transformed3DTestPattern_' timestamp '.tif'],...
    'Do3DTransform', true,...
    'AutoAdjustWeights', false);


%% word
word = 'LLOYD';
font = 'Minecraftia';
fontSize = 8;
scaleFactor = 5;
NumLetters = numel(word);
CentreXY = [256,256];
Zrange = [-50 50];
Zrange = Zrange(1):diff(Zrange)/(NumLetters-1):Zrange(2);

characters = char(32:126);
characterImgs = [];
for i = 1:numel(characters)
    c = characters(i);
    characterImgs(i,:,:) = rgb2gray(insertText(zeros(14, 8, 1), [5 7], c, ...
        'Font', font, ...
        'FontSize', fontSize,...
        'AnchorPoint', 'Center', ...
        'TextColor', [1 1 1], ...
        'BoxOpacity', 0)) > 0.5;
end

indices = unicode2native(word) - 31;
temp = [];
z = [];
for i = 1:numel(indices)
    temp = [temp squeeze(characterImgs(indices(i),:,:))];
    z = [z Zrange(i)*ones(1,numel(find(characterImgs(indices(i),:,:))))];
end
wordImg = temp;
[y,x] = find(wordImg);
x = CentreXY(1) + round(scaleFactor*x - mean(scaleFactor*[min(x) max(x)]));
y = CentreXY(2) + round(scaleFactor*y - mean(scaleFactor*[min(y) max(y)]));

figure
scatter3(x,y,z, 'filled')
axis vis3d

[PhaseMask, TransformedSLMTarget] = SLMPhaseMaskMakerCUDA3D(...
    'Points', [x y z' ones(size(x))],...
    'Save', true,...
    'SaveName', ['Transformed3DWord_' word timestamp '.tif'],...
    'Do3DTransform', true,...
    'AutoAdjustWeights', false);



%% focal plane finder
x = [-25:5:25] + 256;
y = [-20 * ones(size(x))] + 256;
z = [-5:1:5];

x = [x 256 256];
y = [y 241 231];
z = [z 0 0];

thesePoints = [y; x; z; ones(size(x))]';

[PhaseMask, TransformedSLMTarget] = SLMPhaseMaskMakerCUDA3D(...
    'Points', thesePoints,...
    'Save', true,...
    'SaveName', 'FocalPlaneFinder.tif',...
    'Do3DTransform', false,...
    'Do2DTransform', false,...
    'AutoAdjustWeights', false);
