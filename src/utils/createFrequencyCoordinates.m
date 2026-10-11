% membuat koordinat frekuensi 2D terpusat dan matriks jarak radial
function [U, V, D] = createFrequencyCoordinates(rows, cols)
    validateattributes(rows, {'numeric'}, ...
        {'scalar', 'real', 'finite', 'integer', 'positive'});
    validateattributes(cols, {'numeric'}, ...
        {'scalar', 'real', 'finite', 'integer', 'positive'});

    u = (1:cols) - (floor(cols / 2) + 1);
    v = (1:rows) - (floor(rows / 2) + 1);

    [U, V] = meshgrid(u, v);
    D = hypot(U, V);
end
