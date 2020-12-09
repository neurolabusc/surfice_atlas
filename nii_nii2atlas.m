function nii_nii2atlas(source, lutname)
%convert NIfTI atlas to MZ3 atlas
% source : indexed NIfTI atlas

%if isempty(which('fileUtils.obj.readObj')), error('Please install MRIcroS https://github.com/bonilhamusclab/MRIcroS'); end;
if ~exist('source','var') %atlas not specified
 [file,path] = uigetfile('*.nii;*.nii.gz', 'Select a NIfTI atlas');
 if isnumeric(file), return; end
 source = fullfile(path,file);
end
if ~exist(source, 'file')
    return;
end
if ~exist('lutname','var')
 [file,path] = uigetfile('*.lut', '(optional) select an ImageJ-format color table');
 lutname = fullfile(path,file);
end
if ~exist(lutname, 'file')
    fprintf('Using default color table\n');
end     
if isempty(which('spm'))
    error('Please get spm and add to your path'); 
end
if isempty(which('nii_reslice_target'))
    error('Please get spmScripts from GitHub and add to your path'); 
end

prefix = '';
reduce = 0.5;
interp = 4; %interpolation
isReverseFace = true;
target = '';%'mni.nii';
mask = ''; %mask ='mask.nii';
smoothVox = 2; %smoothVox = 2;
isResize = false;
thresh = 0.555;
%source code follows
[hdrS, imgS] = loadNiiSub(source);
if ~isempty(mask)
    [~, imgM] = loadNiiSub(mask);
    imgS(imgM ~= 0) = 0; 
end
if ~isempty(target)
    isResize = true;
    [hdrT, ~] = loadNiiSub(target);
end
imgS = uint16(imgS);
nROI = max(imgS(:));                                                                                                                                                                                                                                                                                                                                            
%nROI = 5;

fprintf('Converting %d regions of interest\n', nROI);
for i = 1 :  nROI
    imgI = (imgS == i);
    if (max(imgI(:)) == 0)
        continue;
    end
    imgI = double(imgI);
    if smoothVox > 0 %isSmooth
        presmooth = imgI+0; %+0 forces new matrix
        spm_smooth(presmooth,imgI,smoothVox,0); %smooth data
    end
    outnm = sprintf('%so%04d.mz3',prefix, i);
    if ~isResize
        img2meshSub(hdrS, imgI, outnm, reduce, thresh, isReverseFace)
        continue;
    end
    [~, outimg] = nii_reslice_target(hdrS, imgI, hdrT, interp);
    if smoothVox > 0 %isSmooth
        presmooth = outimg+0; %+0 forces new matrix
        spm_smooth(presmooth,outimg,smoothVox,0); %smooth data
    end  
    hdr = hdrS;
    hdr.pinfo = [1;0;0]; 
    img2meshSub(hdrT, outimg, outnm, reduce, thresh, isReverseFace)
end
obj2mz3(prefix, nROI, lutname, true);
%end nii_nii2atlas()

function img2meshSub(hdr, img, outnm, reduce, thresh, isReverse)
thresh = min(img(:)) + (thresh * max(img(:)) - min(img(:)));
if (max(img(:))< thresh) || (min(img(:)) > thresh) 
    if (min(img(:)) == max(img(:)) )
        warning('Range %g..%g No voxels survive for %s\n', min(img(:)), max(img(:)), outnm);
        return; 
    end
    thresh = min(img(:)) + (0.5 * max(img(:)) - min(img(:)));
    warning('Reseting threshold to %g for %s\n', thresh, outnm); 
end
FV = isosurface(img,thresh);
%FV = losslessCompressSub(FV);
r = reduce;
isManifold = true;
if size(FV.faces,1) < 160
    r = 1;
end
while (~isManifold) && (r < 1)
    nR = round(r * size(FV.faces,1));
    if nR < 160
       nR = 160; 
    end
    if mod(nR,2), nR = nR + 1; end
    FVr = reducepatch(FV,nR); %r
    isManifold = manifoldSub(FVr);
    if ~isManifold
       r = r + 0.025;
    end
end
if (r < 1) && exist('FVr','var')
    FV = FVr;
    %FV = losslessCompressSub(FV); %optional
end
FV.vertices = FV.vertices(:,[2,1,3]); %isosurface swaps X/Y
vx = [ FV.vertices ones(size(FV.vertices,1),1)];
vx = mtimes(hdr.mat,vx')';
FV.vertices = vx(:,1:3);
if exist('isReverse','var') && isReverse
    FV.faces = fliplr(FV.faces); %reverse winding
end
writeMz3(outnm, FV.faces, FV.vertices, [], [], false);
%end img2meshSub()

function FV = losslessCompressSub(FV);
innm = 'tmp.mz3';
writeMz3(innm, FV.faces, FV.vertices);
outnm = 'tmp.mz3';
system(sprintf('%s %s %s 1','./simplify', innm, outnm));
[FV.faces, FV.vertices] = readMz3(outnm);
%end losslessCompressSub()

function isManifold = manifoldSub(fv);
edges = sort(cat(1, fv.faces(:,1:2), fv.faces(:,2:3), fv.faces(:,[3 1])),2);
[unqEdges, ~, edgeNos] = unique(edges,'rows');
%fprintf('Check %d %d\n', size(edges,1), size(unqEdges,1))
%https://www.mathworks.com/matlabcentral/answers/27886-find-holes-and-gaps-in-stl-files
%http://www.alecjacobson.com/weblog/?tag=mesh-decimation
%  I?ve noticed that qslim and matlab will create non-manifold meshes from manifold inputs
if size(edges,1) == size(unqEdges,1)*2
    isManifold = true;
else
    isManifold = false;
end
%end manifoldSub()

function [hdr, img] = loadNiiSub(fnm)
hdr = spm_vol(fnm);
img = spm_read_vols(hdr);
%end loadNiiSub()

