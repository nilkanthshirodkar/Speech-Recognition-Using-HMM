htkParam=htkParamSet;
htkParam.feaCfgFile='mfcc26.cfg';
htkParam.feaType='MFCC_E_D_Z';
htkParam.feaDim=26;
htkParam.streamWidth=[26];

maxMixNum=8;
for i=1:maxMixNum
	htkParam.mixtureNum=i;
	fprintf('====== %d/%d\n', i, maxMixNum);
	[trainPR(i), testPR(i)]=htkTrainTest(htkParam);
end

plot(1:maxMixNum, testPR, 'o-');

%plot(1:maxMixNum, trainRR, 'o-', 1:maxMixNum, testRR, 'o-');
%xlabel('No. of mixtures'); ylabel('Recog. rate (%)');
%legend('Inside test', 'Outside test');