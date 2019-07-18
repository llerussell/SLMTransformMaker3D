%% SLMTransformMaker3D
% 3D SLM calibration routine
% Lloyd Russell 2018

%% options
savePath = 'C:\Users\User\Dropbox\Bruker2\SLM\3Dcalibration';
cd(savePath)

x = [-50  -50 -50 -50  0 50] + 256;
y = [-100 -50   0  50 50 50] + 256;
z = [-30 -15 0 15 30];  % nb on Bruker2 -100 goes -400, +50 goes +300
% z = [-20:0];  % nb on Bruker2 -100 goes -400, +50 goes +300

BurnZPlanesSeparately = true;

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

%% Make and save phase mask(s)
if ~BurnZPlanesSeparately
    [PhaseMask, TransformedSLMTarget] = SLMPhaseMaskMakerCUDA3D(...
        'Points', fixedPoints,...
        'Save', true,...
        'SaveName', ['3Dtargets_' timestamp '.tif'],...
        'Do2DTransform', false,...
        'Do3DTransform', false,...
        'AutoAdjustWeights', false);
    
    % plot the targets and mask
    figure('Position',[100,100,1600,800])
    subplot(1,2,1)
    plot3(fixedPoints(:,1), fixedPoints(:,2), fixedPoints(:,3), 'ko', 'markerfacecolor','k')
    hold on
    plot3(256,256,0,'r+')
    xlim([1 512])
    ylim([1 512])
    axis square
    grid on
    title('SLM targets')
    
    subplot(1,2,2)
    imagesc(PhaseMask{1})
    axis square
    axis off
    title('Phase mask')
    colormap(gray)
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
    
    % plot the targets and mask
    figure('Position',[100,100,1600,800])
    subplot(1,2,1)
    plot3(fixedPoints(:,1), fixedPoints(:,2), fixedPoints(:,3), 'ko', 'markerfacecolor','k')
    hold on
    plot3(256,256,0,'r+')
    xlim([1 512])
    ylim([1 512])
    axis square
    grid on
    title('SLM targets')
    
    subplot(1,2,2)
    imagesc(PhaseMask{1})
    axis square
    axis off
    title('Phase mask')
    colormap(gray)
end

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
movingPoints = cpselect3d(movingStack, fixedPoints(:,1:3));

%% Make and apply transforms
fixedPoints = fixedPoints(:,1:3);
T    = makeAffineTransform3D(fixedPoints, movingPoints);
Tinv = makeAffineTransform3D(movingPoints, fixedPoints);

transformedSpots   = applyAffineTransform3D_Interpolation(movingPoints, T);
compensatedTargets = applyAffineTransform3D_Interpolation(fixedPoints, T);

%% Save
timestamp = datestr(now, 'yyyymmdd_HHMM');
save(['3DTransform_' timestamp],'T', 'Tinv')

%% Plot results
% Plot all 3D points
figure
plot3(fixedPoints(:,1), fixedPoints(:,2), fixedPoints(:,3), 'b.', 'markersize',20)
hold on
axis vis3d
axis square
box on
plot3(movingPoints(:,1), movingPoints(:,2), movingPoints(:,3), 'r.', 'markersize',20)
plot3(transformedSpots(:,1), transformedSpots(:,2), transformedSpots(:,3), 'o', 'color','m', 'markersize',12, 'linewidth',2)
plot3(compensatedTargets(:,1), compensatedTargets(:,2), compensatedTargets(:,3), 'o', 'color','k', 'markersize',12, 'linewidth',2)
% legend({'Targets','Spots','Transformed spots','Compensated targets'}, 'location', 'southoutside')
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
scatter(T.testedZ, T.measuredZ, 100, 'k', 'filled')
x = [min(T.testedZ):max(T.testedZ)];
y = interp1(T.testedZ, T.measuredZ, x, 'spline');
plot(x,y, 'k-', 'linewidth',2)
axis square
xlabel('Algorithm displacement (au)', 'Color','b')
ylabel('Measured displacement (um)', 'Color','r')
title('Z calibration (au to um)')
grid on

subplot(1,2,2)
hold on
scatter(T.testedZ, T.scaleFactors, 100, 'k', 'filled')
y = interp1(T.testedZ, T.scaleFactors, x, 'spline');
plot(x,y, 'k-', 'linewidth',2)
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
