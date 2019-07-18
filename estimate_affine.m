function M = estimate_affine(v0, v1)
% Description
% ===========--------------------------------------------------------------
% Estimates the affine transformation required to register the point set
% 'v0' with another point set 'v1'. The returned transormation matrix
% performs rotation, translation, shearing and scaling.
%
% Input
% =====--------------------------------------------------------------------
% v0 : dxn array of xy(z) coordinates
% v1 : dxn array of xy(z) coordinates of same size as v0
% 
% Output
% ======-------------------------------------------------------------------
% M : 3x3 (2D) or 4x4 (3D) affine transformation matrix
% 
% Authors
% =======------------------------------------------------------------------
% Lloyd Russell 2016 (@llerussell)
% Ported from Christoph Gohlke's 'transformations.py'
% http://www.lfd.uci.edu/~gohlke/code/transformations.py.html
% which implements the Hartley and Zissermann algorithm:
% Multiple View Geometry in Computer Vision. Hartley and Zissermann.
% Cambridge University Press; 2nd Ed. 2004. Chapter 4, Algorithm 4.7, p130.


ndims = size(v0, 1);

% move centroids to origin
t0 = -mean(v0, 2)';
M0 = eye(ndims+1);
M0(1:ndims, ndims+1) = t0;
v0 = v0 + repmat(t0', 1, size(v0, 2));
t1 = -mean(v1, 2)';
M1 = eye(ndims+1);
M1(1:ndims, ndims+1) = t1;
v1 = v1 + repmat(t1' ,1, size(v1, 2));

% affine transformation
A = cat(1, v0, v1);
[u, s, v] = svd(A');
vh = v';
vh = vh(1:ndims, :)';
B = vh(1:ndims, 1:ndims);
C = vh(ndims+1:2*ndims, :);
t = C * pinv(B);
t = cat(2, t, zeros(ndims, 1));
M = cat(1, t, zeros(1, ndims+1));
M(end, end) = 1;

% move centroids back
M = (M1 \ (M * M0));
M = M / M(ndims+1, ndims+1);
