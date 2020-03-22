/***
* Name: Assignment2
* Author: Alexandros Nicolaou, Alexandre Justo Miro
* Description: Negotiation and Communication (FIPA)
* Tags: Tag1, Tag2, TagN
***/

model ChallengesModel

global {
	int number_of_auctioneers <- 3;
	int number_of_participants <- 30;
	
	point auction_location1 <- {25,25};
	point auction_location2 <- {75,25};
	point auction_location3 <- {50,75};
	
	list<string> auction_genre <- ['Art', 'Metals', 'Vehicles'];
	list<string> auction_type <- ['Dutch', 'English', 'Sealed'];
	list<Initiator> InitiatorList <- [];
	
	list<list<int>> random_combination <- [[0,1,2],[0,2,1],[1,0,2],[1,2,0],[2,0,1],[2,1,0]];
	int combination_key <- rnd(0,5);
	
	int genre_assigned <- 0;
	int type_assigned <- 0;
	
	init {
		create Participant number: number_of_participants;
		create Initiator number: number_of_auctioneers;
	}
}

species Initiator skills: [fipa] {

	string genre;
	string type;
	rgb color;
	bool initialized <- false;
	int aPrice;
	int original_offer;
	bool auction_running <- false;
	list<Participant> people_attending <- [];
	bool next <- false;
	bool auction_ended <- false;
	int price_sold <- -1;
	int dutch_auction_minimum <- 100;
	int sealed_auction_minimum <- rnd(90,120);
	
	aspect base {
		if !self.initialized{
			add self to: InitiatorList;
			
			// Assign genre
			self.genre <- auction_genre[genre_assigned];
			genre_assigned <- genre_assigned + 1;
			
			if self.genre = 'Art'{
				self.color <- #red;
				self.location <- auction_location1;
			}
			
			else if self.genre = 'Metals'{
				self.color <- #green;
				self.location <- auction_location2;
			}
			
			else if self.genre = 'Vehicles'{
				self.color <- #blue;
				self.location <- auction_location3;
			}
			
			// Assign type
			self.type <- auction_type[random_combination[combination_key][type_assigned]];
			type_assigned <- type_assigned + 1;
			
			if self.type = 'Dutch'{
				self.aPrice <- rnd(400, 500);
			}
					
			else if self.type = 'English'{
				self.aPrice <- rnd(20, 50);
			}
			
			else if self.type = 'Sealed'{
				self.aPrice <- 0;
			}
			
			original_offer <- self.aPrice;
			
			self.initialized <- true;
		}
		
		draw rectangle(5,2) at: self.location color: self.color;
		draw string(self.genre) at: self.location + {3, 1} color: self.color font: font('Default', 12, #bold);
		draw string(self.type) + ' auction' at: self.location + {-5, 5} color: #black font: font('Default', 9);

	}
	
	reflex startAuction when: length(self.people_attending) > 5 and self.auction_running = false and self.auction_ended = false {
		self.auction_running <- true;
		next <- true;
		if self.type = 'English' {
			write "Starting bid in " + self.type + " auction selling " + self.genre + " is " + self.aPrice;
		}
		loop a over: self.people_attending {
			do start_conversation (to :: [a], protocol :: 'fipa-request', performative :: 'inform', contents :: ["Auction starting"]);
		}
	}
	
	reflex sendMessage when: self.auction_running and next = true {
		
		if self.type = 'Dutch'{
			self.aPrice <- self.aPrice - rnd(10,40);
			write "Current bid in " + self.type + " auction selling " + self.genre + " is " + self.aPrice;
		}
		
		loop r over: self.people_attending {
			do start_conversation (to :: [r], protocol :: 'fipa-request', performative :: 'cfp', contents :: [aPrice]);
		}
		write self.type + " auction selling " + self.genre + " currently has " + length(self.people_attending) + " participants: " + self.people_attending;
		next <- false;
	}
	
	reflex readMessage when: (!(empty(proposes))) and self.auction_running{
		Participant winner;
		loop a over: proposes {
			do accept_proposal with: [ message :: a, contents :: ['Proposal accepted'] ];
			bool is_buying <- bool(a.contents at 0);
			int offer_received <- int(a.contents at 1);
			
			if self.type = 'Dutch'{
				if self.aPrice < self.dutch_auction_minimum{
					self.auction_running <- false;
					self.price_sold <- 0;
					self.people_attending <- [];
					winner <- nil;
					write self.type + " auction is over. Articles could not be sold";
				} else if is_buying = true {
					self.auction_running <- false;
					self.price_sold <- self.aPrice;
					self.people_attending <- [];
					winner <- a.sender;
					write self.type + " auction is over. Articles were sold to " + a.sender + " for " + self.price_sold;
					break;
				}
			}
			
			else if self.type = 'English'{
				if is_buying = false and length(self.people_attending) > 1 {
					remove a.sender from: self.people_attending;
					write self.type + ' auction is abandoned by ' + a.sender + ' since the price is too high';
				}
				if (is_buying = true) and (offer_received > self.aPrice) and (offer_received > self.price_sold) {
					self.price_sold <- offer_received;
					winner <- a.sender;
					write self.type + " auction: " + a.sender + " raises to " + self.price_sold;
				}
				self.aPrice <- self.price_sold;
				
				if length(self.people_attending) = 1{
					self.auction_running <- false;
					self.people_attending <- [];
				}
			}
			
			else if self.type = 'Sealed'{
				write self.type + " receives " + string(a.sender) + ' is willing to pay ' + offer_received;
				if offer_received > self.price_sold{
					self.auction_running <- false;
					self.price_sold <- offer_received;
					winner <- a.sender;
					self.people_attending <- [];
				}
			}
		} 
		
		if self.auction_running = false {
			write self.type + " auction sold " + self.genre + " for " + self.price_sold;
			self.auction_ended <- true;
			
			if winner != nil{
				do start_conversation (to :: [winner], protocol :: 'fipa-request', performative :: 'inform', contents :: ["Articles are being sold to you", self.price_sold]);
				
				if self.type = 'Dutch'{
					write "Dutch auction gained value: " + with_precision(100.0*float(self.price_sold)/float(self.dutch_auction_minimum), 1) + "%";
				} else if self.type = 'English'{
					write "English auction gained value: " + with_precision(100.0*float(self.price_sold)/float(self.original_offer), 1) + "%";
				} else if self.type = 'Sealed'{
					write "Sealed auction gained value: " + with_precision(100.0*float(self.price_sold)/float(self.sealed_auction_minimum), 1) + "%";
				}	
			}
			
		} else {
			next <- true;	
		}
	}
}

species Participant skills: [fipa, moving] {
	
	string genre <- auction_genre[rnd(0,2)];
	string auction_type;
	rgb color;
	point targetPoint;
	bool initialized <- false;
	bool attending <- false;
	int part_offer <- rnd(100, 400);
	bool Dutch_buy_that <- false;
	bool English_continue <- false;
	int English_my_last_offer <- 0;
	
	aspect base {
		if self.initialized = false {
			if self.genre = 'Art'{
				self.color <- #magenta;
				self.targetPoint <- auction_location1;
			}
			
			else if self.genre = 'Metals'{
				self.color <- #lawngreen;
				self.targetPoint <- auction_location2;
			}
			
			else if self.genre = 'Vehicles'{
				self.color <- #cyan;
				self.targetPoint <- auction_location3;
			}
			
			self.initialized <- true;
		}
		
		draw circle(0.5) color: self.color;
	}
	
	reflex goToAuction when: self.attending = false {
		do goto target: targetPoint;
	
		if (location distance_to(targetPoint) < 2) {
			loop i over: InitiatorList{
				ask i {
					if self.genre = myself.genre{
						add myself to: self.people_attending;
						myself.attending <- true;
						myself.auction_type <- self.type;
						break;
					}
				}
			}
		}
	}
	
	reflex replyMessage when: (!empty(cfps)) {
		
		message requestFromInitiator <- (cfps at 0);
		int offer <- int(requestFromInitiator.contents at 0);
		
		if self.auction_type = 'Dutch' {
			if offer < self.part_offer {
				self.Dutch_buy_that <- true;
				write self.name + ' says: "I am buying that for ' + offer + '!"';
			}
			do propose with: (message: requestFromInitiator, contents: [self.Dutch_buy_that, nil]);
		}
		
		else if self.auction_type = 'English' {
			self.English_continue <- flip(1-0.001*offer);
			if offer > self.English_my_last_offer {
				self.English_my_last_offer <- offer + rnd(1,30);
			}
			do propose with: (message: requestFromInitiator, contents: [English_continue, self.English_my_last_offer]);
		}
		
		else if self.auction_type = 'Sealed' {
			do propose with: (message: requestFromInitiator, contents: [true, self.part_offer]);
		}
	}
}

experiment ChallengesModel type: gui repeat: 1{
	output {
		display main_display {
			species Participant aspect: base;
			species Initiator aspect: base;
		}
	}	
}