function transformedPoints = applyAffineTransform3D_GalvoOffset(input_points, galvo_offset, T)
% Inputs:
% -------
% input_points       : 3xn array of coordinates (xyz)
% galvo_offset       : xy coordiantes (1x2 vecotr)
% T is cell array of transform matrices for calibrated galvo locations

% Outputs:
% --------
% transformed_points : 3xn array of coordinates (xyz)


% given galvo offset create a new transform matrix by interpolation
queryX = galvo_offset(1);
queryY = galvo_offset(2);
for i = 1:numel(T)
    sampleX(i) = T{i}.galvoXY(1);
    sampleY(i) = T{i}.galvoXY(2);
end

allM = [];
for g = 1:numel(T)
    for z = 1:numel(T{g}.M)
        allM(g,z,:,:) = T{g}.M{z};
    end
end

keyboard

[xs,ys] = meshgrid(linspace(1,512,512), linspace(1,512,512));
for z = 1:numel(T{g}.M)
    figure('position',[100 100 800 800])
    for m = 1:9
        subplot(3,3,m)
        axis square
        hold on
        im = interp2(reshape(sampleX,3,3), reshape(sampleY,3,3), reshape(squeeze(allM(:,z,m)),3,3), xs,ys,  'linear');
        imagesc(im)

        colorbar()
        xlim([1 size(xs,1)])
        ylim([1 size(xs,2)]) 
        title(['element ' num2str(m)])

    end
    suptitle(['plane ' num2str(z) '. affine transform matrix element interpolations'])
end

newM = [];
for z = 1:numel(T{1}.measuredZ)
    newM{z} = zeros(3,3);
    for m = 1:9
        newM{z}(m) = interp2(reshape(sampleX,3,3), reshape(sampleY,3,3), reshape(squeeze(allM(:,z,m)),3,3), queryX, queryY, 'spline');
    end
end

M = [];
for z = 1:numel(newM)
    M(z,:,:) = newM{z};
end


num_points = size(input_points, 1);
transformedPoints = zeros(num_points,3);

for i = 1:num_points
    % convert from microns to required arbitrary units
    z_intended_um = input_points(i,3);
    sample_points = T{1}.measuredZ;
    query_point = z_intended_um;
    z_required_au = interp1(sample_points, T{1}.testedZ, query_point, 'spline');
   
    % generate a custom transformation matrix by interpolation
    sample_points = T{1}.measuredZ;
    query_point = z_intended_um;
    interp_tform = squeeze(interp1(sample_points, M, query_point, 'spline'));

    % transform the points
    transformedPoints(i,:) = [apply_affine(input_points(i,1:2), interp_tform) z_required_au];
%     T = affine2d(interp_tform);
%     temp = transformPointsForward(T, input_points(1:2,i)');
%     transformed_points(:,i) = [temp'; z_required_au];
end
