function [trainPR, testPR]=htkTrainTest(htkParam, printOpt)


if nargin<1, htkParam=htkParamSet; end
if nargin<2, printOpt=0; end

if printOpt, fprintf('I.1: Generate output directories\n'); end
[s,mess,messid]=mkdir('output');
[s,mess,messid]=mkdir('output/feature');
[s,mess,messid]=mkdir('output/hmm');

if printOpt, fprintf('I.2: Generate %s and %s\n', htkParam.mnlFile, htkParam.phoneMlfFile); end
fid=fopen('output\syl2phone.scp', 'w'); fprintf(fid, 'EX'); fclose(fid);
cmd=sprintf('HLEd -n output\\%s -d %s -l * -i output\\%s output\\syl2phone.scp %s', htkParam.mnlFile, htkParam.pamFile, htkParam.phoneMlfFile, htkParam.sylMlfFile);
dos(cmd);

if printOpt, fprintf('I.3: Generate wav2fea.scp'); end
tic;
waveFiles=recursiveFileList(htkParam.waveDir, 'wav');
outFile='output\wav2fea.scp';
fid=fopen(outFile, 'w');
for i=1:length(waveFiles)
	wavePath=strrep(waveFiles(i).path, '/', '\');
	[a,b,c]=fileparts(wavePath);
	fprintf(fid, '%s\t%s\r\n', wavePath, ['output\feature\', b, '.fea']);
end
fclose(fid);
%fprintf('%f sec\n', toc);
waveNum=length(waveFiles);
testWaveNum=round(waveNum/5);
trainWaveNum=waveNum-testWaveNum;

if printOpt, fprintf('I.4: Use HCopy.exe for acoustic feature extraction\n'); end
tic;
cmd=sprintf('HCopy -C %s -S output\\wav2fea.scp', htkParam.feaCfgFile);
dos(cmd);
%fprintf('%f sec\n', toc);

if printOpt, fprintf('II.1: Generate file listing for training and test sets in trainFea.scp and testFea.scp, respectively.\n'); end
tic;
outFile='output\trainFea.scp';
fid=fopen(outFile, 'w');
for i=1:trainWaveNum
	wavePath=strrep(waveFiles(i).path, '/', '\');
	[a,b,c]=fileparts(wavePath);
	fprintf(fid, '%s\r\n', ['output\feature\', b, '.fea']);
end
fclose(fid);
outFile='output\testFea.scp';
fid=fopen(outFile, 'w');
for i=(trainWaveNum+1):length(waveFiles)
	wavePath=strrep(waveFiles(i).path, '/', '\');
	[a,b,c]=fileparts(wavePath);
	fprintf(fid, '%s\r\n', ['output\feature\', b, '.fea']);
end
fclose(fid);
%fprintf('%f sec\n', toc);

if printOpt, fprintf('II.2: Generate HMM template file template.hmm\n'); end
outFile='output\template.hmm';
mixtureNum=[1];		% Set to 1 for now, will be modified later
genTemplateHmmFile(htkParam.feaType, htkParam.feaDim, htkParam.stateNum, outFile, mixtureNum, htkParam.streamWidth);

if printOpt, fprintf('II.3: Populate template.hmm to generate hcompv.hmm\n'); end
cmd=sprintf('HCompV -m -o hcompv.hmm -M output -I output\\%s -S output\\trainFea.scp output\\template.hmm', htkParam.phoneMlfFile);
dos(cmd);

if printOpt, fprintf('II.4: Duplidate hcompv.hmm to generate macro.init'); end
tic;
% Read modelName.txt
modelListFile=sprintf('output\\%s', htkParam.mnlFile);;
models = textread(modelListFile,'%s','delimiter','\n','whitespace','');
% Read hcompv.hmm
hmmFile='output\hcompv.hmm';
fid=fopen(hmmFile, 'r');
contents=fread(fid, inf, 'char');
contents=char(contents');
fclose(fid);
% Write macro.init
outFile='output\macro.init';
fid=fopen(outFile, 'w');
source='~h "hcompv.hmm"';
for i=1:length(models)
	target=sprintf('~h "%s"', models{i});
	x=strrep(contents, source, target);
	fprintf(fid, '%s', x);
end
fclose(fid);
%fprintf('%f sec\n', toc);

if printOpt, fprintf('II.5: Create more Gaussian components to generate macro.0\n'); end
fid=fopen('output\mxup.scp', 'w'); fprintf(fid, 'MU %d {*.state[2-4].mix}', htkParam.mixtureNum); fclose(fid);
copyfile('output/macro.init', 'output/hmm/macro.0');
cmd=sprintf('HHEd -H output\\hmm\\macro.0 output\\mxup.scp output\\%s', htkParam.mnlFile);
dos(cmd);

if printOpt, fprintf('II.6: Generate macro.1~macro.5 via EM\n'); end
emCount=5;
for i=1:emCount
	sourceMacro=['output\hmm\macro.', int2str(i-1)];
	targetMacro=['output\hmm\macro.', int2str(i)];
	fprintf('%d/%d: Generate %s...\n', i, emCount, targetMacro);
	copyfile(sourceMacro, targetMacro);
	cmd=sprintf('HERest -H %s -I output\\%s -S output\\trainFea.scp output\\%s', targetMacro, htkParam.phoneMlfFile, htkParam.mnlFile);
	dos(cmd);
end

if printOpt, fprintf('III.1: Use grammar file to generate net file\n'); end
cmd=sprintf('Hparse %s output\\digit.net', htkParam.grammarFile);
dos(cmd);

if printOpt, fprintf('III.2: Recognition rates for inside/outside tests\n'); end
if printOpt, fprintf('\tOutside test: Generating result_test.mlf\n'); end
cmd=sprintf('HVite -H %s -l * -i output\\result_test.mlf -w output\\digit.net -S output\\testFea.scp %s output\\%s', targetMacro, htkParam.pamFile, htkParam.mnlFile);
dos(cmd);
if printOpt, fprintf('\tInside test: Generating result_train.mlf\n'); end
cmd=sprintf('HVite -H %s -l * -i output\\result_train.mlf -w output\\digit.net -S output\\trainFea.scp %s output\\%s', targetMacro, htkParam.pamFile, htkParam.mnlFile);
dos(cmd);

if printOpt, fprintf('III.3: Generate confusion matrices for inside/outside tests\n'); end
if printOpt, fprintf('\tGenerate Confusion matrix of outside test\n'); end
dos(sprintf('findstr /v "sil" %s > output\\answer.mlf', htkParam.sylMlfFile));
dos('findstr /v "sil" output\\result_test.mlf > output\\result_test_no_sil.mlf');
[status, result]=dos(sprintf('HResults -p -I output\\answer.mlf %s output\\result_test_no_sil.mlf > output\\outsideTest.txt', htkParam.pamFile));
contents=fileread('output\outsideTest.txt');
keyStr='WORD: %Corr=';
startIndex=strfind(contents, keyStr)+length(keyStr);
testPR=eval(contents(startIndex:startIndex+4));

if printOpt, fprintf('\tGenerate Confusion matrix of inside test\n'); end
dos('findstr /v "sil" output\\result_train.mlf > output\\result_train_no_sil.mlf');
[status, result]=dos(sprintf('HResults -p -I output\\answer.mlf %s output\\result_train_no_sil.mlf > output\\insideTest.txt', htkParam.pamFile));
contents=fileread('output\insideTest.txt');
keyStr='WORD: %Corr=';
startIndex=strfind(contents, keyStr)+length(keyStr);
trainPR=eval(contents(startIndex:startIndex+4));