function [tprAtWP,auc,fpr,tpr] = fastROC(labels,scores,plot_flag, plotStyle)
% function [tprAtWP,auc,fpr,tpr] = fastROC(labels,scores,plot_flag)
%
% This function calculates m AUC values for m ranked lists.
% n is the number of ranked items. 
% m is the number of different rankings.
%
% Input:  labels is nXm binary logical.
%         scores is nXm real. For a high AUC the higher scores should have
%         labels==1.
%         plot_flag: binary flag, if TRUE then m ROC curves will be plotted
%         (default FALSE).
%
% Output: tprAtWP is a real number, the true positive rate average between
%                 10^-3 and 10^-3 FPR in log scale
%         auc is mX1 real, the Area Under the ROC curves.
%         fpr is nXm real, the false positive rates.
%         tpr is nXm real, the true positive rates.

if ~exist('plot_flag','var')
    plot_flag = 0;
end

if ~exist('plotStyle','var')
    plotStyle = 'b';
end

if ~islogical(labels)
    error('labels input should be logical');
end

if (size(labels,2) ~= 1) | (size(scores,2) ~= 1)
    error('labels and scores must be one-dimensional vectors');
end

if ~isequal(size(labels),size(scores))
    error('labels and scores should have the same size');
end
[n,m] = size(labels);
num_pos = sum(labels);
if any(num_pos==0)
    error('no positive labels entered');
end
if any(num_pos==n)
    error('no negative labels entered');
end

[~,scores_si] = sort(scores,'descend');
clear scores
scores_si_reindex = scores_si+ones(n,1)*(0:m-1)*n;
l = labels(scores_si_reindex);
clear scores_si labels 

tp = cumsum(l==1,1);
fp = repmat((1:n)',[1 m])-tp;

num_neg = n-num_pos;
fpr = bsxfun(@rdivide,fp,num_neg); %False Positive Rate
tpr = bsxfun(@rdivide,tp,num_pos); %True Positive Rate

fprintf('trp and frp is %f %f\n', tpr, fpr)

%Plot the ROC curve
if plot_flag==1
    semilogx(fpr,tpr,plotStyle,'LineWidth',2);
    xlabel('False Positive Rate');
    ylabel('True Positive Rate');
end

auc = sum(tpr.*[(diff(fp)==1); zeros(1,m)])./num_neg;

% average TPR between 10^-3 and 10^-2
startAvg = 10^-3;
endAvg = 10^-2;

logFPR = log10(fpr + eps/100);
intervalIdxs = find( (logFPR > log10(startAvg)) & (logFPR < log10(endAvg)));

logVals = logFPR(intervalIdxs);

% fix for some pathological cases
if intervalIdxs(1) >= 2
    intervalIdxs = [intervalIdxs(1)-1; intervalIdxs];
    logVals = [log10(startAvg); logVals];
end

if intervalIdxs(end) < length(logFPR)
    intervalIdxs = [intervalIdxs; intervalIdxs(end)+1];
    logVals = [logVals; log10(endAvg)];
end

tprAtWP = trapz(logVals , tpr(intervalIdxs) ) ;
if plot_flag==1
    %title(sprintf('TPR @ Working Point = %.2f', tprAtWP));
end
