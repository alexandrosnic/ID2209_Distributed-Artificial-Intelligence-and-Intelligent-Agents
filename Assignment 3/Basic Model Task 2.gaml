/***
* Name: Assignment3
* Author: Alexandros Nicolaou, Alexandre Justo Miro
* Description: Coordination & Utility
* Tags: Tag1, Tag2, TagN
***/

model BasicModelTask2

global {
	int number_of_guests <- 30;
	int number_of_stages <- 4;
	
	point stage_location1 <- {10,10};
	point stage_location2 <- {10,90};
	point stage_location3 <- {70,10};
	point stage_location4 <- {70,90};
	
	list<guest> GuestList <- [];
	list<string> StageList <- [];
	
	init {
		create guest number: number_of_guests;
		create stage number: number_of_stages;
	}
}

species guest skills: [fipa, moving] {

	rgb color;
	
	bool initialized <- false;
	string step <- '0';
	bool first_time <- true;
	point targetPoint;
	
	float prew1 <- rnd(0.0, 1.0);
	float prew2 <- rnd(0.0, 1.0);
	float prew3 <- rnd(0.0, 1.0);
	float prew4 <- rnd(0.0, 1.0);
	float prew5 <- rnd(0.0, 1.0);
	float prew6 <- rnd(0.0, 1.0);
	float norm_fact <- prew1 + prew2 + prew3 + prew4 + prew5 + prew6;
	float w1 <- prew1/norm_fact;
	float w2 <- prew2/norm_fact;
	float w3 <- prew3/norm_fact;
	float w4 <- prew4/norm_fact;
	float w5 <- prew5/norm_fact;
	float w6 <- prew6/norm_fact;
	
	float utility;
	float max_utility;
	
	list empty <- [{0.0, 0.0, 0.0}, 0.0];
	list memory <- [empty, empty, empty, empty, empty];
	
	aspect base {
		if !self.initialized {
			add self to: GuestList;
			self.initialized <- true;
		}
		self.color <- #lawngreen;
		draw circle(0.8) at: self.location color: self.color;
	}
	
	reflex readMessage when: (!(empty(cfps))) {
		
		step <- '0';
		
		message a <- (cfps at 0);
		point where <- point(a.contents at 0);
		float f1 <- float(a.contents at 1);
		float f2 <- float(a.contents at 2);
		float f3 <- float(a.contents at 3);
		float f4 <- float(a.contents at 4);
		float f5 <- float(a.contents at 5);
		float f6 <- float(a.contents at 6);
		int index <- StageList index_of string(a.contents at 7);
		
		self.utility <- self.w1*f1 + self.w2*f2 + self.w3*f3 + self.w4*f4 + self.w5*f5 + self.w6*f6;
		self.memory[index] <- [where, self.utility];

		if first_time=true and index=number_of_stages-1 {
			step <- '1';
			first_time <- false;
		} else {
			step <- '1';
		}
	}
	
	reflex chooseStage when: step='1' {
		
		self.max_utility <- 0.0;
		loop m over: self.memory {
			if float(m[1]) > self.max_utility {
				self.max_utility <- float(m[1]);
				self.targetPoint <- point(m[0]);
			}
		}
		do goto target: self.targetPoint;
		if (self.location distance_to(self.targetPoint) < 5) {
			self.targetPoint <- self.location;
			do wander;
		}
	}
}

species stage skills: [fipa] {
	
	rgb color;
	
	bool initialized <- false;
	int label <- 1;
	
	float f1 <- 0.0; // Music
	float f2 <- 0.0; // Band
	float f3 <- 0.0; // Lightshow
	float f4 <- 0.0; // Visuals
	float f5 <- 0.0; // Speakers
	float f6 <- 0.0; // Popularity of the band
	
	int act_time <- 0 update: act_time + 1;
	int duration <- 0;
	
	bool act_running <- false;
	bool next <- false;
	
	aspect base {
		if !self.initialized and length(StageList) < number_of_stages {
			add self.name to: StageList;
			if length(StageList) = 1 {
				self.location <- stage_location1;
			} else if length(StageList) = 2 {
				self.location <- stage_location2;
			} else if length(StageList) = 3 {
				self.location <- stage_location3;
			} else if length(StageList) = 4 {
				self.location <- stage_location4;
			}
		}
		
		if self.act_time < 100 {
			draw 'NEW!!' at: self.location + {-4, 7} color: #magenta font: font('Default', 12, #bold);
			self.color <- #magenta;
		} else {
			self.color <- #red;
		}
		
		draw rectangle(8, 8) color: self.color;
		draw string(int(self.f1)) + '/10 Music' at: self.location + {5, -2} color: #black font: font('Default', 9);
		draw string(int(self.f2)) + '/10 Band' at: self.location + {5, 0} color: #black font: font('Default', 9);
		draw string(int(self.f3)) + '/10 Lightshow' at: self.location + {5, 2} color: #black font: font('Default', 9);
		draw string(int(self.f4)) + '/10 Visuals' at: self.location + {5, 4} color: #black font: font('Default', 9);
		draw string(int(self.f5)) + '/10 Speakers' at: self.location + {5, 6} color: #black font: font('Default', 9);
		draw string(int(self.f6)) + '/10 Popularity' at: self.location + {5, 8} color: #black font: font('Default', 9);
	}
	
	reflex startAct when: (self.act_time = self.duration) or (!self.initialized) {
		self.duration <- rnd(100,1000);
		self.act_time <- 0;
		int pref1 <- rnd(0,10);
		int pref2 <- rnd(0,10);
		int pref3 <- rnd(0,10);
		int pref4 <- rnd(0,10);
		int pref5 <- rnd(0,10);
		int pref6 <- rnd(0,10);
		int norm_fact <- pref1 + pref2 + pref3 + pref4 + pref5 + pref6;
		norm_fact <- 1;
		self.f1 <- pref1/norm_fact; // Music
		self.f2 <- pref2/norm_fact; // Band
		self.f3 <- pref3/norm_fact; // Lightshow
		self.f4 <- pref4/norm_fact; // Visuals
		self.f5 <- pref5/norm_fact; // Speakers
		self.f6 <- pref6/norm_fact; // Popularity of the band
		self.next <- true;
		self.initialized <- true;
	}
	
	reflex sendMessage when: self.next = true {
		loop r over: GuestList {
			do start_conversation (to :: [r], protocol :: 'fipa-request', performative :: 'cfp', contents :: [self.location,f1,f2,f3,f4,f5,f6,self.name]);
		}
		self.next <- false;
	}
}

experiment BasicModelTask2 type: gui{
	output {
		display main_display {
			species stage aspect: base;
			species guest aspect: base;
		}
	}	
}