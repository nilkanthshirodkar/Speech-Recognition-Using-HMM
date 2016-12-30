htkParam=htkParamSet;
maxMixNum=8;

htkPara.feaCfgFile='mfcc13.cfg';
htkPara.feaType='MFCC_E';
htkPara.feaDim=13;
htkPara.streamWidth=[13];
for i=1:maxMixNum
	htkParam.mixtureNum=i;
	fprintf('====== %d/%d\n', i, maxMixNum);
	[testPR(i)]=Anath(htkParam);
end


plot(1:maxMixNum, testPR, 'o-');
xlabel('No. of mixtures'); ylabel('Recog. rate (%)');



