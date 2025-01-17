function [list_spectra, commonMasses] = parse_waters_imaging_txt(fn)
% Parser for the text file generated by Waters' HDI software.
% Author: Paolo Inglese, Imperial College London 2017 <pi514@ic.ac.uk>

fid = fopen(fn);
C = textscan(fid, '%f', 'delimiter', '\t');
fclose(fid);
C = cell2mat(C);

numElements = length(C);

% Start from the last NAN
currIdx = find(isnan(C), 1, 'last') + 1;

numCommonMasses = C(currIdx - 4); % Remove 3 NANs

% Extract the common masses
startMassesIdx = currIdx;
endMassesIdx = currIdx + numCommonMasses - 1;
commonMasses = C(startMassesIdx:endMassesIdx);

% Sort masses
[commonMasses, sortIdx] = sort(commonMasses);

currIdx = endMassesIdx + 1;

k = 0;

while currIdx <= numElements
   
    k = k + 1;
    
    pixelIndex = C(currIdx);
    
    fprintf('pixel index: %d\n', pixelIndex);
    
    x = C(currIdx + 1);
    y = C(currIdx + 2);
    
    currIntensities = C(currIdx+3:currIdx+numCommonMasses+2);
    
    list_spectra{k} = struct('mz', 'intensity', 'x', 'y');
    list_spectra{k}.mz = commonMasses;
    list_spectra{k}.intensity = currIntensities(sortIdx);
    list_spectra{k}.x = x;
    list_spectra{k}.y = y;
    
    currIdx = currIdx + numCommonMasses + 5;
    
end

end