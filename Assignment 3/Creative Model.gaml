/***
* Name: Assignment3
* Author: Alexandros Nicolaou, Alexandre Justo Miro
* Description: Coordination & Utility
* Tags: Tag1, Tag2, TagN
***/

model CreativeModel

global {
	int number_of_queens <- 10;//int(rnd(4,10)); // queens can be 4-20
	int number_of_guests <- 30;
	int init_column <-0;
	int column <-0;
	list<queen> queens;
	list<crowd> guests;
	list<water> waterList;
	int createList<-0;
	bool releaseTheCrowd<-false;
	geometry shape<- sphere(50);
	bool followTheLeader<-false;
	bool waterBombs<-false;
	bool destroyFire<-false;
	int countWater<-1;
	matrix cumulativePerception<- 0 as_matrix({number_of_queens,number_of_queens});
	
	init {
		create helicopter number:1 ;
		create water number:1000;
		create crowd number: number_of_guests;
		create queen number: number_of_queens{
			location <- my_grid[init_column,0].location;
			init_column <- init_column+1;
		}
	}
}

grid my_grid skills: [fipa] width: number_of_queens height: number_of_queens {
	rgb color <- bool(((grid_x + grid_y) mod 2)) ? rgb(0,128,0) : rgb(157,193,131);
}

species queen skills: [fipa] {
	
	bool informPred<- false;
	bool informSucc<-false;
	bool moveQueen<-false;
	bool remindPosition<-false;
	list<int> occupiedRows;
	list<int> visitedRows;
	list<int> tempRow;
	int assignedRow<-0;
	int messageQueen;
	bool couldntFindSol;
	bool finishedPlacing;
	
	init{
		add self to: queens;
		createList <- createList+1;
		assignedRow<-0;
		if column=0and(createList=number_of_queens){
			visitedRows <+ assignedRow; // add this row to the visited
			cumulativePerception[column, assignedRow]<- 1;
			do start_conversation with:(to: list(queens[column +1]), protocol: 'fipa-request', performative: 'inform', contents: ['Go on', assignedRow]);
			write 'the first queen started the conversation';
		}
	}
	
	reflex listen_to_the_queen when: !empty(informs){
			message posOfPreviousQueen <- (informs at 0);
			write 'the message is '+posOfPreviousQueen;
			if (posOfPreviousQueen.contents[0]='Help meee'){
				informPred<-true;
			}
			if (posOfPreviousQueen.contents[0]='Go on'){
				messageQueen<-int(posOfPreviousQueen.contents[1]);
				informSucc<-true;
			}
			if (posOfPreviousQueen.contents[0]='Remind me'){
				remindPosition<-true;
			}
	}
	
	reflex inform_Predecessor when: informPred{
		column<-column-1;
		do start_conversation with:(to: list(queens[column -1]), protocol: 'fipa-request', performative: 'inform', contents: ['Remind me']);
		informPred<-false;
	}
	
	reflex inform_Successor when: informSucc{
		column<- column+1;
		moveQueen<-true;
		informSucc<-false;
	}
	
	reflex remind_position when:remindPosition{
		column<- column-1;
		if column<number_of_queens-1{
			do start_conversation with:(to: list(queens[column +1]), protocol: 'fipa-request', performative: 'inform', contents: ['Go on',assignedRow]);
		}
		remindPosition<-false;
	}
	
	reflex move_Queen when: moveQueen and (self=queens[column]){
		list<int> possibleRows<-nil;
		loop i from:0 to:number_of_queens-1{
			possibleRows<+ i; // the possible rows are the n. of rows in a column
		}
		occupiedRows <- [messageQueen-1,messageQueen,messageQueen+1]; // the queen cannot be in one of these rows
		possibleRows <- possibleRows-occupiedRows-visitedRows; // then the possible rows are all except of the occupied
		write 'The possible rows for ' + queen[column]+ ' are ' + possibleRows;
		write 'the possible - visited '+ (possibleRows-visitedRows);
		if !empty(possibleRows) {
			loop assignRow over: possibleRows{
				int parallelRow<-0;
				int upDiagRow <-0;
				int downDiagRow <-0;
				int sumRow<-0;
				int updColDown<-0;
				int updRowDown<-0;
				int updColUp<-0;
				int updRowUp<-0;
				loop while: (column-updColDown>=0) and (assignRow-updRowDown>=0){
					if (cumulativePerception[column-updColDown,assignRow-updRowDown]=1){
						downDiagRow <-downDiagRow+1;
						possibleRows<-possibleRows-assignRow;
						write 'column: '+column+' assignedRow: '+ assignRow+' updRowDown: '+updRowDown+' updColDown: '+updColDown;
						write 'the remained possible are '+ (possibleRows-visitedRows);
					}
					updColDown<-updColDown+1;
					updRowDown<-updRowDown+1;
				}
				loop while: (column-updColUp>=0)and(assignRow+updRowUp<number_of_queens){
					if (cumulativePerception[column-updColUp,assignRow+updRowUp]=1){
						possibleRows<-possibleRows-assignRow;
						upDiagRow <-upDiagRow+1;
						write 'the remained possible are '+ (possibleRows-visitedRows);
					}
					updColUp<-updColUp+1;
					updRowUp<-updRowUp+1;
				}
				loop col from:0 to:column{
					if (cumulativePerception[col, assignRow]=1){
						parallelRow <-parallelRow+1;
						possibleRows<-possibleRows-assignRow;
						write 'the remained possible are '+ (possibleRows-visitedRows);
					}
					write 'the parallel of '+assignRow+' is '+parallelRow;					
				}
				if empty(possibleRows-visitedRows){
					write possibleRows;
					couldntFindSol<-true;
					break;
				}
				sumRow<-parallelRow+upDiagRow+downDiagRow;
				write 'sumrow for row '+assignRow+ ' is '+sumRow;
				if sumRow<1{
					assignedRow <- assignRow;// assign a random row from the possible rows, that had not visited
					visitedRows <+ assignedRow; // add this row to the visited
					self.location<-my_grid[column, assignedRow].location;
					write 'The assigned row for ' + queen[column]+ ' is ' + assignedRow;
					write 'the visited for ' +queen[column] +' queen is ' +visitedRows;
					cumulativePerception[column, assignedRow]<- 1;
					write 'the cum perc is '+cumulativePerception;
					moveQueen<-false;	
					if column<number_of_queens-1{
						do start_conversation with:(to: list(queens[column +1]), protocol: 'fipa-request', performative: 'inform', contents: ['Go on', assignedRow]);
					}else{
						write 'The process finished!';
						finishedPlacing<-true;
						releaseTheCrowd<-true;
					}
					write '' +assignRow+ ' row found to be ok. Lets check it out';
					break;
				}
			}
		}
		if couldntFindSol{
			write 'The ' +queen[column] + ' couldnt find a solution. Go back to the previous queen';
			loop row from:0 to:number_of_queens-1{
				cumulativePerception[column-1,row]<-0;
			}
			visitedRows<-nil;
			moveQueen<-false;
			do start_conversation with:(to: list(queens[column -1]), protocol: 'fipa-request', performative: 'inform', contents: ['Help meee']);					
			couldntFindSol<-false;
		}
	}
	
	reflex finished when: finishedPlacing{
		do start_conversation with:(to: list(guests), protocol: 'fipa-request', performative: 'inform', contents: [location]);					
	}
	
	aspect base {
		draw cube(3) at: location color: #black;
	}
}

species crowd skills:[moving,fipa]{
	point targetPoint;
	point avoidSpeakers;
	point temporLoc;
	point leaderCoord;
	int leader;
	
	init{
		add self to: guests;	
		if length(guests)=number_of_guests{
			leader<-rnd(length(guests)-1);
		}
	}
	
	reflex move{
		do wander;
	}
	
	reflex beTheLeader when:releaseTheCrowd {
		if self=guests[leader]{
			do goto target: {100,0};
			do start_conversation with:(to: list(guests), protocol: 'fipa-request', performative: 'query', contents: [location]);					
			followTheLeader<-true;
		}
	}
	
	reflex escape when:followTheLeader {
		if !(self=guests[leader]){
		message speakersLocation <-(informs at 0);
		avoidSpeakers<-speakersLocation.contents[0];
		
		message leaderLocation<-(queries at 0);
		temporLoc<-leaderLocation.contents[0];
		do goto target: temporLoc;
		}
	}
	
	aspect base{
		draw sphere(1) color: #blue;
	}
}

species helicopter skills:[moving]{
	point locOfFire;
	bool goToFire<-false;
	int x<-0;
	int y<-100;
	
	init{
		location<- {100,0,5};
	}
	
	reflex riseHelic when:followTheLeader {
		if !goToFire{
			do goto target:{100,0,20};
		
			write location.z;
			if abs(location.z-20)<5{
				goToFire<-true;
				write '11111111111';
				write goToFire;
				write destroyFire;
		}
		
		}
		if goToFire and !destroyFire{
			locOfFire<-{0,100,20};
			do goto target:{0,100,20};
			write '22222222222';
			if location distance_to({0,100,20})<5{//location.x<5 and location.y-20<5{
				destroyFire<-true;
				goToFire<-false;
				write '3333333333333';
			}
		}
		if destroyFire{
			x<-x+1;
			y<-y-1;
			do goto target:{x,y,20} speed:0.1;
			waterBombs<-true;
			
		}
	}
	
	aspect base{
		draw obj_file("helic.obj", 90::{-1,0,0}) size: 20
		color: #grey;
	}
}

species water skills:[moving3D]{
	point followhelic;
	
	init{
		add self to: waterList;
	}
	reflex attaaaack when: waterBombs {
		ask helicopter{
			myself.followhelic<-self.location;
		}
		if length(waterList)=1000{
			if bool(countWater mod 3){
				location<-{followhelic.x,followhelic.y,0};
				
			}else{
				location<-followhelic;
				countWater<-countWater+1;
			}
		}
	}
	
	aspect base{
		if destroyFire{
			draw sphere(0.3) color: #blue at:location;
		}
	}
}

grid fires width: 50 height: 50 neighbors: 4 {
	float max_fire <- 1.0 ;
    float fire_prod <- rnd(0.01) ;
    float fire <- rnd(1.0) max: max_fire update: fire + fire_prod ;
    rgb colors <- rgb(int(255 * (1 - fire)), 255, int(255 * (1 - fire)));
	reflex when:releaseTheCrowd{
		float newfire<-(-grid_x+grid_y+(time/30))/(100) ;
		
		colors <- rgb(255,int(255 * (1 - newfire)), int(255 * (1 - newfire)));
	    fire <- rnd(1.0);
	}
	
    rgb color <- colors update: releaseTheCrowd? colors : colors;
}

experiment CreativeModel type: gui {
	parameter 'Number of queens: ' var:number_of_queens min:4 max:20 category: 'Queens';
	output {
		display main_display type: opengl{
			grid my_grid lines:#black ;
			grid fires lines: #black;
			species queen aspect: base transparency: 0.1;	
			species crowd aspect:base;
			species helicopter aspect:base transparency: 0.2;
			species water aspect:base;
		}
	}	
}