function M = get_affine(c1, c2)
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

% add dim
c1 = [c1 ones(size(c1,1),1)];
c2 = [c2 ones(size(c2,1),1)];

% get affine matrix
M = c1 \ c2;

