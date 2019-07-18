function transformedPoints = applyAffineTransform3D(points, T)
% Lloyd Russell 2018

% if 2D add z coordinate (0)
if size(points,2) == 2
    points(:,3) = zeros(size(points,1),1);
end

% get the calibrated z coordinates
desiredZ = points(:,3);
requiredZ = interp1(T.measuredZ, T.testedZ, desiredZ, 'spline');
uniqueDesiredZ = unique(desiredZ, 'stable');
uniqueRequiredZ = unique(requiredZ, 'stable');
numPlanes = numel(uniqueRequiredZ);

% find the closest two calibration planes (1 above and 1 below)
closestPlanes = [];
distancesBetweenPlanes = [];
for i = 1:numPlanes
    closestPlanes(i,:) = findClosestTwoPlanes(uniqueRequiredZ(i), T.testedZ);
    distancesBetweenPlanes(i,:) = T.testedZ(closestPlanes(i,:)) - uniqueRequiredZ(i);
end
absDist = abs(distancesBetweenPlanes);
absDist(all(absDist==0, 2),:) = 1;
weights = 1 - (absDist ./ sum(absDist,2));

% transform the points, plane by plane
transformedPoints = [];
transformedPoints(:,3) = requiredZ;
for i = 1:numPlanes
    % get the current points and plane
    thisPlane = uniqueDesiredZ(i);
    thesePointsIdx = find(points(:,3)==thisPlane);
    thesePoints = points(thesePointsIdx,1:2);
    thisClosestPlanes = closestPlanes(i,:);
    thisWeights = weights(i,:);
    
    % apply transform to points in two closest calibration planes
    temp1 = apply_affine(thesePoints, T.M{thisClosestPlanes(1)});
    temp2 = apply_affine(thesePoints, T.M{thisClosestPlanes(2)});
    
    % interpolate (take the weighted average) of those two planes
    temp3 = (temp1 * thisWeights(1)) + (temp2 * thisWeights(2));
    
    % store transformed points
    transformedPoints(thesePointsIdx,1:2) = temp3;
end

