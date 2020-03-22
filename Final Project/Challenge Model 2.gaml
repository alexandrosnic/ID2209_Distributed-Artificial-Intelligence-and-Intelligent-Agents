/***
* Name: FinalProject
* Author: Alexandros Nicolaou, Alexandre Justo Miro
* Description: Behavior of different agents
* Tags: Tag1, Tag2, TagN
***/


model ChallengeModel2

global {
	int grid_size<-8;
	int number_of_drugs <- 6;
	int number_of_guests <- 1;
	int number_of_police <-1;
	
	list drugs_list;
	
	bool next_episode <- true;
	bool perform_best_road <- false;
	int police_location;
	
	init {		
		create drugs number: number_of_drugs;
		create police number: number_of_police;
		create guest number: number_of_guests {
			location <- initial_location.location;	
		}
	}
	
//	reflex pause_simulation when:perform_best_road{
//		do pause;
//	}
}

grid my_grid width: grid_size height: grid_size neighbors:4{
	rgb color <- bool(((grid_x + grid_y) mod 2)) ? #grey : #white;
}

species guest skills: [moving] {
	
	// Learning parameters
	int total_episodes <- 15000;        // Total episodes
	float learning_rate <- 0.8;         // Learning rate
	int max_steps <- 99;                // Max steps per episode
	int learn_step <- 100;				// Learn Step
	float discount_rate <- 0.9;			// Discounting rate
              
	
	// Exploration parameters
	float epsilon <- 100.0;               // Exploration rate
	float max_epsilon <- 100.0;           // Exploration probability at start
	float min_epsilon <- 1.0;             // Minimum exploration probability 
	float decay_rate <- 0.005;            // Exponential decay rate for exploration prob
	
	// Environment parameters
	my_grid my_cell <- one_of(my_grid);
	my_grid initial_location <- my_cell;
	int stateIndex <- my_grid index_of initial_location ;
	int total_rewards;
	list rewards;
	bool initialized <- false;
	int episode<-1;
    int best_sequence_index;
    int best_action_index <- 0;
    int rewardStateIndex;
    list best_road;
	
	// Q table parameters
	list<list> qtable;
	init{
		loop i from:0 to: grid_size^2-1{
			list<float> state_list <- [0.0,0.0,0.0,0.0];
			add state_list to: qtable;
		}	
	}
	
	//////////////////// Next episode reflex /////////////////////
	reflex update_episode when: next_episode{
		episode <- episode +1;
		//write qtable;
		if initialized{
			epsilon <- min_epsilon + (max_epsilon - min_epsilon)*exp(-decay_rate*episode);
			add total_rewards to: rewards;	
    	}
    	total_rewards <- 0;	
    	learn_step <- 0;
		if episode =100{
			location <- initial_location.location;
			best_sequence_index <- rewards index_of min(rewards);
			learn_step <- max_steps +10;
			perform_best_road <- true;
		}
		next_episode <- false;
	}
	
	///////////////////////// Update step reflex ///////////////////////
	reflex update_step when: (learn_step<=max_steps){
		int randomN <- rnd(0,100);
		int actionIndex;
		list<float> max_q_list;
		list alternative_cells;
		int reward <- 0;
		int dummy_index;
		
		/////////////////// Define actions ////////////////////////
		my_grid right <- my_grid[my_cell.grid_x+1,my_cell.grid_y];
		my_grid left <-  my_grid[my_cell.grid_x-1,my_cell.grid_y];
		my_grid up <-  my_grid[my_cell.grid_x,my_cell.grid_y-1];
		my_grid down <-  my_grid[my_cell.grid_x,my_cell.grid_y+1];
		list<my_grid> possible_cells <- nil;
		if my_cell.grid_x=grid_size-1 and !((my_cell.grid_y=grid_size-1) or (my_cell.grid_y=0)){
			possible_cells <-[left,up,down];
		}else if my_cell.grid_y=grid_size-1 and !((my_cell.grid_x=grid_size-1) or (my_cell.grid_x=0)){
			possible_cells <-[left,up,right];
			
		}else if my_cell.grid_y=0 and !((my_cell.grid_x=grid_size-1) or (my_cell.grid_x=0)){
			possible_cells <-[left,down,right];
			
		}else if my_cell.grid_x=0 and !((my_cell.grid_y=0) or (my_cell.grid_y=grid_size-1)){
			possible_cells <-[down,up,right];
		
		}else if my_cell.grid_x=grid_size-1 and my_cell.grid_y=grid_size-1 {
			possible_cells <- [left,up] ;
		}else if my_cell.grid_x=grid_size-1 and my_cell.grid_y=0  {
			possible_cells <- [left,down] ;
		}else if my_cell.grid_y=grid_size-1 and my_cell.grid_x=0  {
			possible_cells <- [right,up] ;
		}else if my_cell.grid_x=0 and my_cell.grid_y=0  {
			possible_cells <- [down,right] ;
		}else{
			possible_cells <- [right,left,up,down] ;	
		}
		
		///////// Choose next action based on exploration parameter /////
		if randomN > epsilon{
			int current_actionIndex <- 0;
			float max_action_outcome <- qtable[stateIndex][current_actionIndex];
			float current_q_value <- qtable[stateIndex][current_actionIndex+1];
			loop i from:1 to: length(possible_cells)-1{
				if (max_action_outcome < current_q_value){
					max_action_outcome <- current_q_value;
					current_actionIndex <- i;
				}
				if i<length(possible_cells)-1{
					current_q_value <- qtable[stateIndex][i+1];	
				}
			}
			my_cell <- possible_cells[current_actionIndex];
		}else{
			my_cell <- any(possible_cells); 
		}
		possible_cells <- possible_cells - my_cell;
		
		///////////////////// Upgrade action ///////////////////////////
		if my_cell = left{
			actionIndex<-0;
			write 'The guest moves to his left grid';
		}
		if my_cell = right{
			actionIndex<-1;
			write 'The guest moves to his right grid';
		}
		if my_cell = up{
			actionIndex<-2;
			write 'The guest moves to his up grid';
		}
		if my_cell = down{
			actionIndex<-3;
			write 'The guest moves to his down grid';
		}
		
		/////////////////// Rewards system ////////////////////////////
		rewardStateIndex <- my_grid index_of my_cell ;
		loop i from:0 to: (length(drugs_list)-1){
			if drugs_list[i] = rewardStateIndex{
				reward <- drugs[i].drug_reward;
				break;
				
				
			}else{
				reward <- 0;
			}
		}
		if rewardStateIndex = police_location{
			reward <- -10;
		}
		
		////////////////////// Build the Q table //////////////////////
		loop i from:0 to: (length(possible_cells)-1){
			if my_cell!=possible_cells[i]{
				if possible_cells[i]=down{
					dummy_index <- 3;
				}else if possible_cells[i]=up{
					dummy_index <- 2;
				}
				else if possible_cells[i]=right{
					dummy_index <- 1;
				}
				else if possible_cells[i]=left{
					dummy_index <- 0;
				}
				add qtable[stateIndex][dummy_index] to: max_q_list;	
			}
		}
		float max_q_value <- max(max_q_list);
		float temporary_q_value <-  qtable[stateIndex][actionIndex];
		qtable[stateIndex][actionIndex] <- temporary_q_value + learning_rate*(reward+discount_rate*max_q_value - temporary_q_value);
		write 'The Q table is ' + qtable;
		
		//////////// Define location and go to the next step ////////////////
		stateIndex<- my_grid index_of my_cell ;
		total_rewards <- total_rewards + reward;
		location <- my_cell.location;
		if learn_step = max_steps{
			location <- initial_location.location;
			initialized <-true;
			next_episode <- true;
		}
		learn_step <- learn_step +1;
	}
	
	//////////////// Perform the optimized path based on reinforcement learning ////////////////
	reflex performTheBestRoad when: perform_best_road{
		int next_best_move;
		int actionIndex;
		my_cell <- my_grid(location);
		stateIndex <- my_grid index_of my_cell;
		
		////////////////////// Choose the next action ////////////////////////////
		int counter<-0;
		loop i from:0 to: 3{
			if qtable[stateIndex][i]=0.0{
				counter <-counter +1;
			}
		}
		if counter=4{
			next_best_move <-rnd(0,3);
		}else{
			next_best_move <- qtable[stateIndex] index_of max(qtable[stateIndex]);	
		}		
		bool found_move<-false;
		list current_list <-qtable[stateIndex];
		loop while: !found_move{
			if next_best_move=0 and !(my_cell.grid_x=0){
				my_cell <- my_grid[my_cell.grid_x-1,my_cell.grid_y];
				actionIndex <-0;
				found_move <- true;
				if mod(stateIndex,grid_size)>1{
					qtable[stateIndex-2][1] <- 0.0;	
				}
				if (stateIndex+grid_size)<grid_size^2{
					qtable[stateIndex+grid_size-1][2] <- 0.0;	
				}
				if (stateIndex-grid_size-1)>=0{
					qtable[stateIndex-grid_size-1][3] <- 0.0;	
				}
			}
			else if next_best_move=1 and !(my_cell.grid_x=grid_size-1){
				my_cell <- my_grid[my_cell.grid_x+1,my_cell.grid_y];
				actionIndex <-1;
				found_move <- true;
				if grid_size-(mod(stateIndex,grid_size))>1 and stateIndex+2<grid_size^2{
					qtable[stateIndex+2][0] <- 0.0;	
				}
				if (stateIndex+grid_size+1)<grid_size^2{
					qtable[stateIndex+grid_size+1][2] <- 0.0;	
				}
				if (stateIndex-grid_size+1)>0{
					qtable[stateIndex-grid_size+1][3] <- 0.0;	
				}
			}
			else if next_best_move=2 and !(my_cell.grid_y=0){
				my_cell <- my_grid[my_cell.grid_x,my_cell.grid_y-1];
				actionIndex <-2;
				found_move <- true;
				if grid_size-(mod(stateIndex,grid_size))>1 and stateIndex-grid_size+1>=0{
					qtable[stateIndex-grid_size+1][0] <- 0.0;	
				}
				if mod(stateIndex,grid_size)>=1 and stateIndex-grid_size-1 >=0 {
					qtable[stateIndex-grid_size-1][1] <- 0.0;	
				}
				if (stateIndex-2*grid_size)>=0{
					qtable[stateIndex-2*grid_size][3] <- 0.0;	
				}
			}
			else if next_best_move=3 and !(my_cell.grid_y=grid_size-1 ){
				my_cell <- my_grid[my_cell.grid_x,my_cell.grid_y+1];
				actionIndex <-3;
				found_move <- true;
				if grid_size-(mod(stateIndex,grid_size))>1 and stateIndex+grid_size+1 < grid_size^2{
					qtable[stateIndex+grid_size+1][0] <- 0.0;	
				}
				if mod(stateIndex,grid_size)>=1 and stateIndex+grid_size-1 < grid_size^2{
					qtable[stateIndex+grid_size-1][1] <- 0.0;	
				}
				if (stateIndex+2*grid_size)<grid_size^2{
					qtable[stateIndex+2*grid_size][2] <- 0.0;	
				}
			}else{
				
				current_list[next_best_move] <- 0;
				int counter<-0;
				loop i from:0 to: 3{
					if current_list[i]=0.0{
						counter <-counter +1;
					}
				}
				if counter=4{
					next_best_move <-rnd(0,3);
				}else{
					next_best_move <- current_list index_of max(current_list);		
				}
//				next_best_move <- rnd(0,3);	
			}
		}
		write 'next is ' + next_best_move;
		qtable[stateIndex][actionIndex] <- 0.0;


		/////////////// Update the list of the remaining drugs ///////////////
		int qtableIndex <- my_grid index_of my_cell;
		loop i from:0 to: (length(drugs_list)-1){
			if drugs_list[i] = qtableIndex{
				drugs[i].drug_reward <- 0;
				remove drugs_list[i] from: drugs_list;
				break;
			}
		}
		
		/////////////// The guest completed his task ///////////////
		add my_cell to: best_road;
		location <- my_cell.location;
		if empty(drugs_list){
			write 'The final road is ' + best_road;
			do die;
		}
	}
			
	aspect base {
		draw circle(3) at: {location.x,location.y} color: #blue;
	}
}

species drugs {
	my_grid drug_location<-one_of(my_grid);
	int drug_reward <- rnd(10,100);
	
	init{
		location <- drug_location.location;
		int drug_index <- my_grid index_of drug_location;
		name <- drug_index;
		add drug_index to: drugs_list;
	}
	
	aspect base {
		draw circle(2+drug_reward*0.03) color: #red at:{location.x, location.y};
	}
}

species police skills: [moving] {
	
	point targetpoint;
	init{
		location <- {rnd(0,grid_size)*10+100/grid_size/2, 10*rnd(0,grid_size)+100/grid_size/2};	
	}
	
	reflex chase_the_drug{
		ask guest{
			myself.targetpoint <-self.location;	
			speed <- 5;
		}
		do goto target: targetpoint;
		police_location <- my_grid index_of location;
	}
		
	aspect base {
		draw circle(3) color: #yellow;
	}
}

experiment ChallengeModel2 type: gui {
	output {
		display Festival {
			grid my_grid lines:#black ;
			species drugs aspect: base;
			species guest aspect: base;
			species police aspect: base;
		}
	}
}
