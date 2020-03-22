/***
* Name: CreativeModel
* Author: Alexandros Nicolaou, Alexandre Justo Miro
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model CreativeModel

// Global
global {
	/** Insert the global definitions, variables and actions here */
	float worldDimension <- 100#m; // Is not needed because anyway the default is 100m square
	geometry shape <- square(worldDimension);
	int number_of_guests <- 10;
	int number_of_storeD <- 3;  // Drinks
	int number_of_storeF <- 2;  // Food
	int number_of_infoCT <- 1;
	int number_of_security <- 2;
	int number_of_DJ <- 1;
	
	// Initialize the agents
	init {		
		create guests number: number_of_guests;
		create security number: number_of_security;
		create storeDrinks number: number_of_storeD;
		create storeFood number: number_of_storeF;
		point center <- {worldDimension/2, worldDimension/2};
		point stage <- {worldDimension/2, 5};
		create infoCT number: number_of_infoCT with: (location:center);
		create DJ number: number_of_DJ with: (location:stage);
	}
}

// Guests
species guests skills:[moving] {
	
	bool thirsty <- false; //To define the process of drinking
    bool hungry <- false; //To define the process of eating
    bool drinkColor <- false; // To define the color of thirsty
    bool eatColor <- false; // To define the color of hungry
	float max_thirst <- 1.0;
    float thirst_step <- rnd(0.001);
	float max_hunger <- 1.0;
    float hunger_step <- rnd(0.0005);
    float is_thirsty <- rnd(0.2) update: is_thirsty + thirst_step max: max_thirst; // flag to trigger thirst need
    float is_hungry <- rnd(1.0) update: is_hungry + hunger_step max: max_hunger; // flag to trigger hunger need
    list list_drinkStores;
	list list_drinkStore;
	list list_foodStores;
	list list_foodStore;
	bool skipInfo <- false;
	point targetPoint <- nil;
	point suspicious <- nil;
	
	// For drugs
	bool betray <- false;
	bool betray_color <- false;
	float max_crazy <- 1.0;
	float crazy_step <- rnd(0.01);
	float is_crazy <- rnd(0.5) update: is_crazy + crazy_step max: max_crazy;
	bool crazy <- false;
	bool reachedSecurity <- false;
	bool foundSecurity <- false;
	bool heGotMe <- false;
	int onlyOneBetrayor <- 0;
	bool theOneBetrayor <- false;
	bool potentialCrazy <- flip(0.3);
	bool escortSecurity <- false;
	
	// For computing distance traveled
	point add_distance_starting_point <- nil;
	point add_distance_ending_point <- nil;
	float add_distance <- 0.0;
	float dAB <- 0.0;
	float dBC <- 0.0;
	float distance_saved <- 0.0;
	
	// For DJ
	point stage <- {worldDimension/2, 5};
		
	aspect base{
		draw circle(0.8#m) color: (crazy) ? #purple : ((betray_color) ? #yellow : (((drinkColor) ? #blue : ((((eatColor) ? #red: #lawngreen))))));
	}
		
	reflex stay when: targetPoint = nil {
		// Creative part only! (the if statement)
		if (distance_to(location, stage) > 20#m) {
			do goto target: stage;
		}
		do wander;
	}
	
	reflex move when: targetPoint != nil {
		do goto target:targetPoint;
	}
	
	// Challenge 2: They are the drug dealers //
	reflex goCrazy when: is_crazy>0.9 and (potentialCrazy){
		is_thirsty <- 0.0;
		is_hungry <- 0.0;
		crazy <- true;
		suspicious <- location;
		ask security at_distance 3#m{
			if (self.arrested=true){
				myself.is_crazy <- 0.0;
				myself.heGotMe <- true; // when the security is close to me, die
			}
		}
		ask guests at_distance 100#m{
			if (self.escortSecurity){
				self.targetPoint <- myself.suspicious;
				self.escortSecurity <- false;
			}
			if (myself.heGotMe){
				self.targetPoint <- nil;
			}
		}
		ask security at_distance 100#m{
			if (myself.heGotMe){
				self.arrested <- false;
			}
		}
		if (heGotMe){
			do die;
		}
	}
	
	// Challenge 2: They are the ones who betray fellow dealers //
	reflex betray {
		ask guests at_distance 100#m{
			if (self.crazy) and (myself.potentialCrazy=false){
				self.onlyOneBetrayor <- self.onlyOneBetrayor + 1;
				if (self.onlyOneBetrayor<2){
					if (myself.betray=false) {
						myself.theOneBetrayor <- true; // Just to set the if conditions to this agent only
						myself.targetPoint<-one_of(infoCT).location;
						myself.betray_color <- true;
					}
				}
			}
		}
		ask infoCT at_distance 2#m{
			if (myself.betray=false) and (myself.theOneBetrayor){
				myself.targetPoint <- self.securityLocation;
				myself.betray <- true;
			}
		}
		ask security at_distance 2#m {
			if (myself.betray=true){
				myself.foundSecurity <- true;
				self.guestFoundDrugDealer <- true;
				myself.betray <- false;
				myself.betray_color <- false;
				myself.theOneBetrayor <- false;
				myself.escortSecurity <- true;
			}
		}
	}
	
	reflex drink when: is_thirsty > 0.9 and (potentialCrazy=false){
		
		add_distance_starting_point <- location;
		is_hungry <- 0.0;
		is_crazy <- 0.0;
				
		if (thirsty = false) {
			
			// Challenge 1: To go to one of the visited places (memory) //
			if (list_drinkStores=[]){
				targetPoint <- one_of(infoCT).location; // Go to infoCT
			} else {
				if (length(list_drinkStores) = number_of_storeD){
					targetPoint <- any(list_drinkStores); // If you visited all of the stores, then go to any of them
					skipInfo <- true;
					add_distance_ending_point <- targetPoint;
					add_distance <- add_distance + distance_to(add_distance_starting_point, add_distance_ending_point);
					distance_saved <- distance_saved + distance_to(add_distance_starting_point, one_of(infoCT).location) + distance_to(one_of(infoCT).location, targetPoint) - distance_to(add_distance_starting_point, add_distance_ending_point);
				} else {
					bool memory <- flip(0.5);
					if (memory){
						targetPoint <- any(list_drinkStores); // If not, then either go to any of the visited, either go to infoCT for a new one
						skipInfo <- true;
						add_distance_ending_point <- targetPoint;
						add_distance <- add_distance + distance_to(add_distance_starting_point, add_distance_ending_point);
						distance_saved <- distance_saved + distance_to(add_distance_starting_point, one_of(infoCT).location) + distance_to(one_of(infoCT).location, targetPoint) - distance_to(add_distance_starting_point, add_distance_ending_point);
					} else {
						targetPoint <- one_of(infoCT).location;
					}
				}
			}
			drinkColor <- true;
		}
		
		// Challenge 1: To ask other agents about places. Only ask them if I am going to InfoCT! //
		ask guests at_distance 5#m{
			if (myself.targetPoint = one_of(infoCT).location and self.list_drinkStores!=[]){
				myself.skipInfo <- true;
				myself.targetPoint <- any(self.list_drinkStores);
				myself.add_distance_ending_point <- myself.targetPoint;
				myself.dAB <- distance_to(myself.add_distance_starting_point, myself.location);
				myself.dBC <- distance_to(myself.location, myself.add_distance_ending_point);
				myself.add_distance <- myself.add_distance + myself.dAB + myself.dBC;
				myself.distance_saved <- myself.distance_saved + distance_to(myself.add_distance_starting_point, one_of(infoCT).location) + distance_to(one_of(infoCT).location, myself.targetPoint) - myself.dAB - myself.dBC;
			}
		}
		ask infoCT at_distance 3#m {
			if (myself.thirsty=false){
				myself.targetPoint <- self.locationStoreDrinks;
				myself.add_distance_ending_point <- myself.targetPoint;
				myself.dAB <- distance_to(myself.add_distance_starting_point, myself.location);
				myself.dBC <- distance_to(myself.location, myself.add_distance_ending_point);
				myself.add_distance <- myself.add_distance + myself.dAB + myself.dBC;
				
				// Challenge 1: To store visited places //
				if (myself.list_drinkStores contains myself.targetPoint){
	
				} else {
					myself.list_drinkStores <- list(myself.list_drinkStores + myself.targetPoint);
					myself.list_drinkStore <- list(name, myself.list_drinkStores);
				}
				myself.thirsty <- true;
			}			
		}
		
		// Challenge 1: skip infoCT //
		if (skipInfo){
			thirsty <-true;
			skipInfo <- false;
		}
		
		if (location distance_to(one_of(storeDrinks).location) < 3#m) and (thirsty = true){
			targetPoint <- nil;
			is_thirsty <- 0.0;
			thirsty <- false;
			drinkColor <- false;
		}
	}	
	
	// The same logic for eating
	reflex eat when: is_hungry > 0.9 and (potentialCrazy=false){
		
		add_distance_starting_point <- location;
		is_thirsty <- 0.0;
		is_crazy <- 0.0;
		
		if (hungry = false) {
			
			if (list_foodStores=[]){
				targetPoint <- one_of(infoCT).location;
			} else {
				if (length(list_foodStores) = number_of_storeF){
					targetPoint <- any(list_foodStores);
					skipInfo <- true;
					add_distance_ending_point <- targetPoint;
					add_distance <- add_distance + distance_to(add_distance_starting_point,add_distance_ending_point);
					distance_saved <- distance_saved + distance_to(add_distance_starting_point, one_of(infoCT).location) + distance_to(one_of(infoCT).location, targetPoint) - distance_to(add_distance_starting_point,add_distance_ending_point);
				}else{
					bool memory <- flip(0.5);
					if (memory){
						targetPoint <- any(list_foodStores);
						skipInfo <- true;
						add_distance_ending_point <- targetPoint;
						add_distance <- add_distance + distance_to(add_distance_starting_point,add_distance_ending_point);
						distance_saved <- distance_saved + distance_to(add_distance_starting_point, one_of(infoCT).location) + distance_to(one_of(infoCT).location, targetPoint) - distance_to(add_distance_starting_point,add_distance_ending_point);
					}else{
						targetPoint <- one_of(infoCT).location;
					}
				}
			}
			eatColor <- true;
		}
		ask guests at_distance 5#m{
			// Only ask them if I am going to InfoCT!
			if (myself.targetPoint = one_of(infoCT).location and self.list_foodStores!=[]){
				myself.skipInfo <- true;
				myself.targetPoint <- any(self.list_foodStores);
				myself.add_distance_ending_point <- myself.targetPoint;
				myself.dAB <- distance_to(myself.add_distance_starting_point, myself.location);
				myself.dBC <- distance_to(myself.location, myself.add_distance_ending_point);
				myself.add_distance <- myself.add_distance + myself.dAB + myself.dBC;
				myself.distance_saved <- myself.distance_saved + distance_to(myself.add_distance_starting_point, one_of(infoCT).location) + distance_to(one_of(infoCT).location, myself.targetPoint) - myself.dAB - myself.dBC;
			}
		}
		ask infoCT at_distance 3#m{
			if (myself.hungry=false){
				myself.targetPoint <- self.locationStoreFood;
				myself.add_distance_ending_point <- myself.targetPoint;
				myself.dAB <- distance_to(myself.add_distance_starting_point, myself.location);
				myself.dBC <- distance_to(myself.location, myself.add_distance_ending_point);
				myself.add_distance <- myself.add_distance + myself.dAB + myself.dBC;
				if (myself.list_foodStores contains myself.targetPoint){
	
				} else {
					myself.list_foodStores <- list(myself.list_foodStores + myself.targetPoint);
					myself.list_foodStore <- list(name, myself.list_foodStores);
				}
				myself.hungry <- true;	
			}
		}
		if (skipInfo){
			hungry <- true;
			skipInfo <- false;
		}
		if (location distance_to(one_of(storeFood).location) < 3#m) and (hungry = true){
			targetPoint <- nil;
			is_hungry <- 0.0;
			hungry <- false;
			eatColor <- false;
		}
	}
	
	// Print the actual distance traveled and the saved distance.
	reflex print_distance when: distance_saved > 0 {
		write 'Total dist: ' + with_precision(add_distance,1) + ' m. Saved dist: ' + with_precision(distance_saved,1) + ' m.';
	}
}

species security skills:[moving]{
	bool arrested <- false;
	bool guestFoundDrugDealer <- false;
	point targetPoint <- nil;
	point startingPoint <- location;
	
	reflex move when: targetPoint != nil{
		do goto target:targetPoint;
	}
	
	reflex arrest {
		// For the guests that betray others
		// Just some flags to declare when the drug dealer got arrested
		ask guests at_distance 100#m{
			if (myself.arrested=true){
				self.foundSecurity <- false;
				//myself.guestFoundDrugDealer <- false;
				myself.arrested <- false;
			}
		}
		// For the drug dealers
		ask guests at_distance 100#m{
			if (myself.guestFoundDrugDealer=true){
				/*if (self.heGotMe){
					myself.arrested<- false;
				}*/
				if (self.crazy=true){
					myself.targetPoint <- self.suspicious; //set new target, the location of drugs
				}
				if (myself.location distance_to(self.location) < 2#m) and (self.crazy=true) {
					myself.targetPoint <- myself.startingPoint;
					myself.arrested <- true;
					//self.foundSecurity <- false;
					myself.guestFoundDrugDealer <- false;
				}
			}
		}		
	}

	aspect base{
		draw circle(1.5#m) color: #black;
		draw "S" at: location + {-0.75, 1} color: #white font: font('Default', 12, #bold);
	}
}

// Stores
species storeDrinks {
	aspect base{
		draw rectangle(6#m,6#m) color: #aqua;
		draw "D" at: location + {-0.75, 1} color: #black font: font('Default', 12, #bold);
	}
}
species storeFood {
	aspect base{
		draw rectangle(6#m,6#m) color: #chocolate;
		draw "F" at: location + {-0.75, 1} color: #black font: font('Default', 12, #bold);
	}
}

// Info Center
species infoCT {
	point locationStoreDrinks <- one_of(storeDrinks).location update: one_of(storeDrinks).location;
	point locationStoreFood <- one_of(storeFood).location update: one_of(storeFood).location;
	point securityLocation <- one_of(security).location update: one_of(security).location;
	aspect base{
		draw rectangle(15#m,6#m) color: #black;
		draw "INFO" at: location + {-3, 1} color: #white font: font('Default', 12, #bold);
	}
}

// Creative part only! Add music coming from an international DJ:
species DJ {
	aspect base{
		draw rectangle(10#m,4#m) color: #pink;
		draw "MUSIC" at: location + {-3.75, 1} color: #black font: font('Default', 12, #bold);
	}
}

// Experiment
experiment CreativeModel type: gui {
	output {
		display my_display{
			species guests aspect:base;
			species security aspect:base;
			species storeDrinks aspect:base;
			species storeFood aspect:base;
			species infoCT aspect:base;
			species DJ aspect:base;
		}
	}
}