//Variables and functions defined in this block of code, before addOnload, are available to all blocks of questions, not just this one, and any executable code is executed for every question.

//initialize variables and arrays (all times are in msec)
//any variable that will be saved as embedded data (using join) must be an array

	// bookkeeping variables
	if (typeof imageNumber == "undefined")			{var imageNumber = -1 } //records the ordinal number of the current question (numbering of images starts at 0, but this variable starts at -1 so that every question, including the first one, can begin by adding 1 to the value)
	if (typeof howManyPracticeImages == "undefined")	{var howManyPracticeImages = 6} //need to know how many practice questions there are so that imageNumber can be reset to cause the real question block to store data in properly in arrays, beginning at location 0
	if (typeof howManyRealImages == "undefined")		{var howManyRealImages = 10} //need to know how many Real (experimental) Questions there are so that when the last image is done scroll-lock can be turned off so that exit questions can be answerted by subject. Note that if there are more Practice Questions than Real Questions, not all the Practice data will be over-written in the embedded data arrays.
	if (typeof interval == "undefined")				{var interval = 5} //this is the minimun time interval between recordings of cursor position by the function getMousePosition
	if (typeof imageOrder == "undefined")			{var imageOrder = []} //records the order that images are presented in the randomized Loop & Merge, by their URLs

	//variables used to analyze timing of subject's actions on question page
	if (typeof loadTime == "undefined")				{var loadTime = [0] }		//absolute time when page begins to load
	if (typeof readyTime == "undefined")			{var readyTime = [0] } 		//absolute time when page is fully loaded
	if (typeof firstMoveTime == "undefined")		{var firstMoveTime = 0 }	//absolute time when first mouse move occurs for each image
	if (typeof firstMoveLatency == "undefined") 	{var firstMoveLatency = [0] }//latency to first mouse movement after image appears (calculated value)
	if (typeof answerElapsedTime == "undefined")	{var answerElapsedTime = [0] }//the time between image laoding and clicking an answer button
	if (typeof answerClickTime == "undefined") 		{var answerClickTime = [0] } //absolute time of click on submit (Next) button
	
	//variables used to set allowed limits on subject's actions
	if (typeof maxAnswerTime == "undefined")		{var maxAnswerTime = 5000 }	//maximum time allowed to click an answer button
	if (typeof maxLatency == "undefined")			{var maxLatency = 800 }		//maximum latency allowed for first mouse movement
	if (typeof minWindowWidth == "undefined")		{var minWindowWidth = 925}
	if (typeof minWindowHeight == "undefined")		{var minWindowHeight = 675}	//window dimensions must be large enough to display all buttons wthout scrolling, and will depend on the specific layout of Qualtrics window and size of stimulus images
	
	//Boolean variables used to remember if things were done or limits exceeded
	{var wait = false}								//is getMousePosition function waiting for its interval to expire? (begins as "false" so we don't delay capturing the first mouse move.)
	{var checkedStartPosition = new Boolean(false)} //has mouse start position been checked yet?
	{var didLatency = false}						//have we measured latency yet for this image?
	{var latencyTooLong = false} 					//was subject's latency to first mouse move too long?
	{var latencyTooShort = false} 					//was subject's latency to first mouse move too short?
	{var windowTooSmall = new Boolean(false)} 		//was browser window too small?
	{var answerButtonClicked = new Boolean(false)}	//has answer button been clicked? (used to force answer)
	{var answerTimeTooLong = new Boolean(false)} 	//was subject's time to click an answer button too long?
	//isItPractice enables us to distinguish between practice question #0 and real question #0 (because different things must happen)
	if (typeof isItPractice == "undefined")			{var isItPractice = true}

	//variables used to used to check for correct mouse start position for each question
	if (typeof currentXPosition == "undefined")		{var currentXPosition = 0 }
	if (typeof currentYPosition == "undefined")		{var currentYPosition = 0 }
	if (typeof currentNextButtonRect == "undefined"){var currentNextButtonRect = { left: 0, right: 0, top: 0, bottom: 0} }
	if (typeof nextButtonLeft == "undefined")		{var nextButtonLeft = [0] }
	if (typeof nextButtonRight == "undefined")		{var nextButtonRight = [0] }
	if (typeof nextButtonTop == "undefined")		{var nextButtonTop = [0] }
	if (typeof nextButtonBottom == "undefined")		{var nextButtonBottom = [0] }

	//dimensions of viewport, used to check that browser window is adequately sized
	if (typeof windowHeight == "undefined" )	{var windowHeight = [] }
	if (typeof windowWidth == "undefined" )		{var windowWidth = [] }
	
	//arrays to record values aquired more than once per question
	
	//arrays to record vector of mouse X coordinates, Y coordinates and times
	if (typeof xPos == "undefined") 	{var xPos = [] }
	if (typeof yPos == "undefined")		{var yPos = [] }
	if (typeof time == "undefined")		{var time = [] }
	//array to record which alerts happened
	if (typeof alerts == "undefined" )	{var alerts = [] }

//define functions

	//define the function that gets and records the mouse position vector as fast as the processor can do it (approx 10-20 msec in this code)
	function getMousePosition(event) 
	{//begin: getMousePosition function
		if (!wait)
		{
			wait=true
			// record the time of movement
			var currentTime = Date.now()
			time.push(currentTime)
			// record mouse coordinates relative to upper left corner of browser window
			currentXPosition = Math.round( event.clientX )
			currentYPosition = Math.round( event.clientY )
			xPos.push(currentXPosition)
			yPos.push(currentYPosition)
			//wait an interval before allowing getMousePosition to run again
			setTimeout(() => wait = false, interval)
		}
	}//end: getMousePosition function
		
	//the function that does everything that needs to be done upon the first mouse movement: calculates and records latency to first movement and checks that mouse start position is inside the Next button
	function firstMove()
	{//begin: firstMove function
		//before doing anything else, stop the eventlistener which otherwise would repeatedly invoke firstMove 
		document.removeEventListener("mousemove", firstMove)
		
		//get the time of first move then calculate and record the latency
		firstMoveTime = Date.now()
		firstMoveLatency[imageNumber] = ( firstMoveTime - readyTime[imageNumber] )
			
		//if subject didn't start moving mouse fast enough, remember it, but to avoid interrupting the timing of the answer, we will wait to give an alert until after an answer button is chosen.
		if ( firstMoveLatency[imageNumber] > maxLatency ) {latencyTooLong = true}
		
		//determine if the mouse started outside of the valid starting position (Next button location) before image was fully displayed 
		//compare mouse position to location of Next button on the previous question page
		//if something displaces the Next button on previous question page (like a Qualtrics-generated alert), this will falsely indicate an error in mouse start position. This is why the Qualtrics Force Response option is not used.
		if	(	(currentXPosition  <  ( nextButtonLeft[imageNumber] - 40) ) ||
				(currentXPosition  >  ( nextButtonRight[imageNumber] + 40) ) ||
				(currentYPosition  >  ( nextButtonBottom[imageNumber] + 16) ) ||
				(currentYPosition  <  ( nextButtonTop[imageNumber] - 16) )
			)
			//remember that latency was too short, but to avoid interrupting the trial, we will wait to give an alert until after an answer button is chosen.
			{latencyTooShort = true}
	} //end: firstMove function
		

	//define function to issue alerts to subject (all alerts are issued after answer button is clicked because data can still be used if we don't interrupt question
	function issueAlertsPractice()
	{//begin: issueAlertsPractice function
			if ( latencyTooShort == true )
				{
				alert (  " \n\n                        STARTED TOO EARLY\n\nYou moved the cursor off the Next button before the question was fully displayed." )
				}
			else
				{
				if ( latencyTooLong == true )
					{
					alert (  " \n\n                        STARTED TOO LATE\n\nYou waited more than 1/2 second to start moving the cursor.\n\nTo speed up your answer, try to start moving the cursor sooner, even if you are not yet fully decided about your final answer." )
					}
				}
		
			if ( answerElapsedTime[imageNumber] > maxAnswerTime )
				{
				alert ( "You took longer than the "+(maxAnswerTime/1000)+"-second total time limit to click an answer button." )
				}
			
			if (windowTooSmall == true)
				{
				alert ( "Your browser window is too small.\n\nPlease make it larger.")
				}
	} //end: issueAlertsPractice function

//this function is used to prevent window scrolling (turned on at first practice question, turned off at end of real questions)
	function stopScroll() { window.scrollTo(0, 0) }




Qualtrics.SurveyEngine.addOnload(function()
{//begin: addOnload function

	//there is no need to reset the array variables (as in Real Question block) because practice data are not being saved
	//reset Booleans to default values
	checkedStartPosition = false
	didLatency = false
	latencyTooLong = false
	latencyTooShort = false
	windowTooSmall = false
	answerButtonClicked = false
	answerTimeTooLong = false

	//advance imageNumber by one
	imageNumber += 1
	
	//turn off scrolling
	if (imageNumber == 0) { document.addEventListener("scroll", stopScroll) }
	
	//turn on mousetracking - has to be done now instead of being triggered by first move because otherwise first move wouldn't be recorded
	document.addEventListener("mousemove", getMousePosition)
	
}); //end: addOnload function




Qualtrics.SurveyEngine.addOnReady(function()
//everything in this function is executed as soon as each question page is done loading. Although Qualtrics states that this function is "executed when the page is fully displayed," this is definitely not true; it is executed before the image is displayed. Therefore, because onReadyTime is recorded before the image is displayed, subjects with slow internet connections will have firstMoveLatency and answerReactionTime significantly longer than the true values; they will receive spurious and confusing "Started too late" alerts. 
{ //begin: addOnReady function

	//To prevent subjects from moving to the next page without answering the question, we disable the Next button -- the button will be enabled again after an answer button is clicked. Qualtrics' own forced-response option cannot be used because their alert shifts the Next button to a lower position on the page, which ruins the mouse start position for the subsequent question.
    this.disableNextButton()
	
	//now is the start time for firstMoveLatency and answerReactionTime calculation, so record it before doing anything else
	readyTime[imageNumber] = ( Date.now() )

	//this function asks subject to check the size of their browser window
	function checkWindowAlertPractice()
		{ alert ("Before you answer this question, please check that you can see two answer buttons at the top of the window and a NEXT button at the bottom of the window. If necessary, make your browser window larger now\n\n\n\nIf your device screen is too small to do this, you will not be able to complete this survey.") }
		//invoke this alert function only on first question. (Must be delayed to allow image to be displayed first.)
	 	if ( imageNumber == 0 ) { setTimeout ( checkWindowAlertPractice, 500 ) }
	
	//turn on eventlistener so that the firstMove function is now waiting to be triggered by the first mouse move after onReadyTime
		document.addEventListener("mousemove", firstMove)
		
	//when an answer button is clicked, record data about the time it took to answer, and issue delayed alerts to give subject feedback about any problems with their speed or mouse movement
	this.questionclick = function(event,element)
	{//begin: questionclick block
		if (element.type == 'radio')
		{//begin: if radio button block
			//turn off mousetracking as soon as answer button is clicked
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
			
			//calculate and record the total time it took to answer following page load
			answerElapsedTime[imageNumber] = ( answerClickTime[imageNumber] - readyTime[imageNumber] )
			
			//check window size, just in case subject re-sized window
			if  ( (window.innerWidth < minWindowWidth) || (window.innerHeight < minWindowHeight) ) {windowTooSmall = true}
			
			//evoke function to issue alerts to the subject, after a delay to allow answer button to change color so subject isn't confused
			//but don't issue alerts on first image because cursor starts in wrong place on first question, and subject takes extra time to read windowSizeCheck alert and maybe resize a too-small window
			if ( imageNumber > 0 ) { setTimeout ( issueAlertsPractice, 25 ) }

		}//end: "if radio button" block
	}//end: questionclick block
});//end: addOnReady