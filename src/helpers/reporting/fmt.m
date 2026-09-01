function s = fmt(x, type)
switch type
    case 'eur'
        s = sprintf('%14s', addcommas(round(x)));
    case 'eur4'
        s = sprintf('%+14.4f', x);
end
end

function s = addcommas(n)
s = fliplr(regexprep(fliplr(num2str(abs(n))), '(\d{3})(?=\d)', '$1,'));
if n < 0; s = ['-' s]; else; s = ['+' s]; end
end
