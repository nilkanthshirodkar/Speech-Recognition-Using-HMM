function htkParam=htkParamSet

htkParam.pamFile='digitSyl.pam';
htkParam.feaCfgFile='mfcc13.cfg';
htkParam.waveDir='..\waveFile';
htkParam.sylMlfFile='digitSyl.mlf';
htkParam.phoneMlfFile='digitSylPhone.mlf';
htkParam.mnlFile='digitSyl.mnl';
htkParam.grammarFile='digit.grammar';
htkParam.feaType='MFCC_E';
htkParam.feaDim=13;
htkParam.mixtureNum=1;
htkParam.stateNum=8;
htkParam.streamWidth=[13];