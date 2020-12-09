function writeLut(fnm)
%Create an ImageJ format color lookup table
% The .lut file is 768 bytes
% This format specifies 256 colors
% Each color is a 3x8 byte color triplet (Red, Green, Blue)
%  In addition to ImageJ, you can use these color tables with MRIcron
%  MRIcron comes with default color schemes in its "lut" folder
%  https://www.nitrc.org/projects/mricron
%  https://imagej.net/Visualization.html#Pseudocolor_Image_Look-Up_Tables_.28LUTs.29
%  https://people.cas.sc.edu/rorden/mricro/lutmaker/index.html
%  https://imagej.nih.gov/ij/plugins/index.html
%  https://imagejdocu.tudor.lu/gui/image/lookup_tables
%  https://imagej.nih.gov/ij/download/luts/
if ~exist('fnm', 'var')
    fnm = 'mylut';
end
lut = floor(rand(256,3)*(256-eps));
lut = uint8(lut);
% %optional: define colors
% for i = 1 : 256
%    lut(i,1) = i-1; %red component
%    lut(i,2) = 256-i; %green component
%    lut(i,3) = 0; %green component
% end
%save binary
[p,n] = fileparts(fnm);
fid = fopen(fullfile(p,[n,'.lut']),'wb');
fwrite(fid,lut,'uchar');
fclose(fid);