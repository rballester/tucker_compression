% Returns the side sizes of the minimal bounding box (with one corner placed at the hot corner) of the elements
% of the input (where zeros are considered empty space)

function R = bounding_box(core)
    proj1 = sum(sum(core,2),3);
    R1 = find(proj1);
    proj2 = sum(sum(core,1),3);
    R2 = find(proj2);
    proj3 = sum(sum(core,1),2);
    R3 = find(proj3);
    R = [R1(end) R2(end) R3(end)];
end