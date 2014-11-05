function result = MLP_block(model,inputs,targets)

% ----------------------------------------------------------------------------
% DESCRIPTION
%	this script does most of the work for training an MLP. 
%	it creates a result struct containing accuracy over blocks

% INPUT ARGUMENTS:
% 	model is a struct that is assumed to contain:
% 		model.numblocks = 16; % number of passes through the training set
% 		model.numinitials = 50; % number of randomized initalizations
% 		model.weightrange = .5; % range of inital weight values
% 		model.numhiddenunits = 2; % # hidden units
% 		model.learningrate = .15; % learning rate for gradient descent
% ----------------------------------------------------------------------------

%   these are optional editables, currently set at default values
	hiddenactrule = 'sigmoid'; % options: 'sigmoid', 'tanh'
	outputactrule = 'sigmoid'; % options: 'linear', 'sigmoid', 'tanh'
	weightcenter=0; % mean value of weights
% ----------------------------------------------------------------------------

result=struct; %initialize the results structure
v2struct(model) %unpack input params

% initializing some useful variables
numattributes = size(inputs,2);
numtargets = size(targets,2);

training=zeros(numblocks,numinitials);

%   Initializing diva and running the simulation
%   ------------------------------------------------------ % 
for modelnumber = 1:numinitials
    
    %  generating initial weights
    [inweights,outweights] = getweights(numattributes, numhiddenunits, ...
		numtargets, weightrange, weightcenter);
    
    %   iterate over each trial in the presentation order
    %   ------------------------------------------------------ % 
	for blocknumber = 1:numblocks
       
% 		pass activations through model
        [outputactivations,hiddenactivation,hiddenactivation_raw,inputswithbias] = ...
			FORWARDPASS(inweights,outweights,inputs,hiddenactrule,outputactrule);

% 		determine classification accuracy
		[~,indecies] = max(targets,[],2);
		accuracy = diag(outputactivations(:,indecies)) ./ sum(outputactivations,2);
        training(blocknumber,modelnumber)=mean(accuracy);
		
        %   Back-propagating the activations
        %   ------------------------------------------------------ % 
        
        %  obtain error on the output units
        outputderivative = 2*(outputactivations - targets);
        
        %  obtain error on the hidden units
		hiddenderivative=outputderivative*outweights';
        if strcmp(hiddenactrule,'sigmoid') % applying sigmoid;
			hiddenderivative=hiddenderivative(:,2:end).*sigmoidgrad(hiddenactivation_raw);
        elseif strcmp(hiddenactrule,'tanh') %applying tanh
			hiddenderivative=hiddenderivative(:,2:end).*tanhgrad(hiddenactivation_raw);
        end

        %  gradient descent
		outweights = gradientDescent(learningrate,hiddenactivation,...
			outputderivative,outweights);
		inweights = gradientDescent(learningrate,inputswithbias,...
			hiddenderivative,inweights);    
	end
end

% store perfomance in the result struct
result.training=training;
end
