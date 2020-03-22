/***
* Name: Assignment3
* Author: Alexandros Nicolaou, Alexandre Justo Miro
* Description: Coordination & Utility
* Tags: Tag1, Tag2, TagN
***/

model ChallengeModel

global {
	int number_of_guests <- 10;
	int number_of_stages <- 4;
	
	point stage_location1 <- {10,10};
	point stage_location2 <- {10,90};
	point stage_location3 <- {70,10};
	point stage_location4 <- {70,90};
	
	list<guest> GuestList <- [];
	list<string> GuestListString <- [];
	list<stage> StageList <- [];
	list<string> StageListString <- [];
	
	list<guest> people_attending_A <- [];
	list<guest> people_attending_B <- [];
	list<guest> people_attending_C <- [];
	list<guest> people_attending_D <- [];
	
	list<list> CloudList <- [];
	
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
	float prewP <- rnd(-1.0, 1.0);
	float norm_fact <- prew1 + prew2 + prew3 + prew4 + prew5 + prew6 + prewP;
	float w1 <- prew1/norm_fact;
	float w2 <- prew2/norm_fact;
	float w3 <- prew3/norm_fact;
	float w4 <- prew4/norm_fact;
	float w5 <- prew5/norm_fact;
	float w6 <- prew6/norm_fact;
	float wP <- prewP/norm_fact;
	
	float utility;
	float max_utility;
	
	string label <- '?';
	
	list empty <- [{0.0, 0.0, 0.0}, 0.0, label];
	list memory <- [empty, empty, empty, empty];
	
	aspect base {
		if !self.initialized {
			add self to: GuestList;
			add self.name to: GuestListString;
			self.initialized <- true;
		}
		draw circle(1.0) at: self.location color: #lawngreen;
		draw string(self.label) at: self.location + {-0.6, 0.9} color: #black;
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
		int index <- StageListString index_of string(a.contents at 7);
		int fP <- int(a.contents at 8);
		string stage_label <- string(a.contents at 9);
		
		self.utility <- self.w1*f1 + self.w2*f2 + self.w3*f3 + self.w4*f4 + self.w5*f5 + self.w6*f6 + self.wP*fP;
		self.memory[index] <- [where, self.utility, stage_label];

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
				self.label <- string(m[2]);
				self.max_utility <- float(m[1]);
				self.targetPoint <- point(m[0]);
			}
		}
		
		int people <- 0;
		
		if self.label = 'A' {
			people <- length(people_attending_A);
		} else if self.label = 'B' {
			people <- length(people_attending_B);
		} else if self.label = 'C' {
			people <- length(people_attending_C);
		} else if self.label = 'D' {
			people <- length(people_attending_D);
		}
		
		int index <- GuestListString index_of string(self.name);
		if length(CloudList) < number_of_guests {
			add [self.wP, self.label, people] to: CloudList;
		}
		if length(CloudList) = number_of_guests {
			CloudList[index] <- [self.wP, self.label, people];
		}
		float delta_S <- 0.0;
		float delta_A <- float(self.memory[0][1]) - float(self.max_utility) - float(CloudList[index][0])*(10*1)/number_of_guests;
		float delta_B <- float(self.memory[1][1]) - float(self.max_utility) - float(CloudList[index][0])*(10*1)/number_of_guests;
		float delta_C <- float(self.memory[2][1]) - float(self.max_utility) - float(CloudList[index][0])*(10*1)/number_of_guests;
		float delta_D <- float(self.memory[3][1]) - float(self.max_utility) - float(CloudList[index][0])*(10*1)/number_of_guests;
		if length(CloudList) = number_of_guests {
			loop j over: CloudList {
				if j[1] = self.label {
					// How much j's utility increases/decreases if self does not change stage
					delta_S <- delta_S + float(j[0])*(10*1)/number_of_guests;
				} else if j[1] = 'A' {
					// How much j's utility increases/decreases if self changed to A
					delta_A <- delta_A + float(j[0])*(10*1)/number_of_guests;
				} else if j[1] = 'B' {
					// How much j's utility increases/decreases if self changed to B
					delta_B <- delta_B + float(j[0])*(10*1)/number_of_guests;
				} else if j[1] = 'C' {
					// How much j's utility increases/decreases if self changed to C
					delta_C <- delta_C + float(j[0])*(10*1)/number_of_guests;
				} else if j[1] = 'D' {
					// How much j's utility increases/decreases if self changed to D
					delta_D <- delta_D + float(j[0])*(10*1)/number_of_guests;
				}
			}
		}
		if (delta_S > delta_A) and (delta_S > delta_B) and (delta_S > delta_C) and (delta_S > delta_D) {
			write string(self.name) + ': I stay with my initial decision since global utility cannot be further maximized';
		} else if (delta_A > delta_S) and (delta_A > delta_B) and (delta_A > delta_C) and (delta_A > delta_D) {
			if delta_A > 0.05 {
				self.targetPoint <- self.memory[0][0];
				self.label <- 'A';
				write string(self.name) + ': I change to stage A. I sacrifice ' + string(with_precision(float(self.memory[0][1]) - float(self.max_utility),1)) + ' but global utility is increased ' + string(with_precision(delta_A,1));
				}
		} else if (delta_B > delta_A) and (delta_B > delta_S) and (delta_B > delta_C) and (delta_B > delta_D) {
			if delta_B > 0.05 {
				self.targetPoint <- self.memory[1][0];
				self.label <- 'B';
				write string(self.name) + ': I change to stage B. I sacrifice ' + string(with_precision(float(self.memory[0][1]) - float(self.max_utility),1)) + ' but global utility is increased ' + string(with_precision(delta_B,1));
				}
		} else if (delta_C > delta_A) and (delta_C > delta_B) and (delta_C > delta_S) and (delta_C > delta_D) {
			if delta_C > 0.05 {
				self.targetPoint <- self.memory[2][0];
				self.label <- 'C';
				write string(self.name) + ': I change to stage C. I sacrifice ' + string(with_precision(float(self.memory[0][1]) - float(self.max_utility),1)) + ' but global utility is increased ' + string(with_precision(delta_C,1));
				}
		} else if (delta_D > delta_A) and (delta_D > delta_B) and (delta_D > delta_C) and (delta_D > delta_S) {
			if delta_D > 0.05 {
				self.targetPoint <- self.memory[3][0];
				self.label <- 'D';
				write string(self.name) + ': I change to stage D. I sacrifice ' + string(with_precision(float(self.memory[0][1]) - float(self.max_utility),1)) + ' but global utility is increased ' + string(with_precision(delta_D,1));
				}
		}
		
		loop i over: StageList {
			if self.location distance_to(i.location) > 5 {
				ask i {
					if (myself in self.people_attending) {
						remove myself from: self.people_attending;
						self.update_message <- true;
						break;
					}
				}
			} else {
				ask i {
					if !(myself in self.people_attending) {
						add myself to: self.people_attending;
						self.update_message <- true;
						break;
					}
				}
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
	
	float f1 <- 0.0; // Music
	float f2 <- 0.0; // Band
	float f3 <- 0.0; // Lightshow
	float f4 <- 0.0; // Visuals
	float f5 <- 0.0; // Speakers
	float f6 <- 0.0; // Popularity of the band
	
	int act_time <- 0 update: act_time + 1;
	int duration <- 0;
	string label;
	
	bool act_running <- false;
	bool next <- false;
	bool update_message <- false;
	
	list<guest> people_attending <- [];
	
	aspect base {
		if !self.initialized and length(StageList) < number_of_stages {
			add self to: StageList;
			add self.name to: StageListString;
			if length(StageList) = 1 {
				self.location <- stage_location1;
				self.label <- 'A';
			} else if length(StageList) = 2 {
				self.location <- stage_location2;
				self.label <- 'B';
			} else if length(StageList) = 3 {
				self.location <- stage_location3;
				self.label <- 'C';
			} else if length(StageList) = 4 {
				self.location <- stage_location4;
				self.label <- 'D';
			}
		}
		
		if self.label = 'A' {
			people_attending_A <- self.people_attending;
		} else if self.label = 'B' {
			people_attending_B <- self.people_attending;
		} else if self.label = 'C' {
			people_attending_C <- self.people_attending;
		} else if self.label = 'D' {
			people_attending_D <- self.people_attending;
		}
		
		if self.act_time < 100 {
			draw 'NEW!!' at: self.location + {-4, 7} color: #magenta font: font('Default', 12, #bold);
			self.color <- #magenta;
		} else {
			self.color <- #blue;
		}
		
		draw rectangle(8, 8) color: self.color;
		draw string(self.label) at: self.location + {-3, 3} font: font('Default', 44, #bold);
		draw string(int(self.f1)) + '/10 Music' at: self.location + {5, -2} color: #black font: font('Default', 9);
		draw string(int(self.f2)) + '/10 Band' at: self.location + {5, 0} color: #black font: font('Default', 9);
		draw string(int(self.f3)) + '/10 Lightshow' at: self.location + {5, 2} color: #black font: font('Default', 9);
		draw string(int(self.f4)) + '/10 Visuals' at: self.location + {5, 4} color: #black font: font('Default', 9);
		draw string(int(self.f5)) + '/10 Speakers' at: self.location + {5, 6} color: #black font: font('Default', 9);
		draw string(int(self.f6)) + '/10 Popularity' at: self.location + {5, 8} color: #black font: font('Default', 9);
		draw string(length(self.people_attending)) + '/' + string(number_of_guests) + ' People' at: self.location + {5, 10} color: #black font: font('Default', 9);
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
			do start_conversation (to :: [r], protocol :: 'fipa-request', performative :: 'cfp', contents :: [self.location,self.f1,self.f2,self.f3,self.f4,self.f5,self.f6,self.name,10*length(self.people_attending)/number_of_guests,self.label]);
		}
		self.next <- false;
	}
	
	reflex updateMessage when: self.update_message = true {
		loop r over: GuestList {
			do start_conversation (to :: [r], protocol :: 'fipa-request', performative :: 'cfp', contents :: [self.location,self.f1,self.f2,self.f3,self.f4,self.f5,self.f6,self.name,10*length(self.people_attending)/number_of_guests,self.label]);
		}
		self.update_message <- false;
	}
}

experiment ChallengeModel type: gui{
	output {
		display main_display {
			species stage aspect: base;
			species guest aspect: base;
		}
	}	
}