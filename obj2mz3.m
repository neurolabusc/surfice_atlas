function obj2mz3 (prefix, nROI, lutname, deleteInputs)
%Create an mz3 format atlas from a series of mz3 meshes
%Example
% obj2mz3('l',16)

if ~exist('prefix','var'), error('Please run nii_nii2atlas'); end;
outname = [prefix, 'merge.mz3'];

if exist('lutname', 'var') && ~isempty(lutname)
  lut = getVertexColorSubImageJ(lutname);  
else
    lut = getVertexColorSub;
end
%n = numel(objs);
fMerge = [];%face
vMerge = [];%vertex
cMerge = [];%color
for i = 1 : nROI %numel(objs)
   %fnm = objs{i};
   fnm = sprintf('%so%04d.mz3',prefix, i);
   if ~exist(fnm,'file')
         warning('Unable to find %s\n', fnm);
         continue;
   end
   %fprintf('%d %s\n', i, fnm);
   %[f,v] = fileUtils.obj.readObj(fnm);
   [f, v] = readMz3(fnm);
   if exist('deleteInputs','var') && deleteInputs,  delete(fnm); end;
   if numel(vMerge) > 0
    f = f + max(fMerge(:));%numel(vMerge) - 1;
   end;
   fMerge = [fMerge; f];
   vMerge = [vMerge; v];
     
    
   i255 = i;
   if i > 255
     i255 =  mod(i,255);
     if i255 == 0
        i255 = 1;
        warning('More than 255 regions');
     end
   end
   %fprintf('%d RGBA = %g %g %g %g\n', i, lut(i255,1), lut(i255,2), lut(i255,3), lut(i255,4));
   fprintf('%d RGBA = %g %g %g %g\n', i, 255*lut(i255,1), 255*lut(i255,2), 255*lut(i255,3), 255*lut(i255,4));
   
   c = repmat(lut(i255,:),size(v,1),1);
   cMerge = [cMerge; c];
end
fprintf('Merged %d meshes with %d faces and %d vertices %s\n',  nROI, size(fMerge,1), size(vMerge,1), outname );
cMerge = [cMerge, round(255*cMerge(:,4))]; %add 5th column as index
writeMz3(outname, fMerge, vMerge, cMerge);
%end obj2mz3()

function lut = getVertexColorSubImageJ(fnm)
%read ImageJ format color lookup table
if ~exist(fnm)
   error('Unable to find %s\n', fnm);
end
fileID = fopen(fnm);
lut = fread(fileID);
fclose(fileID);
lut = reshape(lut,256,3);
lut(1,:) = [];
lut = [lut, [1:255]']; %RGB->RGBA with A set to index
lut = lut/255;
%end getVertexColorSubImageJ()

function lut = getVertexColorSub()
lut = [71,46,154;
48,112,58;
192,199,10;
32,79,207;
195,89,204;
208,41,164;
173,208,231;
233,135,136;
202,20,58;
25,154,239;
210,35,30;
145,21,147;
89,43,230;
87,230,101;
245,113,111;
246,191,150;
38,147,35;
3,208,128;
50,74,114;
57,28,252;
167,27,79;
245,86,173;
86,203,120;
227,25,25;
208,209,126;
81,148,81;
64,187,85;
90,139,8;
199,111,7;
140,48,122;
48,102,237;
212,76,190;
180,110,152;
70,106,246;
120,130,182;
9,37,130;
192,160,219;
245,34,67;
177,222,76;
65,90,167;
157,165,178;
9,245,235;
193,222,250;
100,102,28;
181,47,61;
125,19,186;
145,130,250;
62,4,199;
8,232,67;
108,137,58;
36,211,50;
140,240,86;
237,11,182;
242,140,108;
248,21,77;
161,42,89;
189,22,112;
41,241,59;
114,61,125;
65,99,226;
121,115,50;
97,199,205;
50,166,227;
238,114,125;
149,190,128;
44,204,104;
214,60,27;
124,233,59;
167,66,66;
40,115,53;
167,230,133;
127,125,159;
178,103,203;
231,203,97;
30,125,125;
173,13,139;
244,176,159;
193,94,158;
203,131,7;
204,39,215;
238,198,47;
139,167,140;
135,124,226;
71,67,223;
234,175,231;
234,254,44;
217,1,110;
66,15,184;
14,198,61;
129,62,233;
19,237,47;
97,159,67;
165,31,148;
112,218,22;
244,58,120;
35,244,173;
73,47,156;
192,61,117;
12,67,181;
149,94,94];
%for i = 1 : 1
%    lut(i,:) = [0,0,0];
%end
if true %e.g. 1/2 3/4 have same colors 
    lut100 = lut;
    for i = 1 : 100 
        lut(i,:) = lut100(ceil(i / 2),:);
    end
end
lut = [lut; lut; lut(1:55,:)]; %make 255 values: repeat 1..100, 1..100, 1..55
lut = [lut, [1:255]'];; %RGB->RGBA with A set to index
lut = lut/255;
%end getVertexColorSub()
