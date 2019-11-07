//Romain Guiet @BIOP, EPFL
// 05.06.2014
// To detect a Staining
// use Color deconvolution and on one of the specified channel aplly a  a specified threshold
//
// To detect Tissue
// convert image to HSB , and on one of the specified channel aplly a  a specified threshold
//
// handle ROIs measurements
// since  2017.08.17 can restrict area for threshold using roi named "LimitedTo"

// Install the BIOP Library
call("BIOP_LibInstaller.installLibrary", "BIOP"+File.separator+"BIOPLib.ijm");

// Name ActionBar
bar_name = "BIOP IHC RatioQuanti";

bar_file = replace(bar_name, " ", "_")+".ijm";
bar_jar  = replace(bar_name, " ", "_")+".jar";


runFrom = "jar:file:BIOP/"+bar_jar+"!/"+bar_file;
//////////////////////////////////////////////////////////////////////////////////////////////
// The line below is for debugging. Place this VSI file in the ActionBar folder within Plugins
//////////////////////////////////////////////////////////////////////////////////////////////
//runFrom = "/plugins/ActionBar/Debug/"+bar_file;

if(isOpen(bar_name)) {
	run("Close AB", bar_name);
}

run("Action Bar",runFrom);
exit();

<codeLibrary>

function toolName() {
	return "Ratio Quantification";
}


function detectionSettings(){
	// Then the user will have to specify the thresholds required	
	listThreshold = getList("threshold.methods");						// get the list of threshold available
	vectors = newArray("H&E", "H&E 2","H DAB", "Feulgen Light Green", "Giemsa", "FastRed FastBlue DAB", "Methyl Green DAB", "H&E DAB", "H AEC","Azan-Mallory","Alcian blue & H","H PAS","RGB","CMY");
	
	vectorColorDeconvolution 		= getDataD("vectorColorDeconvolution", vectors[0]);
	channelFromColorDeconvolution 	= getDataD("channelFromColorDeconvolution", 2);
	thresholdForStaining 			= getDataD("thresholdForStaining", listThreshold[0]);
	gbStaining						= getDataD("GaussianBlurStaining ", gbStaining);
	hsbChannel 						= getDataD("hsbChannel", 2);
	thresholdForTissue 				= getDataD("thresholdForTissue", listThreshold[0]);
	gbTissue						= getDataD("GaussianBlurTissue ", gbTissue);
	
	Dialog.create("Specify Settings")									// create a dialog
	Dialog.addMessage("Select a threshold for detection of ");
	Dialog.addChoice("Colour Deconvolution vector:", vectors,vectorColorDeconvolution);			// Colour Deconvolution Vector 
	Dialog.addNumber("Colour Deconvoluted channel", channelFromColorDeconvolution);					// Colour Deconvolution Vector 
	Dialog.addChoice("Threshold for Staining", listThreshold,thresholdForStaining);		// Threshold for Staining
	Dialog.addNumber("Gaussian Blur on staining", gbStaining);	
	
	Dialog.addMessage("");
	
	Dialog.addMessage("Detect Tissue, using HSB method: ");
	Dialog.addNumber(" HSB channel for tissue detection", hsbChannel);
	Dialog.addChoice("Threshold for Tissue", listThreshold,thresholdForTissue);			// Threshold for Tissue
	Dialog.addNumber("Gaussian Blur on tissue", gbTissue);
	Dialog.show() ;
	
	vectorColorDeconvolution 		= Dialog.getChoice();				//  get the Vector for ColorDeconvolution 
	channelFromColorDeconvolution	= Dialog.getNumber();				//  and the image to use from it
	thresholdForStaining 			= Dialog.getChoice();				//  get the selected Threshold for Staining
	gbStaining						= Dialog.getNumber();
	hsbChannel						= Dialog.getNumber();
	thresholdForTissue				= Dialog.getChoice();				//  get the selected Threshold for Tissue
	gbTissue						= Dialog.getNumber();
	
	setData("vectorColorDeconvolution",vectorColorDeconvolution);
	setData("channelFromColorDeconvolution",channelFromColorDeconvolution);
	setData("thresholdForStaining",thresholdForStaining);
	setData("GaussianBlurStaining ", gbStaining);
	setData("hsbChannel",hsbChannel);
	setData("thresholdForTissue",thresholdForTissue);
	setData("GaussianBlurTissue ", gbTissue);
	
	savingDir		= getSaveFolder();
	paramWindowName = toolName();
	selectWindow(paramWindowName);
	saveAs("text", savingDir+paramWindowName+".txt");	
}

function processImage(testMode){
	
	totalRoiNumber = roiManager("Count");
	
	run("Set Measurements...", "area limit display redirect=None decimal=3");// set measurement

	vectorColorDeconvolution 		= getData("vectorColorDeconvolution");
	channelFromColorDeconvolution 	= getData("channelFromColorDeconvolution");
	thresholdForStaining 			= getData("thresholdForStaining");
	hsbChannel 						= getData("hsbChannel");
	thresholdForTissue 				= getData("thresholdForTissue");
	savingDir						= getSaveFolder();
	gbStaining						= getData("GaussianBlurStaining ");
	gbTissue						= getData("GaussianBlurTissue ");
	
	oriImage = getTitle();										// get the image title	
	getVoxelSize(width, height, depth, unit);					// and infos
	run("Select None");

	indexOfLimitedTo = findRoiWithName("LimitedTo");
	limitROIbeforeThreshold = false;
	if (indexOfLimitedTo >= 0){
		limitROIbeforeThreshold = true;
	}
		
		////////////////////////////////////////////////////////////////////////////// Staining detection
		run("Select All");
		run("Colour Deconvolution", "vectors=["+vectorColorDeconvolution+"]");
		selectWindow(oriImage+"-(Colour_"+channelFromColorDeconvolution+")");
		setVoxelSize(width, height, depth, unit);
		rename(oriImage+"_Staining");
		
		if (gbStaining>0){
			run("Gaussian Blur...", "sigma="+gbStaining);
		}	

		if (limitROIbeforeThreshold) roiManager("Select",indexOfLimitedTo);
		setAutoThreshold(thresholdForStaining); 

		if (testMode){
			run("Threshold...");
			waitForUser("Please Select a Threshold\nPress OK");
		}
		
		if (totalRoiNumber>0) {
			for (roiIndex = 0 ; roiIndex < totalRoiNumber ; roiIndex++ ){		
				if (roiIndex != indexOfLimitedTo){
					roiManager("Select",roiIndex);
					run("Measure");
				}
			}
		}else{
			run("Measure");
		}
		
		run("Convert to Mask");
		stainingArea = getResult("Area", (nResults-1));
		
		//////////////////////////////////////////////////////////////////////////////  Tissue detection
		selectWindow(oriImage);
		run("Select All");
		run("Duplicate...", "title="+oriImage+"_HSB");
		run("HSB Stack");
		selectImage(nImages);
		Stack.setChannel(hsbChannel);
		run("Duplicate...", "title="+oriImage+"_Tissue");
		setVoxelSize(width, height, depth, unit);
		rename(oriImage+"_Tissue");
		
		if (gbTissue>0){
			run("Gaussian Blur...", "sigma="+gbTissue);
		}

		if (limitROIbeforeThreshold) roiManager("Select",indexOfLimitedTo);	
		if(hsbChannel == 2){
			setAutoThreshold(thresholdForTissue+" dark");
		}else{
			setAutoThreshold(thresholdForTissue);		
		}

		if (testMode){
			run("Threshold...");
			waitForUser("Please Select a Threshold\nPress OK");
		}

		if (totalRoiNumber>0) {
			for (roiIndex = 0 ; roiIndex < totalRoiNumber ; roiIndex++ ){		
				if (roiIndex != indexOfLimitedTo){
					roiManager("Select",roiIndex);
					run("Measure");
				}
			}
		}else{
			run("Measure");
		}
		
		
		run("Convert to Mask");
		tissueArea = getResult("Area", (nResults-1));

		///////////////////////////////////////////////////////////////////////////// Calculate Area Ratio and set it within the Table.
		//setResult("Area Ratio",(nResults-1),(stainingArea/tissueArea));
		
		//////////////////////////////////////////////////////////////////////////// create a merged image of the masks
		run("Merge Channels...", "c1=["+oriImage+"_Staining] c2=["+oriImage+"_Tissue] create keep");// red = staining, grey = tissue
		//waitForUser;
		Stack.setChannel(4);									// select the grey channel
		setMinAndMax(200, 455);									// decrease the B&C of the grey channel, so red channel is still visible
		run("RGB Color");										// flatten to a RGB (thus  the thumbail can be seen on Windows/Mac explorer)
		rename(oriImage+"_merge");
		
		if (!testMode){
			close("\\Others");
		}

		

		
		selectWindow("Results");								//select the result table
		updateResults() ;										// update it

}

function batchProcessImage(){
	savingDir = getSaveFolder();
	setBatchMode(true);
	// make ImageJ/Fiji clean 	
	roiManager("Reset");												// reset ROI manager
	if (isOpen("Results")){
		run("Clear Results");												// and the results table
	}
	if(nImages>0){
		run("Close All");
	}
	nI = getNumberImages();												// get the imagenumber

	for (imageIndex=0; imageIndex<nI; imageIndex++) {
		roiManager("reset");
		openImage(imageIndex);													// open the image and associated ROIset
		totalRoiNumber = roiManager("Count");
		
		processImage(false);
		saveCurrentImage();
		saveRois("Save");
		run("Close All");										//close every image
	}
	updateResults() ;// update it
	selectWindow("Results");
	saveAs("Results", savingDir+"Results.txt");						// and save it	
	setBatchMode(false);											// get out of the Batch mode
	showMessage("Jobs Done");										// pop up an "End Message"
}

//helper function
function isImage(filename) {
	extensions= newArray("lsm", "lei", "lif", "tif", "ics", "bmp", "jpg", "png", "TIF", "tiff");
	for (i=0; i<extensions.length; i++) {
		if(endsWith(filename, "."+extensions[i])) {
			return true;
		}
	}
	return false;
} 


</codeLibrary>

<text><html><font size=3 color=#0C2981> Select

<line>
<button>
label= Folder
icon=noicon
arg=<macro>
//Open the file and parse the data
openParamsIfNeeded();
setImageFolder("Select Working Folder");
getSaveFolder();
</macro>
</line>

<line>
<button>
label= Image
icon=noicon
arg=<macro>
selectImageDialog();
</macro>
</line>

<text><html><font size=3 color=#0C2981> Settings
<line>
<button>
label= Specify
icon=noicon
arg=<macro>
detectionSettings();
</macro>
</line>

<line>
<button>
label= Test on current image (test mode)
icon=noicon
arg=<macro>
processImage(true);
</macro>
</line>

</line>
<line>
<button>
label=Save 
arg=<macro>
saveParameters();
</macro>

<button>
label=Load 
arg=<macro>
loadParameters();
</macro>
</line>

<text><html><font size=3 color=#0C2981> Process
<line>
<button>
label= Current image
icon=noicon
arg=<macro>
processImage(false);
</macro>

<button>
label= Folder
icon=noicon
arg=<macro>
batchProcessImage();
</macro>
</line>

<text><html><font size=3 color=#0C2981> Help
<line>
<button>
label= Infos & Contact
icon=noicon
arg=<macro>
//biopUrl = "http://biop.epfl.ch/INFO_Facility.html#staff/";
biopUrl = "https://c4science.ch/w/bioimaging_and_optics_platform_biop/image-processing/imagej_tools/ijab-ihc-ratio/"
run("URL...", "url="+biopUrl);
</macro>
</line>

