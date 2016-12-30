htkParam=htkParamSet;
htkParam.feaCfgFile='mfcc39.cfg';
htkParam.feaType='MFCC_E_D_A_Z';
htkParam.feaDim=39;
htkParam.streamWidth=[39];

maxMixNum=8;
for i=1:maxMixNum
	htkParam.mixtureNum=i;
	fprintf('====== %d/%d\n', i, maxMixNum);
	[trainPR(i), testPR(i)]=htkTrainTest(htkParam);
end

plot(1:maxMixNum, testPR, 'o-');
xlabel('No. of mixtures'); ylabel('Recog. rate (%)');
legend('Inside test', 'Outside test');