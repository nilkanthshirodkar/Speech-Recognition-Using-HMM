function genTemplateHmmFile(feaType, feaDim, stateNum, outFile, mixtureNum, streamWidth)
% getTemplateHum: Get a template HMM parameter for HTK training
%	Usage: genTemplateHmmFilegenTemplateHmmFile(feaType, feaDim, stateNum, outFile, mixtureNum, streamWidth)
%		feaType: feature type for HTK, for example, 'MFCC_E', 'MFCC_E_D_A', etc
%		feaDim: dimension of the feature vector
%		stateNum: no. of states in a model
%		outFile: output file
%		mixtureNum: a vector of no. of mixtures in a state (the length is equal to no. of streams)
%		streamWidth: a vector of dim. of a stream (the length is equal to no. of streams)

%	Type "genTemplateHmmFile" for a demo.

%	Roger Jang, 20060519

if nargin<1, selfdemo; return; end
if nargin<2
	switch(feaType)
		case {'MFCC_E', 'MFCC_E_Z'}
			feaDim=13;
		case {'MFCC_E_D', 'MFCC_E_D_Z'}
			feaDim=26;
		case {'MFCC_E_D_A', 'MFCC_E_D_A_Z'}
			feaDim=39;
		default
			error('The given feaType is not supported!');
	end
end
if nargin<3, stateNum=1; end
if nargin<4, outFile=tempname; end
if nargin<5, mixtureNum=1; end
streamNum=length(mixtureNum);
if nargin<6, streamWidth=feaDim*ones(1, streamNum); end

if streamNum~=length(streamWidth)
	error('streamNum is not equal to length(streamWidth)!');
end
if feaDim~=sum(streamWidth)
	error('feaDim is not equal to sum(streamWidth)!');
end

fid=fopen(outFile, 'w');
fprintf(fid, '~o <VecSize> %d <%s> <StreamInfo> %d ', feaDim, feaType, streamNum);
for i=1:streamNum
	fprintf(fid, '%d ', streamWidth(i));
end
fprintf(fid, '\r\n');

fprintf(fid, '<BeginHMM>\r\n');
fprintf(fid, '<NUMSTATES> %d\r\n', stateNum+2);
for stateId=2:stateNum+1
	fprintf(fid, '<STATE> %d', stateId);
	fprintf(fid, '<NUMMIXES> ');	% <NUMMIXES> x x x

	for streamId=1:streamNum
		fprintf(fid, '%d ', mixtureNum(streamId));
	end
	fprintf(fid, '\r\n');

	for streamId=1:streamNum
		fprintf(fid, '<STREAM> %d\r\n', streamId);	% <STREAM>
		avgMixtureWeight=1/mixtureNum(streamId);
		for mixtureId=1:mixtureNum(streamId)		% <MIXTURE>
			fprintf(fid, '<MIXTURE> %d %e\r\n', mixtureId, avgMixtureWeight);
			fprintf(fid, '<MEAN> %d\r\n', streamWidth(streamId));	% <MEAN> dimensionSize
			for mx=1:streamWidth(streamId)
				fprintf(fid, '0.0 ');
			end
			fprintf(fid, '\r\n');
			fprintf(fid, '<VARIANCE> %d\r\n', streamWidth(streamId));	% <VARIANCE> dimensionSize
			for mx=1:streamWidth(streamId)
				fprintf(fid, '1.0 ');
			end
			fprintf(fid, '\r\n');
		end
	end
end

fprintf(fid, '<TRANSP> %d\r\n', stateNum+2);	% <TRANSP> stateNum
transProb=zeros(stateNum+2, stateNum+2);
for i=2:stateNum+1
	for j=2:stateNum+2
		if i==j
			transProb(i,j)=0.6;
		elseif i+1==j
			transProb(i,j)=0.4;
		end
	end
end
transProb(1,2)=1.0;

for i=1:stateNum+2
	for j=1:stateNum+2
		fprintf(fid, '%e ', transProb(i,j));
	end
	fprintf(fid, '\r\n');
end
fprintf(fid, '<ENDHMM>\r\n');
fclose(fid);

% ====== Self demo
function selfdemo
stateNum=3;
feaType='MFCC_E_D_A';
feaDim=39;
stateNum=3;
outFile=[tempname, '.txt'];
mixtureNum=[6, 2, 2];
streamWidth=[13, 13, 13];
feval(mfilename, feaType, feaDim, stateNum, outFile, mixtureNum, streamWidth);
dos(['start ', outFile]);