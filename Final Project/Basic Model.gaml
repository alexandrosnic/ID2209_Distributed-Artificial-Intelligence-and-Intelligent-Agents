/***
* Name: FinalProject
* Author: Alexandros Nicolaou, Alexandre Justo Miro
* Description: Behavior of different agents
* Tags: Tag1, Tag2, TagN
***/

model BasicModel

global {
	int number_of_places <- 9;
	int number_of_guests <- 50;
	
	int acceptance_count <- 0;
	int rejection_count <- 0;
	
	list<point> place_location <- [{10,10},{10,50},{10,90},{50,10},{50,50},{50,90},{90,10},{90,50},{90,90}];
	list<string> guest_type <- ['Party', 'Chill', 'Alcoholic', 'Instagrammer', 'Dealer'];
	list<string> place_type <- ['Stage', 'Terrace', 'Bar'];
	int type_assigned <- 0;
	list<place> placeList <- [];
	list<place> placeListStage <- [];
	list<place> placeListTerrace <- [];
	list<place> placeListBar <- [];
	
	init {
		create guest number: number_of_guests;
		create place number: number_of_places;
	}
}

species place {

	string type;
	rgb color;
	bool initialized <- false;
	
	aspect base {
		if !self.initialized{
			self.initialized <- true;
			add self to: placeList;
			// Assign type
			self.type <- place_type[rnd(0, length(place_type)-1)];
			self.location <- place_location[type_assigned];
			type_assigned <- type_assigned + 1;
			if self.type = 'Stage'{
				add self to: placeListStage;
				self.color <- #lawngreen;
			} else if self.type = 'Terrace'{
				add self to: placeListTerrace;
				self.color <- #cyan;
			} else if self.type = 'Bar'{
				add self to: placeListBar;
				self.color <- #orange;
			}
		}
		draw rectangle(5,2) at: self.location color: #gray;
		draw string(self.type) at: self.location + {-3, 3} color: self.color font: font('Default', 12, #bold);
	}
}

species guest skills: [moving] {
	
	// Personal traits
	int generous <- rnd(0,10);
	int friendly <- rnd(0,10);
	int wealthy <- rnd(0,10);
	
	// Traits depending on type
	float interact_party;
	float interact_chill;
	float interact_alcoholic;
	float interact_instagrammer;
	float interact_dealer;
	
	int time <- 0 update: time + 1;
	int autonomy <- rnd(200,400);
	bool limit_interactions <- false;
	
	string type <- guest_type[rnd(0, length(guest_type)-1)];
	rgb color;
	point targetPoint;
	bool initialized <- false;
	bool decider;
	
	aspect base {
		if self.initialized = false {
			if self.type = 'Party' {
				self.color <- #lawngreen;
				self.interact_party <- 1.0;
				self.interact_chill <- 0.5;
				self.interact_alcoholic <- with_precision(rnd(0.0,1.0),1);
				self.interact_instagrammer <- 0.2;
				self.interact_dealer <- with_precision(rnd(0.0,1.0),1);
			} else if self.type = 'Chill' {
				self.color <- #cyan;
				self.interact_party <- 0.0;
				self.interact_chill <- 1.0;
				self.interact_alcoholic <- 0.0;
				self.interact_instagrammer <- 0.5;
				self.interact_dealer <- 0.0;
			} else if self.type = 'Alcoholic' {
				self.color <- #orange;
				self.interact_party <- 0.4;
				self.interact_chill <- 0.6;
				self.interact_alcoholic <- 1.0;
				self.interact_instagrammer <- 0.2;
				self.interact_dealer <- 0.8;
			} else if self.type = 'Instagrammer' {
				self.color <- #magenta;
				self.interact_party <- 0.8;
				self.interact_chill <- 0.4;
				self.interact_alcoholic <- 0.6;
				self.interact_instagrammer <- 1.0;
				self.interact_dealer <- 0.2;
			} else if self.type = 'Dealer' {
				self.color <- #black;
				self.interact_party <- 1.0;
				self.interact_chill <- 0.6;
				self.interact_alcoholic <- 0.2;
				self.interact_instagrammer <- 0.4;
				self.interact_dealer <- 0.0;
			}
		}
		draw circle(0.5) color: self.color;
	}
	
	reflex move when: self.targetPoint != nil {
		if (distance_to(self.location, self.targetPoint) > 5#m) {
			do goto target: self.targetPoint;
		}
		do wander;
	}
	
	reflex choosePlace when: (self.time=self.autonomy) or (!self.initialized) {
		self.time <- 0;
		self.autonomy <- rnd(200,400);
		self.initialized <- true;
		self.limit_interactions <- false;
		if self.type = 'Party' {
			self.targetPoint <- placeListStage[rnd(0, length(placeListStage)-1)].location;
		} else if self.type = 'Chill' {
			self.targetPoint <- placeListTerrace[rnd(0, length(placeListTerrace)-1)].location;
		} else if self.type = 'Alcoholic' {
			self.targetPoint <- placeListBar[rnd(0, length(placeListBar)-1)].location;
		} else if self.type = 'Instagrammer' {
			self.targetPoint <- placeList[rnd(0, length(placeList)-1)].location;
		} else if self.type = 'Dealer' {
			self.targetPoint <- placeList[rnd(0, length(placeList)-1)].location;
		}
	}
	
	reflex interact when: (self.limit_interactions=false) {
		ask guest at_distance 5#m {
			if (myself.type = 'Party') {
				write string(myself.name) + 'asks: Hello, ' + string(self.name) + '. I am ' + string(myself.type) + ' and I want to dance with you.';
				if self.friendly>=5 {
					decider <- flip(self.interact_party);
					if decider=true {
						acceptance_count <- acceptance_count + 1;
						write string(self.name) + 'says: Yes, ' + string(myself.name) + '. I am ' + string(self.type) + ' and I accept to dance with you.';
					} else if decider=false {
						rejection_count <- rejection_count + 1;
						write string(self.name) + 'says: No, ' + string(myself.name) + '. I am ' + string(self.type) + ' and I do not like ' + string(myself.type) + ' people.';
					}
				} else if self.friendly<5 {
					decider <- false;
					rejection_count <- rejection_count + 1;
					write string(self.name) + 'says: No, ' + string(myself.name) + '. I am sorry, but I am not friendly enough to dance with you.';
				}
			} else if (myself.type = 'Chill') {
				write string(myself.name) + 'asks: Hello, ' + string(self.name) + '. I am ' + string(myself.type) + ' and I want to chill with you.';
				if self.friendly>=5 {
					decider <- flip(self.interact_chill);
					if decider=true {
						acceptance_count <- acceptance_count + 1;
						write string(self.name) + 'says: Yes, ' + string(myself.name) + '. I am ' + string(self.type) + ' and I accept to chill with you.';
					} else if decider=false {
						rejection_count <- rejection_count + 1;
						write string(self.name) + 'says: No, ' + string(myself.name) + '. I am ' + string(self.type) + ' and I do not like ' + string(myself.type) + ' people.';
					}
				} else if self.friendly<5 {
					decider <- false;
					rejection_count <- rejection_count + 1;
					write string(self.name) + 'says: No, ' + string(myself.name) + '. I am sorry, but I am not friendly enough to chill with you.';
				}
			} else if (myself.type = 'Alcoholic') {
				write string(myself.name) + 'asks: Hello, ' + string(self.name) + '. I am ' + string(myself.type) + ' and I want to drink with you.';
				if self.generous>=5 {
					decider <- flip(self.interact_alcoholic);
					if decider=true {
						acceptance_count <- acceptance_count + 1;
						write string(self.name) + 'says: Yes, ' + string(myself.name) + '. I am ' + string(self.type) + ' and I am inviting you for a drink.';
					} else if decider=false {
						rejection_count <- rejection_count + 1;
						write string(self.name) + 'says: No, ' + string(myself.name) + '. I am ' + string(self.type) + ' and I do not like ' + string(myself.type) + ' people.';
					}
				} else if self.generous<5 {
					decider <- false;
					rejection_count <- rejection_count + 1;
					write string(self.name) + 'says: No, ' + string(myself.name) + '. I am sorry, but I am not generous enough to invite you for a drink.';
				}
			} else if (myself.type = 'Instagrammer') {
				write string(myself.name) + 'asks: Hello, ' + string(self.name) + '. I am ' + string(myself.type) + ' and I want a picture with you.';
				if self.friendly>=5 {
					decider <- flip(self.interact_instagrammer);
					if decider=true {
						acceptance_count <- acceptance_count + 1;
						write string(self.name) + 'says: Yes, ' + string(myself.name) + '. I am ' + string(self.type) + ' and I am taking a picture with you.';
					} else if decider=false {
						rejection_count <- rejection_count + 1;
						write string(self.name) + 'says: No, ' + string(myself.name) + '. I am ' + string(self.type) + ' and I do not like ' + string(myself.type) + ' people.';
					}
				} else if self.friendly<5 {
					decider <- false;
					rejection_count <- rejection_count + 1;
					write string(self.name) + 'says: No, ' + string(myself.name) + '. I am sorry, but I am not friendly enough to take a picture with you.';
				}
			} else if (myself.type = 'Dealer') {
				write string(myself.name) + 'asks: Hello, ' + string(self.name) + '. I am ' + string(myself.type) + ' and I want to sell drugs to you.';
				if self.wealthy>=5 {
					decider <- flip(self.interact_dealer);
					if decider=true {
						acceptance_count <- acceptance_count + 1;
						write string(self.name) + 'says: Yes, ' + string(myself.name) + '. I am ' + string(self.type) + ' and I am buying drugs to you.';
					} else if decider=false {
						rejection_count <- rejection_count + 1;
						write string(self.name) + 'says: No, ' + string(myself.name) + '. I am ' + string(self.type) + ' and I do not like ' + string(myself.type) + ' people.';
					}
				} else if self.wealthy<5 {
					decider <- false;
					rejection_count <- rejection_count + 1;
					write string(self.name) + 'says: No, ' + string(myself.name) + '. I am sorry, but I am not wealthy enough to buy drugs to you.';
				}
			}
		}
		self.limit_interactions <- true;
	}
}

experiment BasicModel type: gui {
	output {
		display Festival {
			species place aspect: base;
			species guest aspect: base;
		}
		display Chart refresh: every(500#cycles) {
			chart "Acceptance and rejection" type: pie { 
				data "Acceptance" value: acceptance_count color: #green;
				data "Rejection" value: rejection_count color: #red;
			}
		}
	}
}