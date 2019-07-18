% cube of points
x_range = [-50:100:50] + 256;
y_range = [-50:100:50] + 256;
z_range = -25:50:25;
[x,y,z] = meshgrid(x_range,y_range,z_range);
x = x(:); y = y(:); z = z(:);
c = hsv(numel(x));

newpoints = applyAffineTransform3D([x y z], Tinv);
x2 = newpoints(:,1);
y2 = newpoints(:,2);
z2 = newpoints(:,3);

K = unique(convhull([x y z]));

%% Plot the fixed and moving points. Animate: camer rotation
% k = boundary(x,y,z);
% k2 = boundary(x2,y2,z2);

figure
ax = subplot(1,1,1);


% fixed points
scatter3(x,y,z,50, 'k', 'filled')
hold on
axis vis3d
axis square

% plot a cube outline
plot3(x([1 2 4 3 1]),y([1 2 4 3 1]),z([1 2 4 3 1]), '-', 'color','k', 'linewidth',1)
plot3(x([5 6 8 7 5]),y([5 6 8 7 5]),z([5 6 8 7 5]), '-', 'color','k', 'linewidth',1)
plot3(x([1 5]),y([1 5]),z([1 5]), '-', 'color','k', 'linewidth',1)
plot3(x([2 6]),y([2 6]),z([2 6]), '-', 'color','g', 'linewidth',2)
plot3(x([3 7]),y([3 7]),z([3 7]), '-', 'color','k', 'linewidth',1)
plot3(x([4 8]),y([4 8]),z([4 8]), '-', 'color','k', 'linewidth',1)
plot3(x([5 6]),y([5 6]),z([5 6]), '-', 'color','b', 'linewidth',2)
plot3(x([6 8]),y([6 8]),z([6 8]), '-', 'color','r', 'linewidth',2)
xlim([1 512]); ylim([1 512]); zlim([-200 200])

% moving points
scatter3(x2,y2,z2,50, 'k', 'filled')

% plot a cube outline
plot3(x2([1 2 4 3 1]),y2([1 2 4 3 1]),z2([1 2 4 3 1]), '-', 'color','k', 'linewidth',1)
plot3(x2([5 6 8 7 5]),y2([5 6 8 7 5]),z2([5 6 8 7 5]), '-', 'color','k', 'linewidth',1)
plot3(x2([1 5]),y2([1 5]),z2([1 5]), '-', 'color','k', 'linewidth',1)
plot3(x2([2 6]),y2([2 6]),z2([2 6]), '-', 'color','g', 'linewidth',2)
plot3(x2([3 7]),y2([3 7]),z2([3 7]), '-', 'color','k', 'linewidth',1)
plot3(x2([4 8]),y2([4 8]),z2([4 8]), '-', 'color','k', 'linewidth',1)
plot3(x2([5 6]),y2([5 6]),z2([5 6]), '-', 'color','b', 'linewidth',2)
plot3(x2([6 8]),y2([6 8]),z2([6 8]), '-', 'color','r', 'linewidth',2)
xlim([1 512]); ylim([1 512]); zlim([-200 200])

xlabel('X')
ylabel('Y')
zlabel('Z')
xticks([])
yticks([])
zticks([])
ax.XColor = 'r';
ax.YColor = 'b';
ax.ZColor = 'g';


% animation loop
animationSteps = 360;
rotationStep = 367 / animationSteps;  %367
rotation = 45;

for i = 1:animationSteps
    rotation = rotation + rotationStep;
    view(ax, [rotation 30])
    drawnow
end


%% Animation: transition between two coordinates
animationSteps = 30;
a = linspace(0,1,animationSteps);
x_ani = (x + a.*(x2 - x))';
y_ani = (y + a.*(y2 - y))';
z_ani = (z + a.*(z2 - z))';

figure
ax2 = subplot(1,1,1);
plot3(x2([1 2 4 3 1]),y2([1 2 4 3 1]),z2([1 2 4 3 1]), '-', 'color','k', 'linewidth',1)
xlim([1 512]); ylim([1 512]); zlim([-200 200])
axis square
hold on
grid on
view(ax2, [45 30])

xlabel('X')
ylabel('Y')
zlabel('Z')
xticks([])
yticks([])
zticks([])
ax2.XColor = 'r';
ax2.YColor = 'b';
ax2.ZColor = 'g';
axis vis3d

for i = 1:animationSteps
    % clear the axes
    cla(ax2)
    
    % redraw the fixed points
    plot3(x([1 2 4 3 1]),y([1 2 4 3 1]),z([1 2 4 3 1]), '-', 'color','k', 'linewidth',1)
    plot3(x([5 6 8 7 5]),y([5 6 8 7 5]),z([5 6 8 7 5]), '-', 'color','k', 'linewidth',1)
    plot3(x([1 5]),y([1 5]),z([1 5]), '-', 'color','k', 'linewidth',1)
    plot3(x([2 6]),y([2 6]),z([2 6]), '-', 'color','g', 'linewidth',2)
    plot3(x([3 7]),y([3 7]),z([3 7]), '-', 'color','k', 'linewidth',1)
    plot3(x([4 8]),y([4 8]),z([4 8]), '-', 'color','k', 'linewidth',1)
    plot3(x([5 6]),y([5 6]),z([5 6]), '-', 'color','b', 'linewidth',2)
    plot3(x([6 8]),y([6 8]),z([6 8]), '-', 'color','r', 'linewidth',2)
    
    % redraw the moving points
    plot3(x2([1 2 4 3 1]),y2([1 2 4 3 1]),z2([1 2 4 3 1]), '-', 'color','k', 'linewidth',1)
    plot3(x2([5 6 8 7 5]),y2([5 6 8 7 5]),z2([5 6 8 7 5]), '-', 'color','k', 'linewidth',1)
    plot3(x2([1 5]),y2([1 5]),z2([1 5]), '-', 'color','k', 'linewidth',1)
    plot3(x2([2 6]),y2([2 6]),z2([2 6]), '-', 'color','g', 'linewidth',2)
    plot3(x2([3 7]),y2([3 7]),z2([3 7]), '-', 'color','k', 'linewidth',1)
    plot3(x2([4 8]),y2([4 8]),z2([4 8]), '-', 'color','k', 'linewidth',1)
    plot3(x2([5 6]),y2([5 6]),z2([5 6]), '-', 'color','b', 'linewidth',2)
    plot3(x2([6 8]),y2([6 8]),z2([6 8]), '-', 'color','r', 'linewidth',2)
    
    % draw the current animated transition
    plot3(x_ani(i,[1 2 4 3 1]),y_ani(i,[1 2 4 3 1]),z_ani(i,[1 2 4 3 1]), '-', 'color','k', 'linewidth',1)
    plot3(x_ani(i,[5 6 8 7 5]),y_ani(i,[5 6 8 7 5]),z_ani(i,[5 6 8 7 5]), '-', 'color','k', 'linewidth',1)
    plot3(x_ani(i,[1 5]),y_ani(i,[1 5]),z_ani(i,[1 5]), '-', 'color','k', 'linewidth',1)
    plot3(x_ani(i,[2 6]),y_ani(i,[2 6]),z_ani(i,[2 6]), '-', 'color','g', 'linewidth',2)
    plot3(x_ani(i,[3 7]),y_ani(i,[3 7]),z_ani(i,[3 7]), '-', 'color','k', 'linewidth',1)
    plot3(x_ani(i,[4 8]),y_ani(i,[4 8]),z_ani(i,[4 8]), '-', 'color','k', 'linewidth',1)
    plot3(x_ani(i,[5 6]),y_ani(i,[5 6]),z_ani(i,[5 6]), '-', 'color','b', 'linewidth',2)
    plot3(x_ani(i,[6 8]),y_ani(i,[6 8]),z_ani(i,[6 8]), '-', 'color','r', 'linewidth',2)
    
    drawnow
end
