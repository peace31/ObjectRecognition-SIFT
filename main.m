clear;
close all;
clc;
%% camera
cam=webcam;
%cam.Resolution = '99x99';
img=snapshot(cam);
figure;
imshow(img);
%% Initialise variables and image database
run('vlfeat\toolbox\vl_setup')
EquationString = '';
imgDB{1} = imread('database/divide.jpg');
imgDB{2} = imread('database/equal.jpg');
imgDB{3} = imread('database/minus.jpg');
imgDB{4} = imread('database/multiply.jpg');
imgDB{5} = imread('database/plus.jpg');
imgDB{6} = imread('database/1.jpg');
imgDB{7} = imread('database/2.jpg');
imgDB{8} = imread('database/3.jpg');
imgDB{9} = imread('database/4.jpg');
imgDB{10} = imread('database/5.jpg');
imgDB{11} = imread('database/6.jpg');
imgDB{12} = imread('database/7.jpg');
imgDB{13} = imread('database/8.jpg');
imgDB{14} = imread('database/9.jpg');

QuestionImage=imread('test/22.jpg');


%% Read question and split the digits
QuestionImage = imcomplement(QuestionImage)
bw = im2bw(QuestionImage);      % Convert to Binary image.

buffersize = 100;               % Add a small vertical buffer.
se = strel('line',buffersize,90);
bwopen = imopen(bw,se);

D = watershed(bwopen);          % Segmentation of the question.
number = D;

for i = 1:max(unique(D));       % Store the images into EachDigit.
    letter = uint8(bw);
    letter(D~=i)=2;
    boundcol = find(max(letter==0,[],1));
    boundrow = find(max(letter==0,[],2));
    EachDigit{i} = bw(boundrow(1):boundrow(end),boundcol(1):boundcol(end));
end


%% Compare the database digit
% Thresh for SIFT features
peakThresh = 5; edgeThresh=15;

% To compare the EachDigit with the images in database.
for m = 1:max(unique(number));
    % Load the EachDigit image and grayscale
    imgGray2 = 255 * uint8(EachDigit{m});
    [height2, width2, channels2] = size(imgGray2);
    imgGray2 = padarray(imgGray2, [round(((100-height2)/2),0) round(((100-width2)/2),0)], 255, 'both');
    imgGray2 = imresize(imgGray2,[100 100]);
    if mod(m,2) == 0 
        se = strel('square', 5);
        imgGray2 = imerode(imgGray2, se);
    end
    % make single the images and extract the SIFT features
    [f2, d2] = vl_sift(single(imgGray2), 'PeakThresh', peakThresh, 'EdgeThresh', edgeThresh);
    Features2.f = f2;
    Features2.d = d2;
    
    if mod(m,2) == 0 
        starting=1;
        ending=5;
        for ii=6:14
            field.ransac = 0;
            result{ii} = field;
        end
    else
        for ii=1:5
            field.ransac = 0;
            result{ii} = field;
        end
        starting=6;
        ending=14;
    end
    
    % Load the images from database
    for loop=starting:ending
        % Convert to binary and then convert back to grayscale
        img1 = im2bw(imgDB{loop});
        img1 = 255 * uint8(img1);
        imgGray{loop} = imcomplement(img1);
        if mod(m,2) == 0 
            se = strel('square', 8);
            imgGray{loop} = imclose(imgGray{loop}, se);
        end
        [height1, width1, channels1] = size(imgGray{loop});
        % make single the images and extract the SIFT features
        [f1, d1] = vl_sift(single(imgGray{loop}), 'PeakThresh', peakThresh, 'EdgeThresh', edgeThresh);
        Features1.f = f1;
        Features1.d = d1;
        
        result{loop} = sift_match(imgGray2,imgGray{loop}, Features2, Features1);
    end

    % Get the column of highest value in the cell (ratiotest)
    Highest = cell2mat(result);
    [value,index] = max([Highest.ransac]);
    if value == 0
        index = 15;
    end
    
    % Recognise according the column of the cell.
    switch index
        case 1
            EquationString = [EquationString, ' ', '/'];
        case 2
            EquationString = [EquationString, '', '']; % equal no need
        case 3
            EquationString = [EquationString, ' ', '-'];
        case 4
            EquationString = [EquationString, ' ', '*'];
        case 5
            EquationString = [EquationString, ' ', '+'];
        case 6
            EquationString = [EquationString, ' ', '1'];
        case 7
            EquationString = [EquationString, ' ', '2'];
        case 8
            EquationString = [EquationString, ' ', '3'];
        case 9
            EquationString = [EquationString, ' ', '4'];
        case 10
            EquationString = [EquationString, ' ', '5'];
        case 11
            EquationString = [EquationString, ' ', '6'];
        case 12
            EquationString = [EquationString, ' ', '7'];
        case 13
            EquationString = [EquationString, ' ', '8'];
        case 14
            EquationString = [EquationString, ' ', '9'];
        case 15
            EquationString = [EquationString, ' ', '?'];
    end
end

%% Perform the answering follow the string of the equation
Question = EquationString;
Question

%Question = '1*3+8/2-4';

%Answer = eval(Question);    % Convert the string to executable code and perform calculation.
%Answer