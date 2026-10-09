% membuat grid jarak frekuensi dengan titik pusat di tengah
function H = createFrequencyGrid(rows, cols)
    validateattributes(rows, {'numeric'}, ...
        {'scalar', 'real', 'finite', 'integer', 'positive'});
    validateattributes(cols, {'numeric'}, ...
        {'scalar', 'real', 'finite', 'integer', 'positive'});

    u = (1:cols) - (floor(cols / 2) + 1);
    v = (1:rows) - (floor(rows / 2) + 1);

    [U, V] = meshgrid(u, v);
    H = hypot(U, V);
end