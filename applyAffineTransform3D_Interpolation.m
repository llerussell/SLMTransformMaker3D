function transformedPoints = applyAffineTransform3D_Interpolation(input_points, T)
% input_points       : 3xn array of coordinates (xyz)
% transformed_points : 3xn array of coordinates (xyz)

num_points = size(input_points, 1);
transformedPoints = zeros(num_points,3);
M=[];
for i =1:numel(T.M)
    M(i,:,:) = T.M{i};
end

for i = 1:num_points
    % convert from microns to required arbitrary units
    z_intended_um = input_points(i,3);
    sample_points = T.measuredZ;
    query_point = z_intended_um;
    z_required_au = interp1(sample_points, T.testedZ, query_point, 'spline');
   
    % generate a custom transformation matrix by interpolation
    sample_points = T.measuredZ;
    query_point = z_intended_um;
    interp_tform = squeeze(interp1(sample_points, M, query_point, 'spline'));

    % transform the points
    transformedPoints(i,:) = [apply_affine(input_points(i,1:2), interp_tform) z_required_au];
%     T = affine2d(interp_tform);
%     temp = transformPointsForward(T, input_points(1:2,i)');
%     transformed_points(:,i) = [temp'; z_required_au];
end
