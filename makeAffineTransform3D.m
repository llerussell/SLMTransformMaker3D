function T = makeAffineTransform3D(fixedPoints, movingPoints)
% for each plane (unique Z) get the affine transform
% Lloyd Russell 2018

% if 2D add z coordinate (0)
if size(fixedPoints,2) == 2
    fixedPoints(:,3) = zeros(size(fixedPoints,1),1);
end
if size(movingPoints,2) == 2
    movingPoints(:,3) = zeros(size(movingPoints,1),1);
end

% extract Z
testedZ = unique(fixedPoints(:,3), 'stable');
measuredZ = unique(movingPoints(:,3), 'stable');
numPlanes = numel(testedZ);

% make transforms
M = [];
scaleFactors = [];
for i = 1:numPlanes
    thisPlane = testedZ(i);
    thesePointsIdx = find(fixedPoints(:,3)==thisPlane);
    M{i} = get_affine(movingPoints(thesePointsIdx,1:2), fixedPoints(thesePointsIdx,1:2));
    scaleFactors(i) = mean(mean(pairwiseDistance(movingPoints(thesePointsIdx,1:2),movingPoints(thesePointsIdx,1:2)))) / mean(mean(pairwiseDistance(fixedPoints(thesePointsIdx,1:2),fixedPoints(thesePointsIdx,1:2))));
end
try
scaleFactors = scaleFactors./scaleFactors(testedZ==0);
catch
    [~,idx] = min(abs(testedZ));
scaleFactors = scaleFactors./scaleFactors(idx);
end

% store in struct
T.fixedPoints = fixedPoints;
T.movingPoints = movingPoints;
T.testedZ = testedZ;
T.measuredZ = measuredZ;
T.M = M;
T.scaleFactors = scaleFactors;
