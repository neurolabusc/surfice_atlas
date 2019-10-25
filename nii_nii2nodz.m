function nii_nii2nodz(fnm)
%convert NIfTI atlas to BrainNet node format
% fnm : indexed NIfTI atlas
%BrainNet node format is a text file
%X Y Z Color Size Name
%-9.631	28.620	33.320	1	1	L.superior.frontal.gyrus

if isempty(which('nii_coord2spheres'))
    error('Please get spmScripts from GitHub and add to your path'); 
end
if isempty(which('spm'))
    error('Please get spm and add to your path'); 
end
if ~exist('fnm','var') %atlas not specified
    [file,path] = uigetfile('*.nii;*.nii.gz');
    if isnumeric(file), return; end
    fnm = fullfile(path,file);
end
[p,n,x] = spm_fileparts(fnm);
fnm = fullfile(p,[n,x]); %remove volume
if ~exist(fnm, 'file')
    error('Unable to find volume %s', fnm);
end
%read image
hdr = spm_vol(fnm);
img = spm_read_vols(hdr);
nROI = max(img(:));
%read table
txt = fullfile(p,[n,'.txt']);
if ~exist(txt, 'file')
    %you can optionally supply a text file to set the size of each node
    warning('Guessing Region Names: unable to find "%s"', txt);
    fid = fopen( txt, 'wt' );
    for i = 1:nROI
        fprintf( fid, '%d\tRegion%d\n', 1, i); %all nodes have size "1"
    end
    fclose(fid);
end
%see https://www.mathworks.com/help/matlab/ref/matlab.io.text.delimitedtextimportoptions.html
varNames = {'Idx','Name'} ;
varTypes = {'int32','char'} ;
delimiter = {'|','\t'};
dataStartLine = 1;
extraColRule = 'ignore';
opts = delimitedTextImportOptions('VariableNames',varNames,...
                            'VariableTypes',varTypes,...
                            'Delimiter',delimiter,...
                            'DataLines', dataStartLine,...
                            'ExtraColumnsRule',extraColRule);                  
T = readtable(txt,opts);
%check table
if nROI ~= numel(T.Idx) 
   error('Image has %d regions, but text file has %d (update code for sparse representations)\n', nROI, numel(T.Idx)); 
end
%find center of mass for each region
node = fullfile(p,[n,'.node']);
fid = fopen(node,'w');
for i = 1 : nROI
    imgi = (img == i)+ 0;
    if max(imgi(:)) < 1
        continue; %no voxels in this region - todo sparse
    end
    sumTotal = sum(imgi(:));
    coivox = ones(4,1);
    coivox(1) = sum(sum(sum(imgi,3),2)'.*(1:size(imgi,1)))/sumTotal; %dimension 1
    coivox(2) = sum(sum(sum(imgi,3),1).*(1:size(imgi,2)))/sumTotal; %dimension 2
    coivox(3) = sum(squeeze(sum(sum(imgi,2),1))'.*(1:size(imgi,3)))/sumTotal; %dimension 3
    XYZ_mm = hdr.mat * coivox; %convert from voxels to millimeters
    fprintf(fid,'%g\t%g\t%g\t1\t1\t%s\n',XYZ_mm(1), XYZ_mm(2), XYZ_mm(3), T.Name{i});
end
fclose(fid);
fprintf('Created %s\n', node);

