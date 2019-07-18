function roi = dilateCentroidsSimple(centroids, roi_radius)
% LR 2017
% centroids: is a struct, with fields .x and .y
% halo_multiplier: relative to roi_radius, the alpha of a guassian kernal to approxiamte neuropil contamination.


% prepare arrays
img_size = [512,512];
num_points = numel(centroids.x);
all_rois = zeros(img_size(1), img_size(2), num_points);

% make ROI mask
sizeofMask = (roi_radius)*2;
if ~mod(sizeofMask,2)
    sizeofMask = sizeofMask+1;
end
centroid_mask = zeros(sizeofMask, sizeofMask);
centroid_mask(ceil(sizeofMask/2), ceil(sizeofMask/2)) = 1;
SE = strel('sphere',roi_radius);
roi_mask = imdilate(centroid_mask, SE);

% convolve all the centroids with the ROI/halo/watershed kernels
for i = 1:num_points
    % make a centroid point image
    this_img = zeros(img_size(1), img_size(2));
    this_img(centroids.y(i), centroids.x(i)) = 1;
    
    % now convolve the point with the kernels
    all_rois(:,:,i)      = conv2(this_img, roi_mask, 'same'); 
end

% save the results
roi = cell(num_points,1);
for i = 1:num_points
    % roi
    [coords_y, coords_x, weights] = find(all_rois(:,:,i) > 0);
    roi{i}.coords = sub2ind(img_size, coords_y, coords_x);
    roi{i}.weights = weights;
    roi{i}.image = all_rois(:,:,i);
end
