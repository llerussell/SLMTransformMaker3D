function x = findClosestTwoPlanes(a,b)
% a - value
% b - array of values
% find closest two values of b to a

if any(b==a)
    lowest = find(b==a);
    sec_lowest = lowest;
else
    d = sort(abs(b-a));
    if (d(1) == d(2))
        vals = find(abs(b-a)==d(1));
        lowest = vals(1);
        second_lowest = vals(2);
    else
        lowest = find(abs(b-a)==d(1));
        sec_lowest = find(abs(b-a)==d(2));
    end
end

x = [lowest sec_lowest];
