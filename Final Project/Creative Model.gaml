/***
* Name: FinalProject
* Author: Alexandros Nicolaou, Alexandre Justo Miro
* Description: Behavior of different agents
* Tags: Tag1, Tag2, TagN
***/

model CreativeModel

global {
	int number_of_places <- 9;
	int number_of_guests <- 50;
	int number_of_instructors <- 1;
	
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
	list<guest> guestListParty <- [];
	list<guest> guestListChill <- [];
	list<guest> guestListAlcoholic <- [];
	list<guest> guestListInstagrammer <- [];
	list<guest> guestListDealer <- [];
	list<guest> guestListPartyAll <- [];
	list<guest> guestListChillAll <- [];
	list<guest> guestListAlcoholicAll <- [];
	list<guest> guestListInstagrammerAll <- [];
	list<guest> guestListDealerAll <- [];
	
	init {
		create instructor number: number_of_instructors;
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

species guest skills: [moving, fipa] {
	
	// For creativity
	bool infected <- false;
	bool won <- false;
	
	// Personal traits
	int generous <- rnd(1,10);
	int friendly <- rnd(1,10);
	int wealthy <- rnd(1,10);
	
	// Traits depending on type
	float interact_party;
	float interact_chill;
	float interact_alcoholic;
	float interact_instagrammer;
	float interact_dealer;
	
	int timer <- 0 update: timer + 1;
	int autonomy <- -1;
	bool limit_interactions <- false;
	
	string type <- guest_type[rnd(0, length(guest_type)-1)];
	rgb color;
	point targetPoint;
	bool initialized <- false;
	bool decider;
	
	aspect base {
		if self.initialized = false {
			self.initialized <- true;
			if self.type = 'Party' {
				add self to: guestListParty;
				add self to: guestListPartyAll;
				self.color <- #lawngreen;
				self.interact_party <- 1.0;
				self.interact_chill <- 0.5;
				self.interact_alcoholic <- with_precision(rnd(0.0,1.0),1);
				self.interact_instagrammer <- 0.2;
				self.interact_dealer <- with_precision(rnd(0.0,1.0),1);
			} else if self.type = 'Chill' {
				add self to: guestListChill;
				add self to: guestListChillAll;
				self.color <- #cyan;
				self.interact_party <- 0.0;
				self.interact_chill <- 1.0;
				self.interact_alcoholic <- 0.0;
				self.interact_instagrammer <- 0.5;
				self.interact_dealer <- 0.0;
			} else if self.type = 'Alcoholic' {
				add self to: guestListAlcoholic;
				add self to: guestListAlcoholicAll;
				self.color <- #orange;
				self.interact_party <- 0.4;
				self.interact_chill <- 0.6;
				self.interact_alcoholic <- 1.0;
				self.interact_instagrammer <- 0.2;
				self.interact_dealer <- 0.8;
			} else if self.type = 'Instagrammer' {
				add self to: guestListInstagrammer;
				add self to: guestListInstagrammerAll;
				self.color <- #magenta;
				self.interact_party <- 0.8;
				self.interact_chill <- 0.4;
				self.interact_alcoholic <- 0.6;
				self.interact_instagrammer <- 1.0;
				self.interact_dealer <- 0.2;
			} else if self.type = 'Dealer' {
				add self to: guestListDealer;
				add self to: guestListDealerAll;
				self.color <- #red;
				self.interact_party <- 1.0;
				self.interact_chill <- 0.6;
				self.interact_alcoholic <- 0.2;
				self.interact_instagrammer <- 0.4;
				self.interact_dealer <- 0.0;
			}
		}
		if self.infected {
			draw obj_file("12140_Skull_v3_L2.obj", 90::{1,0,0}) color: self.color size: 2 at: self.location;
		} else if self.won {
			draw obj_file("WinnerCup.obj", 90::{0,1,0}) color: self.color size: 2 at: self.location;
		} else {
			draw circle(0.5) color: self.color;
		}
	}
	
	reflex readMessage when: (!(empty(self.cfps))) {
		message a <- (self.cfps at 0);
		if string(a.contents at 0) = 'You are infected' {
			self.infected <- true;
			if self.type = 'Party' and self in guestListParty {
				remove self from: guestListParty;
			} else if self.type = 'Chill' and self in guestListChill {
				remove self from: guestListChill;
			} else if self.type = 'Alcoholic' and self in guestListAlcoholic {
				remove self from: guestListAlcoholic;
			} else if self.type = 'Instagrammer' and self in guestListInstagrammer {
				remove self from: guestListInstagrammer;
			} else if self.type = 'Dealer' and self in guestListDealer {
				remove self from: guestListDealer;
			}
		}
		if string(a.contents at 0) = 'You are eliminated' {
			do die;
		}
		if string(a.contents at 0) = 'You won' {
			self.infected <- false;
			self.won <- true;
		}
	}
	
	reflex move when: self.targetPoint != nil {
		if (distance_to(self.location, self.targetPoint) > 5#m) {
			do goto target: self.targetPoint;
		}
		do wander;
	}
	
	reflex choosePlace when: (self.timer>self.autonomy) {
		self.timer <- 0;
		self.autonomy <- rnd(200,400);
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
	
	reflex interact when: (self.limit_interactions=false and !self.won) {
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
					bool aux_decider_1 <- flip(self.friendly/10);
					bool aux_decider_2 <- flip(self.interact_party);
					if aux_decider_1 and aux_decider_2 {
						decider <- true;
						acceptance_count <- acceptance_count + 1;
						write string(self.name) + 'says: Yes, ' + string(myself.name) + '. I am ' + string(self.type) + ' and I accept to dance with you.';
					} else {
						decider <- false;
						rejection_count <- rejection_count + 1;
						write string(self.name) + 'says: No, ' + string(myself.name) + '. I am sorry, but I am not friendly enough to dance with you.';
					}
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
					bool aux_decider_1 <- flip(self.friendly/10);
					bool aux_decider_2 <- flip(self.interact_chill);
					if aux_decider_1 and aux_decider_2 {
						decider <- true;
						acceptance_count <- acceptance_count + 1;
						write string(self.name) + 'says: Yes, ' + string(myself.name) + '. I am ' + string(self.type) + ' and I accept to chill with you.';
					} else {
						decider <- false;
						rejection_count <- rejection_count + 1;
						write string(self.name) + 'says: No, ' + string(myself.name) + '. I am sorry, but I am not friendly enough to chill with you.';
					}
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
					bool aux_decider_1 <- flip(self.generous/10);
					bool aux_decider_2 <- flip(self.interact_alcoholic);
					if aux_decider_1 and aux_decider_2 {
						decider <- true;
						acceptance_count <- acceptance_count + 1;
						write string(self.name) + 'says: Yes, ' + string(myself.name) + '. I am ' + string(self.type) + ' and I am inviting you for a drink.';
					} else {
						decider <- false;
						rejection_count <- rejection_count + 1;
						write string(self.name) + 'says: No, ' + string(myself.name) + '. I am sorry, but I am not generous enough to invite you for a drink.';
					}
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
					bool aux_decider_1 <- flip(self.friendly/10);
					bool aux_decider_2 <- flip(self.interact_instagrammer);
					if aux_decider_1 and aux_decider_2 {
						decider <- true;
						acceptance_count <- acceptance_count + 1;
						write string(self.name) + 'says: Yes, ' + string(myself.name) + '. I am ' + string(self.type) + ' and I am taking a picture with you.';
					} else {
						decider <- false;
						rejection_count <- rejection_count + 1;
						write string(self.name) + 'says: No, ' + string(myself.name) + '. I am sorry, but I am not friendly enough to take a picture with you.';
					}
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
					bool aux_decider_1 <- flip(self.wealthy/10);
					bool aux_decider_2 <- flip(self.interact_dealer);
					if aux_decider_1 and aux_decider_2 {
						decider <- true;
						acceptance_count <- acceptance_count + 1;
						write string(self.name) + 'says: Yes, ' + string(myself.name) + '. I am ' + string(self.type) + ' and I am buying drugs to you.';
					} else {
						decider <- false;
						rejection_count <- rejection_count + 1;
						write string(self.name) + 'says: No, ' + string(myself.name) + '. I am sorry, but I am not wealthy enough to buy drugs to you.';
					}
				}
			}
			if myself.infected and decider=true {
				self.infected <- true;
				if self.type = 'Party' and self in guestListParty {
					remove self from: guestListParty;
				} else if self.type = 'Chill' and self in guestListChill {
					remove self from: guestListChill;
				} else if self.type = 'Alcoholic' and self in guestListAlcoholic {
					remove self from: guestListAlcoholic;
				} else if self.type = 'Instagrammer' and self in guestListInstagrammer {
					remove self from: guestListInstagrammer;
				} else if self.type = 'Dealer' and self in guestListDealer {
					remove self from: guestListDealer;
				}
			}
		}
		self.limit_interactions <- true;
	}
}

species instructor skills: [fipa] {
	list winner <- [0, 'Empty'];
	bool eliminated_party <- false;
	bool eliminated_chill <- false;
	bool eliminated_alcoholic <- false;
	bool eliminated_instagrammer <- false;
	bool eliminated_dealer <- false;
	bool gameOver <- false;
	aspect base {
		self.location <- {45,-4};
		draw 'INSTRUCTOR' color: #white at: self.location + {-22,-2};
		draw obj_file("OgreOBJ.obj", 30::{0,1,0}) size: 10 at: self.location;
		if gameOver {
			draw 'Congratulations, team ' + string(winner[1]) + '! You won with ' + string(winner[0]) + ' healthy agents left!' color: #white at: self.location + {7,-1};
		} else {
			draw 'Team ' + string(winner[1]) + ' are winning with ' + string(winner[0]) + ' healthy agents left.' color: #white at: self.location + {7,-1};
		}
		draw 'Party (' + length(guestListParty) + ')' color: eliminated_party ? #gray : #lawngreen at: self.location + {7,2};
		draw 'Chill (' + length(guestListChill) + ')' color: eliminated_chill ? #gray : #cyan at: self.location + {22,2};
		draw 'Alcoholic (' + length(guestListAlcoholic) + ')' color: eliminated_alcoholic ? #gray : #orange at: self.location + {37,2};
		draw 'Instagr. (' + length(guestListInstagrammer) + ')' color: eliminated_instagrammer ? #gray : #magenta at: self.location + {57,2};
		draw 'Dealer (' + length(guestListDealer) + ')' color: eliminated_dealer ? #gray : #red at: self.location + {77,2};
	}
	reflex startGame when: time = 100 {
		do start_conversation (to :: [one_of(guestListParty)], protocol :: 'fipa-request', performative :: 'cfp', contents :: ['You are infected']);
		do start_conversation (to :: [one_of(guestListChill)], protocol :: 'fipa-request', performative :: 'cfp', contents :: ['You are infected']);
		do start_conversation (to :: [one_of(guestListAlcoholic)], protocol :: 'fipa-request', performative :: 'cfp', contents :: ['You are infected']);
		do start_conversation (to :: [one_of(guestListInstagrammer)], protocol :: 'fipa-request', performative :: 'cfp', contents :: ['You are infected']);
		do start_conversation (to :: [one_of(guestListDealer)], protocol :: 'fipa-request', performative :: 'cfp', contents :: ['You are infected']);
	}
	reflex scoreboard when: mod(time,10)=0 {
		self.winner <- [0, 'Empty'];
		int LParty <- length(guestListParty);
		int LChill <- length(guestListChill);
		int LAlcoholic <- length(guestListAlcoholic);
		int LInstagrammer <- length(guestListInstagrammer);
		int LDealer <- length(guestListDealer);
		if LParty = 0 and !eliminated_party {
			eliminated_party <- true;
			loop e over: guestListPartyAll {
				do start_conversation (to :: [e], protocol :: 'fipa-request', performative :: 'cfp', contents :: ['You are eliminated']);
			}
		}
		if LChill = 0 and !eliminated_chill {
			eliminated_chill <- true;
			loop e over: guestListChillAll {
				do start_conversation (to :: [e], protocol :: 'fipa-request', performative :: 'cfp', contents :: ['You are eliminated']);
			}
		}
		if LAlcoholic = 0 and !eliminated_alcoholic {
			eliminated_alcoholic <- true;
			loop e over: guestListAlcoholicAll {
				do start_conversation (to :: [e], protocol :: 'fipa-request', performative :: 'cfp', contents :: ['You are eliminated']);
			}
		}
		if LInstagrammer = 0 and !eliminated_instagrammer {
			eliminated_instagrammer <- true;
			loop e over: guestListInstagrammerAll {
				do start_conversation (to :: [e], protocol :: 'fipa-request', performative :: 'cfp', contents :: ['You are eliminated']);
			}
		}
		if LDealer = 0 and !eliminated_dealer {
			eliminated_dealer <- true;
			loop e over: guestListDealerAll {
				do start_conversation (to :: [e], protocol :: 'fipa-request', performative :: 'cfp', contents :: ['You are eliminated']);
			}
		}
		list<list> scores <- [[LParty, 'Party'], [LChill, 'Chill'], [LAlcoholic, 'Alcoholic'], [LInstagrammer, 'Instagrammer'], [LDealer, 'Dealer']];
		loop s over: scores {
			if int(s[0]) > int(self.winner[0]) {
				self.winner[0] <- s[0];
				self.winner[1] <- s[1];
			} else if int(s[0]) = int(self.winner[0]) {
				self.winner[0] <- s[0];
				self.winner[1] <- string(string(self.winner[1]) + ' and ' + s[1]) ;				
			}
		}
	}
	reflex endGame when: (int(eliminated_party) + int(eliminated_chill) + int(eliminated_alcoholic) + int(eliminated_instagrammer) + int(eliminated_dealer) = 4 and !gameOver) {
		gameOver <- true;
		if !eliminated_party {
			loop e over: guestListPartyAll {
				do start_conversation (to :: [e], protocol :: 'fipa-request', performative :: 'cfp', contents :: ['You won']);
			}
		} else if !eliminated_chill {
			loop e over: guestListChillAll {
				do start_conversation (to :: [e], protocol :: 'fipa-request', performative :: 'cfp', contents :: ['You won']);
			}
		} else if !eliminated_alcoholic {
			loop e over: guestListAlcoholicAll {
				do start_conversation (to :: [e], protocol :: 'fipa-request', performative :: 'cfp', contents :: ['You won']);
			}
		} else if !eliminated_instagrammer {
			loop e over: guestListInstagrammerAll {
				do start_conversation (to :: [e], protocol :: 'fipa-request', performative :: 'cfp', contents :: ['You won']);
			}
		} else if !eliminated_dealer {
			loop e over: guestListDealerAll {
				do start_conversation (to :: [e], protocol :: 'fipa-request', performative :: 'cfp', contents :: ['You won']);
			}
		}
	}
}

experiment CreativeModel type: gui {
	output {
		display Chart refresh: every(500#cycles) {
			chart "Acceptance and rejection" type: pie {
				data "Acceptance" value: acceptance_count color: #green;
				data "Rejection" value: rejection_count color: #red;
			}
		}
		display Festival type: opengl background: #black {
			species instructor aspect: base;
			species place aspect: base;
			species guest aspect: base;
		}
	}
}