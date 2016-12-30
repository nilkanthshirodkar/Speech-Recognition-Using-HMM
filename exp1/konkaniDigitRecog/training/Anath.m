function [testPR]=Anath(htkParam)

htkParam=htkParamSet;

[s,mess,messid]=mkdir('output');
[s,mess,messid]=mkdir('output/feature');
[s,mess,messid]=mkdir('output/hmm');

fid=fopen('output\syl2phone.scp', 'w'); fprintf(fid, 'EX'); fclose(fid);
cmd=sprintf('HLEd -n output\\%s -d %s -l * -i output\\%s output\\syl2phone.scp %s', htkParam.mnlFile, htkParam.pamFile, htkParam.phoneMlfFile, htkParam.sylMlfFile);
dos(cmd);

fid=fopen('output\syl2phone.scp', 'w'); fprintf(fid, 'EX'); fclose(fid);
cmd=sprintf('HLEd -n output\\%s -d %s -l * -i output\\%s output\\syl2phone.scp %s', htkParam.mnlFile, htkParam.pamFile, htkParam.phoneMlfFile, htkParam.sylMlfFile);
dos(cmd);

waveFiles=recursiveFileList(htkParam.waveDir, 'wav');
outFile='output\wav2fea.scp';
fid=fopen(outFile, 'w');
for i=1:length(waveFiles)
	wavePath=strrep(waveFiles(i).path, '/', '\');
	[a,b,c]=fileparts(wavePath);
	fprintf(fid, '%s\t%s\r\n', wavePath, ['output\feature\', b, '.fea']);
end
fclose(fid);

waveNum=length(waveFiles);
testWaveNum=round(waveNum/5);
trainWaveNum=waveNum-testWaveNum;

cmd=sprintf('HCopy -C %s -S output\\wav2fea.scp', htkParam.feaCfgFile);
dos(cmd);


%outFile='output\trainFea.scp';
%fid=fopen(outFile, 'w');
%for i=1:trainWaveNum
%	wavePath=strrep(waveFiles(i).path, '/', '\');
%	[a,b,c]=fileparts(wavePath);
%	fprintf(fid, '%s\r\n', ['output\feature\', b, '.fea']);
%end
%fclose(fid);

%outFile='output\testFea.scp';
%fid=fopen(outFile, 'w');
%for i=(trainWaveNum+1):length(waveFiles)
%	wavePath=strrep(waveFiles(i).path, '/', '\');
%	[a,b,c]=fileparts(wavePath);
%	fprintf(fid, '%s\r\n', ['output\feature\', b, '.fea']);
%end
%fclose(fid);


outFile='output\template.hmm';
mixtureNum=[i];
%genTemplateHmmFile(htkParam.feaType, htkParam.feaDim, htkParam.stateNum, outFile, mixtureNum, htkParam.streamWidth);

cmd=sprintf('HCompV -m -o hcompv.hmm -M output -I output\\%s -S output\\trainFea.scp output\\template.hmm', htkParam.phoneMlfFile);
dos(cmd);


modelListFile=sprintf('output\\%s', htkParam.mnlFile);;
models = textread(modelListFile,'%s','delimiter','\n','whitespace','');


hmmFile='output\hcompv.hmm';
fid=fopen(hmmFile, 'r');
contents=fread(fid, inf, 'char');
contents=char(contents');
fclose(fid);


outFile='output\macro.init';
fid=fopen(outFile, 'w');
source='~h "hcompv.hmm"';
for i=1:length(models)
	target=sprintf('~h "%s"', models{i});
	x=strrep(contents, source, target);
	fprintf(fid, '%s', x);
end

fid=fopen('output\mxup.scp', 'w'); fprintf(fid, 'MU 3 {*.state[2-4].mix}', htkParam.mixtureNum); fclose(fid);

copyfile('output/macro.init', 'output/hmm/macro.0');

cmd=sprintf('HHEd -H output\\hmm\\macro.0 output\\mxup.scp output\\%s', htkParam.mnlFile);
dos(cmd);

emCount=5;
for i=1:emCount
	sourceMacro=['output\hmm\macro.', int2str(i-1)];
	targetMacro=['output\hmm\macro.', int2str(i)];
	fprintf('%d/%d: Generate %s...\n', i, emCount, targetMacro);
	copyfile(sourceMacro, targetMacro);
	cmd=sprintf('HERest -H %s -I output\\%s -S output\\trainFea.scp output\\%s', targetMacro, htkParam.phoneMlfFile, htkParam.mnlFile);
	dos(cmd);
end


cmd=sprintf('Hparse %s output\\digit.net', htkParam.grammarFile);
dos(cmd);
cmd=sprintf('HVite -H %s -l * -i output\\result_test.mlf -w output\\digit.net -S output\\testFea.scp %s output\\%s', targetMacro, htkParam.pamFile, htkParam.mnlFile);
dos(cmd);
cmd=sprintf('HVite -H %s -l * -i output\\result_train.mlf -w output\\digit.net -S output\\trainFea.scp %s output\\%s', targetMacro, htkParam.pamFile, htkParam.mnlFile);
dos(cmd);
dos(sprintf('findstr /v "sil" %s > output\\answer.mlf', htkParam.sylMlfFile));
dos('findstr /v "sil" output\\result_test.mlf > output\\result_test_no_sil.mlf');
[status, result]=dos(sprintf('HResults -p -I output\\answer.mlf %s output\\result_test_no_sil.mlf > output\\outsideTest22.txt', htkParam.pamFile));
contents=fileread('output\outsideTest22.txt');
keyStr='WORD: %Corr=';
startIndex=strfind(contents, keyStr)+length(keyStr);

testPR=eval(contents(startIndex:startIndex+4));






