clearvars;

% -- GETTING STARTED WITH THE PERSON DETECTION DATASET -- %
% IMPORTANT: Make sure you downloaded Piotr's toolbox: http://vision.ucsd.edu/~pdollar/toolbox/doc/
%            and add it to the path with
%            addpath(genpath('where/the/toolbox/is'))
%
%    And make sure you downloaded the train_feats.mat and train_imgs.mat
%    files we provided you with.

% add path to piotr's toolbox

% ---------------------------------------------
% ====>   FIX TO YOUR ACTUAL TOOLBOX PATH <====
% ---------------------------------------------
addpath(genpath('../toolbox/'));

% Load both features and training images
load train_feats;
load train_imgs;

%% --browse through the images, and show the feature visualization beside
%  -- You should explore the features for the positive and negative
%  examples and understand how they resemble the original image.
for i=1:10
    clf();
    
    subplot(121);
    imshow(imgs{i}); % image itself
    
    subplot(122);
    im( hogDraw(feats{i}) ); colormap gray;
    axis off; colorbar off;
    
    pause;  % wait for keydo that then,??
end

%% -- Generate feature vectors (so each one is a row of X)
fprintf('Generating feature vectors..\n');
D = numel(feats{1});  % feature dimensionality
X = zeros([length(imgs) D]);

for i=1:length(imgs)
    X(i,:) = feats{i}(:);  % convert to a vector of D dimensions
end

%% -- Example: split half and half into train/test
fprintf('Splitting into train/test..\n');
% NOTE: you should do this randomly! and k-fold!
Tr.idxs = 1:2:size(X,1);
Tr.X = X(Tr.idxs,:);
Tr.y = labels(Tr.idxs);

Te.idxs = 2:2:size(X,1);
Te.X = X(Te.idxs,:);
Te.y = labels(Te.idxs);

%%
fprintf('Training simple neural network..\n');

%--- WARNING --
% You need to download the Deep Learning Toolbox and add it to your path
% You can get it from https://github.com/rasmusbergpalm/DeepLearnToolbox/archive/master.zip
addpath(genpath('where/the/deeplearningtoolboxis/'));

% --- NOTE ---
% Using this toolbox requires that you understand very well neural networks
% and that you go through the examples in their README file (github).
% You may also need to get into the toolbox code to be able to experiment
% with it.
%
% Make sure you understand what is going on below!

rng(8339);  % fix seed, this    NN is very sensitive to initialization

% setup NN. The first layer needs to have number of features neurons,
%  and the last layer the number of classes (here two).
nn = nnsetup([size(Tr.X,2) 10 2]);
opts.numepochs =  50;   %  Number of full sweeps through data
opts.batchsize = 100;  %  Take a mean gradient step over this many samples

% if == 1 => plots trainin error as the NN is trained
opts.plot               = 1; 

nn.learningRate = 2;

% this neural network implementation requires number of samples to be a
% multiple of batchsize, so we remove some for this to be true.
numSampToUse = opts.batchsize * floor( size(Tr.X) / opts.batchsize);
Tr.X = Tr.X(1:numSampToUse,:);
Tr.y = Tr.y(1:numSampToUse);

% normalize data
[Tr.normX, mu, sigma] = zscore(Tr.X); % train, get mu and std

% prepare labels for NN
LL = [1*(Tr.y>0)  1*(Tr.y<0)];  % first column, p(y=1)
                                   % second column, p(y=-1)

[nn, L] = nntrain(nn, Tr.normX, LL, opts);


Te.normX = normalize(Te.X, mu, sigma);  % normalize test data

% to get the scores we need to do nnff (feed-forward)
%  see for example nnpredict().
% (This is a weird thing of this toolbox)
nn.testing = 1;
nn = nnff(nn, Te.normX, zeros(size(Te.normX,1), nn.size(end)));
nn.testing = 0;

% predict on the test set
nnPred = nn.a{end};

% we want a single score, subtract the output sigmoids
nnPred = nnPred(:,1) - nnPred(:,2);

%% See prediction performance
fprintf('Plotting performance..\n');
% let's also see how random predicition does
randPred = rand(size(Te.y));

% and plot all together, and get the performance of each
methodNames = {'Neural Network', 'Random'}; % this is to show it in the legend
avgTPRList = evaluateMultipleMethods( Te.y > 0, [nnPred,randPred], true, methodNames );

% now you can see that the performance of each method
% is in avgTPRList. You can see that random is doing very bad.
avgTPRList

%% visualize samples and their predictions (test set)
figure;
for i=20:30  % just 10 of them, though there are thousands
    clf();
    
    subplot(121);
    imshow(imgs{Te.idxs(i)}); % image itself
    
    subplot(122);
    im( hogDraw(feats{Te.idxs(i)}) ); colormap gray;
    axis off; colorbar off;
    
    % show if it is classified as pos or neg, and true label
    title(sprintf('Label: %d, Pred: %d', labels(Te.idxs(i)), 2*(nnPred(i)>0) - 1));
    
    pause;  % wait for keydo that then,??
end
