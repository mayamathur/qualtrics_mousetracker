//define functions specific to "Real" question block

	//define function to issue alerts to subject (all alerts are issued after answer button is clicked because data can still be used as long as we don't interrupt question with alerts before it is answered)
	//to avoid confusing subjects, latencyTooLong alert is only issued if there was no latencyTooShort alert (both things can happen if subject moves mouse before page loads then also waits too long to move again after page loads, but they would see both "started too early" and "started too late" which could drive them crazy.
	//for each question, a record of issued alerts is constructed by saving numbers that correspond to every alert that was issued, to a string. If no alerts were issued, zero is saved.
	function issueAlerts()
	{ //beginning of issueAlerts
	
		//be sure to forget that a latencyTooShort alert might have been issued for the previous question
		latencyTooShortAlert = false
	
		if ( latencyTooShort == true )
			{
			alert ( " \n\n                        STARTED TOO EARLY\n\nYou moved the cursor off the Next button before the question was fully displayed." )
			alerts.push( "1" )
			//remember that this alert was issued
			latencyTooShortAlert = true
			}
		
		if ( latencyTooLong == true )
			{
				//only give a too-long alert if there was not a too-short alert, so as not to confuse the subject
				if ( latencyTooShortAlert == false )
					{
					alert (  " \n\n                        STARTED TOO LATE\n\nYou waited a little too long to start moving the cursor.\n\nTo speed up your answer, try to start moving the cursor sooner, even if you are not yet fully decided about your final answer." )
					}
				alerts.push( "2" )
			}
		
		if ( answerElapsedTime[imageNumber] > maxAnswerTime )
			{
			answerTimeTooLong = true
			alert ( "You took longer than the "+(maxAnswerTime/1000)+"-second total time limit to click an answer." )
			alerts.push( "3" )
			}
		
		if ( windowTooSmall == true )
			{
			alert ( "Your browser window is too small.\n\nPlease make it larger.")
			alerts.push( "4" )
			}
			
		//questions that got no alerts should have a zero in their alerts array
		if ( (latencyTooShort == false) && (latencyTooLong == false) && (answerTimeTooLong == false) && (windowTooSmall == false) )
			{alerts.push( "0" )}
				
		//prepare the alerts array for embedded data by appending a letter "a" (the separator) at the end of the set of alert values saved for each image
			{alerts.push( "a" )}

				
	}//end of issueAlerts

	//the following function writes zeroes in an array (used to initialize arrays after practice trials are done)
	function zeroArray(arrayName)
		{var index
		for (index = 0; index < howManyRealImages; index += 1) {arrayName[index] = 0} }



Qualtrics.SurveyEngine.addOnload(function()
{//begin addOnload function
	
	//advance imageNumber by one
	imageNumber += 1
	
	//reset Booleans to default values at beginning of every stimulus trial
	checkedStartPosition = false
	didLatency = false
	latencyTooLong = false
	latencyTooShort = false
	windowTooSmall = false
	answerButtonClicked = false
	answerTimeTooLong = false
	wait = false	//we don't want the getMousePosition function to miss the first mouse move

	if ( ( imageNumber == howManyPracticeImages ) && (isItPractice == true) )
	{ //beginning of first Real question block
		//this is everything that must be done just before the first Real question happens
		
		//reset imageNumber to 0 so that experimental data is stored in correct positions in arrays
		imageNumber = 0
		isItPractice = false
		
		//because these arrays use the push method to save values, they must be emptied so that push starts adding to the array at position 0 (other variables are only recorded once-per-question and so they use imageNumber (not push) to save to the correct position.
		xPos = []
		yPos = []
		time = []
		alerts = []
		//But we'll reset the non-pushed arrays, anyhow, just to be safe, and write zeroes in the locations that will be filled. Because, if some error were to cause a value to not be saved for a question, if there were no value in that position the Qualtrics Embedded Variables would just have fewer values than howManyRealImages, but we would not know which question was missing data. This was needed during code development, but is reatained here as a safeguard against unanticipated missing-data errors during the experiment.
		readyTime = [];			zeroArray(readyTime)
		loadTime = [];			zeroArray(loadTime)
		firstMoveTime = [];		zeroArray(firstMoveTime)
		firstMoveLatency = [];	zeroArray(firstMoveLatency)
		answerElapsedTime = [];	zeroArray(answerElapsedTime)
		answerClickTime = [];	zeroArray(answerClickTime)
		windowHeight = [];		zeroArray(windowHeight)
		windowWidth = [];		zeroArray(windowWidth)
		
		//must move info about Next button position from the last Practice Question into the correct array position for first Real Question
		nextButtonLeft[0] = nextButtonLeft[ (howManyPracticeImages) ]
		nextButtonRight[0] = nextButtonRight[ (howManyPracticeImages) ]
		nextButtonTop[0] = nextButtonTop[ (howManyPracticeImages) ]
		nextButtonBottom[0] = nextButtonBottom[ (howManyPracticeImages) ]
	}//end of first Real Question block
	
	//loadTime is recorded so that, by comparing it to readyTime, we can get an idea of the subjects connection speed. It would be ideal to do this first in the addOnLoad function (to get an accurate time), but the loadTime array and imageNumber haven't been prepared yet at that point
	loadTime[imageNumber] = ( Date.now() )
	
	//save the URL of the image in the array that records their randomized Loop & Merge order
	imageOrder[imageNumber] = "${lm://Field/1}"
	
	//turn on mousetracking - has to be done now instead of being triggered by first move because otherwise first move wouldn't be recorded
	document.addEventListener("mousemove", getMousePosition)

});//end of addOnload function



Qualtrics.SurveyEngine.addOnReady(function()
//everything in this function is executed as soon as each question page is done loading. Although Qualtrics states that this function is "executed when the page is fully displayed," this is definitely not true; it is executed before the image is displayed. Therefore, because onReadyTime is recorded before the image is displayed, subjects with slow internet connections will have firstMoveLatency and answerReactionTime significantly longer than the true values; they will receive spurious and confusing "Started too late" alerts. 
{//begin: addOnReady function

	//To prevent subjects from moving to the next page without answering the question, we disable the Next button -- the button will be enabled again after an answer button is clicked. Qualtrics' own forced-response option cannot be used because their alert shifts the Next button to a lower position on the page, which ruins the mouse start position for the subsequent question.
    this.disableNextButton()

	//now is the start time for firstMoveLatency and answerReactionTime calculation, so record it before doing anything else
	readyTime[imageNumber] = ( Date.now() )

	//turn on eventlistener so that the firstMove function is now waiting to be triggered by the first mouse move after onReadyTime
	document.addEventListener("mousemove", firstMove)
		
	//when an answer button is clicked, record data about the time it took to answer, and issue delayed alerts to give subject feedback about any problems with their speed or mouse movement
	this.questionclick = function(event,element)
	{//begin: questionclick block
		if (element.type == 'radio')
		{//begin: "if radio button" block
			//turn off mousetracking as soon as answer button is clicked (this is not supported by Internet Explorer 8.0 and earlier)
			document.removeEventListener("mousemove", getMousePosition)
			
			//record the absolute time answer button was clicked
			answerClickTime[imageNumber] = ( Date.now() )
			
			//because an answer button was clicked, Next button will now be re-enabled so subject can move to the next question
			this.enableNextButton()
			//get and record Next button location (to determine valid starting location for the next question
			currentNextButtonRect = document.getElementById("NextButton").getBoundingClientRect()
			nextButtonLeft[ (imageNumber + 1) ] = Math.round(currentNextButtonRect.left)
			nextButtonRight[ (imageNumber + 1) ] = Math.round(currentNextButtonRect.right)
			nextButtonTop[ (imageNumber + 1) ] = Math.round(currentNextButtonRect.top)
			nextButtonBottom[ (imageNumber + 1) ] = Math.round(currentNextButtonRect.bottom)
			
			// calculate and record the total time it took to answer following display of image
			answerElapsedTime[imageNumber] = ( answerClickTime[imageNumber] - readyTime[imageNumber] )
			
			//get and record window dimensions
			windowWidth[imageNumber] = (window.innerWidth)
			windowHeight[imageNumber] = (window.innerHeight)
			// determine if window is too small
			if  ( (window.innerWidth < minWindowWidth) || (window.innerHeight < minWindowHeight) ) {windowTooSmall = true}
			
			// evoke function to issue alerts to the subject, after a delay to allow answer button to change color so subject isn't confused
			setTimeout ( issueAlerts, 25 )

		}//end: "if radio button" block
	}//end: questionclick block
});// end: addOnReady function



Qualtrics.SurveyEngine.addOnPageSubmit(function(type)
//everything in this function is executed when Next button is clicked
{// begin addOnPageSubmit function

	if ( (type == "next") && (imageNumber == (howManyRealImages - 1) ) )
	{//beginning: if last question-submitted
		//last question is being submitted, so save all the embedded data for this subject
				
		//Javascript variables for this question are converted to strings with the "a" character inserted between values and are added to the Qualtrics embedded data arrays with the same names
		Qualtrics.SurveyEngine.setEmbeddedData("xPos", xPos.join("a"))
		Qualtrics.SurveyEngine.setEmbeddedData("yPos", yPos.join("a"))
		Qualtrics.SurveyEngine.setEmbeddedData("time", time.join("a"))
		console.log("readyTime array for image #: "+ imageNumber +": "+readyTime.join("a")) //This seems to have to be here for the following data to be saved???!!!
		Qualtrics.SurveyEngine.setEmbeddedData("onReadyTime", readyTime.join("a"))
		Qualtrics.SurveyEngine.setEmbeddedData("onLoadTime", loadTime.join("a"))
		Qualtrics.SurveyEngine.setEmbeddedData("buttonClickTime", answerClickTime.join("a"))
		Qualtrics.SurveyEngine.setEmbeddedData("windowWidth", windowWidth.join("a"))
		Qualtrics.SurveyEngine.setEmbeddedData("windowHeight", windowHeight.join("a"))
		Qualtrics.SurveyEngine.setEmbeddedData("latency", firstMoveLatency.join("a"))
		Qualtrics.SurveyEngine.setEmbeddedData("answerReactionTime", answerElapsedTime.join("a"))
		Qualtrics.SurveyEngine.setEmbeddedData("stimulusOrder", imageOrder.join("|"))
				
		// for the alerts string, we only want a single "a" separator between each set of alerts for each image, so don't add any more here
		Qualtrics.SurveyEngine.setEmbeddedData("alerts", alerts.join(""))

	} // end: if Next button block
}); //end: addOnPageSubmit function