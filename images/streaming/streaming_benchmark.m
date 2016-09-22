function [] = streaming_benchmark()
        
    %% create sample data
    img = loadSampleImage();
    img = img + uint8(rand(size(img)) * 64);
    jpeg = encodeJpeg_matlab(img);
    imshow(img);
    
    benchmark = @(name, f) ...
        fprintf('%s: \t %3.3f ms\n', name, timeit(f,1) * 1000); 
    
    %% test decoders
    f = @() decodeJpeg_matlab(jpeg);
    benchmark('decodeJpeg_matlab', f);
    
    f = @() decodeJpeg_java(jpeg);
    benchmark('decodeJpeg_java', f);
    
    %% test java conversion
    rnd480p = {480 640 3};
    
    list = java.util.ArrayList();
    list.add(uint8(rand(rnd480p{:})*255));
    f = @() getFirstElement_Java(list);
    benchmark('java 480p (3d)', f);

    list = java.util.ArrayList();
    list.add(uint8(rand(480*640*3,1)*255));
    f = @() getFirstElement_Java(list);
    benchmark('java 480p (1d)', f);

    list = java.util.ArrayList();
    list.add(uint8(rand(720,1280,3)*255));
    f = @() getFirstElement_Java(list);
    benchmark('java 720p (3d)', f);
    
    list = java.util.ArrayList();
    list.add(uint8(rand(720*1280*3,1)*255));
    f = @() getFirstElement_Java(list);
    benchmark('java 720p (1d)', f);
    
end

%% Utilities
function img = loadSampleImage()
    img = imread('fabric.png');
end

function jpeg = encodeJpeg_matlab(img)
    % write image as jpeg file
    tmpFile = 'tmp.jpg';
    imwrite(img, tmpFile, 'Quality', 100, 'BitDepth' , 8);
    fid = fopen(tmpFile, 'r+');
    
    % read raw data stream
    jpeg = fread(fid, inf, 'uint8=>uint8')';
    fclose(fid);
    delete(tmpFile);
end

%% JPEG decoding
function img = decodeJpeg_matlab(jpeg)
    % write raw data stream
    tmpFile = fullfile('tmp.jpg');
    fid = fopen(tmpFile,'w+');
    fwrite(fid, typecast(jpeg, 'uint8'), 'uint8');
    fclose(fid);

    % read image from file
    img = imread(tmpFile);
    delete(tmpFile);
end

function img = decodeJpeg_java(jpeg)

    % convert to java image
    inputStream = java.io.ByteArrayInputStream(jpeg);
    imgJava = javax.imageio.ImageIO.read(inputStream);
    
    % convert image bytes to matlab format
    w = getWidth(imgJava);
    h = getHeight(imgJava);
    components = getNumComponents(getColorModel(imgJava));
    
    % reshape 1 dimensional java array to matrix
    pixels = reshape( ...
        typecast(getDataStorage(getData(imgJava)), 'uint8'), ... % Type
        components, w, h );  % Size
        
    
    % reshape from row major to column major format
    % RGB Images
    if(components == 3)
        img = cat(3, ...
            transpose(reshape(pixels(3, :, :), w, h)), ...
            transpose(reshape(pixels(2, :, :), w, h)), ...
            transpose(reshape(pixels(1, :, :), w, h)));
        return;
        
    % Grayscale Images
    elseif (components == 1)
        img = transpose(reshape(pixels(1, :, :), w, h));
        return;
    end
    
end

function data = getFirstElement_Java(list)
    data = get(list, 0);
end




