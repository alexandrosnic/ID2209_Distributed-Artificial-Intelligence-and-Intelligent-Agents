/***
* Name: Assignment3
* Author: Alexandros Nicolaou, Alexandre Justo Miro
* Description: Coordination & Utility
* Tags: Tag1, Tag2, TagN
***/

model BasicModelTask1

global {
	int number_of_queens <- 16;
	int init_column <-0;
	int column <-0;
	list<queen> queens;
	int createList<-0;
	matrix cumulativePerception<- 0 as_matrix({number_of_queens,number_of_queens});
	
	init {
		create queen number: number_of_queens{
//			if number_of_queens = 4 {
//				location <- my_grid[init_column,1].location;
//				init_column <- init_column+1;
//			}
			location <- my_grid[init_column,0].location;
			init_column <- init_column+1;
		}
	}
}

grid my_grid skills: [fipa] width: number_of_queens height: number_of_queens {
	rgb color <- bool(((grid_x + grid_y) mod 2)) ? #grey : #white;
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
	
	reflex remind_position when:remindPosition {
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
	
	aspect base {
		draw sphere(2) at: location color: #blue;
	}
}

experiment BasicModelTask1 type: gui {
	output {
		display main_display type: opengl{
			grid my_grid lines:#black;
			species queen aspect: base;	
		}
	}	
}