mkdir('output');
mkdir('output/feature');
mkdir('output/hmm');

fid=fopen('output\syl2phone.scp', 'w'); fprintf(fid, 'EX'); fclose(fid);

cmd='HLEd -n output\digitSyl.mnl -d digitSyl.pam -l * -i output\digitSylPhone.mlf output\syl2phone.scp digitSyl.mlf';
dos(cmd);

wavDir='..\waveFile';
waveFiles=recursiveFileList(wavDir, 'wav');
outFile='output\wav2fea.scp';
fid=fopen(outFile, 'w');
for i=1:length(waveFiles)
	wavePath=strrep(waveFiles(i).path, '/', '\');
	[a,b,c]=fileparts(wavePath);
	fprintf(fid, '%s\t%s\r\n', wavePath, ['output\feature\', b, '.fea']);
end
fclose(fid);

cmd='HCopy -C mfcc39.cfg -S output\wav2fea.scp';
dos(cmd);

%outFile='output\trainFea.scp';
%fid=fopen(outFile, 'w');
%for i=1:400
%	wavePath=strrep(waveFiles(i).path, '/', '\');
%	[a,b,c]=fileparts(wavePath);
%	fprintf(fid, '%s\r\n', ['output\feature\', b, '.fea']);
%end
%fclose(fid);
%outFile='output\testFea.scp';
%fid=fopen(outFile, 'w');
%for i=401:length(waveFiles)
%	wavePath=strrep(waveFiles(i).path, '/', '\');
%	[a,b,c]=fileparts(wavePath);
%	fprintf(fid, '%s\r\n', ['output\feature\', b, '.fea']);
%end
%fclose(fid);

cmd='outMacro.exe P D 3 1 MFCC_E_D_A_Z 39 > output\template.hmm';
dos(cmd);

feaType='MFCC_E_D_A_Z';
feaDim=39;
outFile='output\template.hmm';
stateNum=3;
mixtureNum=[1];
streamWidth=[39];
genTemplateHmmFile(feaType, feaDim, stateNum, outFile, mixtureNum, streamWidth);


cmd='HCompV -m -o hcompv.hmm -M output -I output\digitSylPhone.mlf -S output\trainFea.scp output\template.hmm';
dos(cmd);

% Read digitSyl.mnl
modelListFile='output\digitSyl.mnl';
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


fid=fopen('output\mxup.scp', 'w'); fprintf(fid, 'MU 3 {*.state[2-4].mix}'); fclose(fid);
copyfile('output/macro.init', 'output/hmm/macro.0');
cmd='HHEd -H output\hmm\macro.0 output\mxup.scp output\digitSyl.mnl';
dos(cmd);



emCount=5;
for i=1:emCount
	sourceMacro=['output\hmm\macro.', int2str(i-1)];
	targetMacro=['output\hmm\macro.', int2str(i)];
	fprintf('%d/%d: %s...\n', i, emCount, targetMacro);
	copyfile(sourceMacro, targetMacro);
	cmd=sprintf('HERest -H %s -I output\\digitSylPhone.mlf -S output\\trainFea.scp output\\digitSyl.mnl', targetMacro);
	dos(cmd);
end



cmd='Hparse digit.grammar output\digit.net';
dos(cmd);


%cmd='HVite -H output\hmm\macro.5 -l * -i output\result_train.mlf -w output\digit.net -S output\trainFea.scp digitSyl.pam output\digitSyl.mnl';
%dos(cmd);



%cmd='findstr /v "sil" output\result_train.mlf > output\result_train_no_sil.mlf';
%dos(cmd);

%cmd='findstr /v "sil" digitSyl.mlf > output\answer.mlf';
%dos(cmd);

%cmd='HResults -p -I output\answer.mlf digitSyl.pam output\result_train_no_sil.mlf > output\insideTest8.txt';
%dos(cmd);

%type output\insideTest8.txt





cmd='HVite -H output\hmm\macro.5 -l * -i output\result_test.mlf -w output\digit.net -S output\testFea.scp digitSyl.pam output\digitSyl.mnl';
dos(cmd);

cmd='findstr /v "sil" output\result_test.mlf > output\result_test_no_sil.mlf';
dos(cmd);

cmd='findstr /v "sil" digitSyl.mlf > output\answer.mlf';
dos(cmd);

cmd='HResults -p -I output\answer.mlf digitSyl.pam output\result_test_no_sil.mlf > output\outsideTest9.txt';
dos(cmd);


type output\outsideTest9.txt


