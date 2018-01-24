@ECHO OFF

ECHO Copying Biop_VSI_reader.ijm to current folder
copy C:\Fiji\plugins\ActionBar\Debug\BIOP_IHC_RatioQuanti.ijm %~dp0

ECHO Creating JAR FILE
jar cf BIOP_IHC_RatioQuanti.jar plugins.config icons *.ijm

ECHO Copying Biop_VSI_reader.jar to Fiji folder
copy *.jar C:\Fiji\plugins\BIOP

PAUSE