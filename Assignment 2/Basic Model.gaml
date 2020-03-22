/***
* Name: Assignment2
* Author: Alexandros Nicolaou, Alexandre Justo Miro
* Description: Negotiation and Communication (FIPA)
* Tags: Tag1, Tag2, TagN
***/

model BasicModel

global {
	int number_of_auctioneers <- 1;
	int number_of_participants <- 30;
	
	list<Initiator> InitiatorList <- [];
	
	init {
		create Participant number: number_of_participants;
		create Initiator number: number_of_auctioneers;
	}
}

species Initiator skills: [fipa] {

	rgb color;
	bool initialized <- false;
	int aPrice;
	int original_offer;
	bool auction_running <- false;
	list<Participant> people_attending <- [];
	int auction_time <- 0;
	bool next <- false;
	bool auction_ended <- false;
	int price_sold <- -1;
	int dutch_auction_minimum <- 100;
	
	aspect base {
		if !self.initialized{
			add self to: InitiatorList;
			self.color <- #red;
			self.aPrice <- rnd(400, 500);
			original_offer <- self.aPrice;
			self.initialized <- true;
		}
		
		draw rectangle(5,2) at: self.location color: self.color;
		draw 'DUTCH' at: self.location + {-5, -3} color: self.color font: font('Default', 12, #bold);
	}
	
	reflex startAuction when: length(self.people_attending) > 5 and self.auction_running = false and self.auction_ended = false {
		self.auction_running <- true;
		next <- true;
		loop a over: self.people_attending {
			do start_conversation (to :: [a], protocol :: 'fipa-request', performative :: 'inform', contents :: ["Auction starting"]);
		}
	}
	
	reflex sendMessage when: self.auction_running and next = true {
		
		self.aPrice <- self.aPrice - rnd(10,40);
		write "Current bid in Dutch auction is " + self.aPrice;
		
		loop r over: self.people_attending {
			do start_conversation (to :: [r], protocol :: 'fipa-request', performative :: 'cfp', contents :: [aPrice]);
		}
		write "Currently " + length(self.people_attending) + " participants: " + self.people_attending;
		next <- false;
	}
	
	reflex readMessage when: (!(empty(proposes))) and self.auction_running{
		
		Participant winner;
		loop a over: proposes {
			do accept_proposal with: [ message :: a, contents :: ['Proposal accepted'] ];
			bool is_buying <- bool(a.contents at 0);
			
			if self.aPrice < self.dutch_auction_minimum{
				self.auction_running <- false;
				self.price_sold <- 0;
				self.people_attending <- [];
				winner <- nil;
				write "Dutch auction is over. Articles could not be sold";
			} else if is_buying = true {
				self.auction_running <- false;
				self.price_sold <- self.aPrice;
				self.people_attending <- [];
				winner <- a.sender;
				write "Dutch auction is over. Articles were sold to " + a.sender + " for " + self.price_sold;
				break;
			}
		}
		
		if self.auction_running = false {
			write "Dutch auction sold articles for " + self.price_sold;
			self.auction_ended <- true;
			
			if winner != nil{
				do start_conversation (to :: [winner], protocol :: 'fipa-request', performative :: 'inform', contents :: ["Articles are being sold to you", self.price_sold]);
			}
			
		} else {
			next <- true;	
		}
	}
}

species Participant skills: [fipa, moving] {
	
	rgb color;
	point targetPoint;
	bool initialized <- false;
	bool attending <- false;
	int part_offer <- rnd(100, 400);
	bool buy_that <- false;
	
	aspect base {
		if self.initialized = false {
			self.color <- #magenta;
			self.targetPoint <- one_of(Initiator).location;
		}
		self.initialized <- true;
		draw circle(0.5) color: self.color;
	}
	
	reflex goToAuction when: self.attending = false {
		do goto target: targetPoint;
	
		if (location distance_to(targetPoint) < 2) {
			loop i over: InitiatorList{
				ask i {
					add myself to: self.people_attending;
					myself.attending <- true;
					break;
				}
			}
		}
	}
	
	reflex replyMessage when: (!empty(cfps)) {
		
		message requestFromInitiator <- (cfps at 0);
		int offer <- int(requestFromInitiator.contents at 0);
		
		write self.name + ' is willing to pay a maximum of ' + self.part_offer;
		
		if offer < self.part_offer {
			self.buy_that <- true;
			write self.name + ' says: "I would like to buy that for ' + offer + '!"';
		}
		
		do propose with: (message: requestFromInitiator, contents: [self.buy_that]);
	}
}

experiment BasicModel type: gui repeat: 1{
	output {
		display main_display {
			species Participant aspect: base;
			species Initiator aspect: base;
		}
	}	
}