function transformed = apply_affine(points, M)
% Description
% ===========--------------------------------------------------------------
% Apply an affine transformation to the input set of points.
%
% Input
% =====--------------------------------------------------------------------
% points : n*d array of xy(z) coordinates to transform
% M      : 3*3 (2D) or 4*4 (3D) affine transformation matrix
% 
% Output
% ======-------------------------------------------------------------------
% transformed : n*d array of xy(z) coordinates 
% 
% Author
% ======-------------------------------------------------------------------
% Lloyd Russell 2016 (@llerussell)


% make homogenous coordinates (nx4 array)
homogenous = [points, ones(size(points,1),1)];

% apply transformation
transformed =  homogenous * M;

% discard the 4th dimension (homogenous)
transformed = transformed(:,1:end-1);
