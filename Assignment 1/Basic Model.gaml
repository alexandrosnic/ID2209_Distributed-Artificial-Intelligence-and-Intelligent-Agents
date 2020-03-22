/***
* Name: BasicModel
* Author: Alexandros Nicolaou, Alexandre Justo Miro
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model BasicModel

// Global
global {
	/** Insert the global definitions, variables and actions here */
	float worldDimension <- 100#m; // Is not needed because anyway the default is 100m square
	geometry shape <- square(worldDimension);
	int number_of_guests <- 10;
	int number_of_storeD <- 3;  // Drinks
	int number_of_storeF <- 2;  // Food
	int number_of_infoCT <- 1;
	
	// Initialize the agents
	init {		
		create guests number: number_of_guests;
		create storeDrinks number: number_of_storeD;
		create storeFood number: number_of_storeF;
		point center <- {worldDimension/2, worldDimension/2};
		create infoCT number: number_of_infoCT with: (location:center);
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
	point targetPoint <- nil;
			
	aspect base{
		draw circle(0.8#m) color: (drinkColor) ? #blue : ((eatColor) ? #red: #lawngreen);
	}
		
	reflex stay when: targetPoint = nil {
		do wander;
	}
	
	reflex move when: targetPoint != nil {
		do goto target:targetPoint;
	}
	
	
	reflex drink when: is_thirsty > 0.9 {
						
		if (thirsty = false) {
			targetPoint <- one_of(infoCT).location;
			drinkColor <- true;
		}
		
		ask infoCT at_distance 3#m {
			if (myself.thirsty=false){
				myself.targetPoint <- self.locationStoreDrinks;
				myself.thirsty <- true;
			}			
		}
				
		if (location distance_to(one_of(storeDrinks).location) < 3#m) and (thirsty = true){
			targetPoint <- nil;
			is_thirsty <- 0.0;
			thirsty <- false;
			drinkColor <- false;
		}
	}	
	
	// The same logic for eating
	reflex eat when: is_hungry > 0.9 {
		
		
		if (hungry = false) {
			targetPoint <- one_of(infoCT).location;
			eatColor <- true;
		}
		ask infoCT at_distance 3#m{
			if (myself.hungry=false){
				myself.targetPoint <- self.locationStoreFood;
				myself.hungry <- true;	
			}
		}
		if (location distance_to(one_of(storeFood).location) < 3#m) and (hungry = true){
			targetPoint <- nil;
			is_hungry <- 0.0;
			hungry <- false;
			eatColor <- false;
		}
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
	aspect base{
		draw rectangle(15#m,6#m) color: #black;
		draw "INFO" at: location + {-3, 1} color: #white font: font('Default', 12, #bold);
	}
}


// Experiment
experiment BasicModel type: gui {
	output {
		display my_display{
			species guests aspect:base;
			species storeDrinks aspect:base;
			species storeFood aspect:base;
			species infoCT aspect:base;
		}
	}
}