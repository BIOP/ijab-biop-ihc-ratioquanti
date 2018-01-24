@ECHO OFF

ECHO Copying BIOP_IHC_RatioQuanti.ijm to current folder
copy C:\Fiji\plugins\ActionBar\Debug\BIOP_IHC_RatioQuanti.ijm

ECHO Creating JAR FILE
jar cf BIOP_IHC_RatioQuanti.jar plugins.config icons *.ijm

ECHO Copying BIOP_IHC_RatioQuanti.ijm to Fiji folder
copy *.jar C:\Fiji\plugins\BIOP

PAUSE