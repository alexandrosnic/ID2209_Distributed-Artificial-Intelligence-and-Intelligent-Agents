/***
* Name: Assignment2
* Author: Alexandros Nicolaou, Alexandre Justo Miro
* Description: Negotiation and Communication (FIPA)
* Tags: Tag1, Tag2, TagN
***/

model CreativeModel

global {
	int number_of_auctioneers <- 1;
	int number_of_participants <- 30;
	int number_of_police <- 5;
	int number_of_cars <- 1;
	
	
	point car_loc <- {70,30};
	
	list<Initiator> InitiatorList <- [];
		
	init {
		create Participant number: number_of_participants;
		create Initiator number: number_of_auctioneers;
		create police number: number_of_police; 
		create car number:number_of_cars;
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
	
	aspect geom3D {
		if !self.initialized{
			add self to: InitiatorList;
			self.color <- #red;
			self.aPrice <- rnd(400, 500);
			original_offer <- self.aPrice;
			self.initialized <- true;
		}
		
		
		draw obj_file("C:/Users/Alex/gama_workspace/Assignment2/includes/auction3d.obj", 90::{-1,0,0}) size: 5
		at: location + {0,0,7} rotate: - 90;//shape depth: 200#m border: #black texture: ["C:/Users/Alex/gama_workspace/Assignment2/includes/rectangle.png","C:/Users/Alex/gama_workspace/Assignment2/includes/rectangle.png"]; //at: self.location color: self.color 
		
		draw 'DUTCH' at: self.location + {-5, -3} color: self.color font: font('Default', 12, #bold);
	}
	
	reflex startAuction when: length(self.people_attending) > 5 and self.auction_running = false and self.auction_ended = false {
		self.auction_running <- true;
		next <- true;
		loop a over: self.people_attending {
			do start_conversation (to :: [a], protocol :: 'fipa-request', performative :: 'inform', contents :: ["Auction starting"]);
		}
	}
	
	reflex send_request when: self.auction_running and next = true {
		
		self.aPrice <- self.aPrice - rnd(10,40);
		write "Current bid in Dutch auction is " + self.aPrice;
		
		loop r over: self.people_attending {
			do start_conversation (to :: [r], protocol :: 'fipa-request', performative :: 'cfp', contents :: [aPrice]);
		}
		write "Currently " + length(self.people_attending) + " participants: " + self.people_attending;
		next <- false;
	}
	
	reflex read_reply_message when: (!(empty(proposes))) and self.auction_running{
		
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
	point startingPoint <- location;
	bool initialized <- false;
	bool attending <- false;
	int part_offer <- rnd(100, 400);
	bool buy_that <- false;
	bool auctionEnded <- false;
	
	//Creative part
	bool thiefDetected;
	bool caughtByPolice <- false;
	int number_of_escaped_thiefs<- 0;
	point carLocation;
	
	aspect base {
		if self.initialized = false {
			self.color <- #magenta;
			self.targetPoint <- one_of(Initiator).location;
		}
		if self.thiefDetected{
			self.color <- #green;
		}
		else{
			self.color <- #magenta;
		}
		self.initialized <- true;
		draw sphere(1.5) color: self.color;
	}
	
	reflex reachAuction when: self.attending = false and (self.auctionEnded = false){
		do goto target: targetPoint;
	
		if (location distance_to(targetPoint) < 2) {
			loop i over: InitiatorList{
				ask i {
					add myself to: self.people_attending;
					myself.attending <- true;
					myself.thiefDetected <- flip(0.5);
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
	
	
	
	// Creative part
	
	reflex goBack {
		ask Initiator{
			if (self.auction_ended){
				myself.auctionEnded <-true;
			}
		}
		if (auctionEnded) and (thiefDetected=false){
			do goto target: startingPoint;
		}
		if (location distance_to(startingPoint)<2){
			self.auctionEnded <- false; 
		}
	}
	
	reflex try_to_escape{
		if (self.thiefDetected){
			if (auctionEnded) {
				ask car{
					myself.carLocation <- self.location;
				}
				do goto target: carLocation;
				if (location distance_to(carLocation)<2){
					number_of_escaped_thiefs <- number_of_escaped_thiefs +1;
					write number_of_escaped_thiefs;
					
				}
			}
		}
	}
	
	reflex being_caught when: (caughtByPolice){
		do die;
	}
	
	
	
}

// Creative part
species police skills: [moving]{
	point targetPoint<-nil;
	point startingPosition <- nil;
	bool backToStart <- false;
	int changeColor;
	
	reflex chase_the_thief {
		ask Participant{
			if(self.thiefDetected) and (self.auctionEnded){
				myself.startingPosition <- myself.location;
				myself.targetPoint <- self.location;
				//do goto target: myself.targetPoint;
			}
			if (myself.location distance_to(self.location) < 1#m){
				self.caughtByPolice <- true;
				myself.targetPoint<- myself.startingPosition;
				myself.backToStart <- true;
				//self.caughtByPolice <- false; he will die anw
			}
			if (myself.backToStart){
				myself.targetPoint<-nil;
				myself.backToStart <- false;
			}
		}
	}
	
	reflex move when: targetPoint != nil{
		do goto target:targetPoint;
		changeColor <- rnd(1,2);
	}
	
	
	aspect base{
		if (changeColor=1){
			color<- #blue;
		}else{
			color <- #red;
		}
		draw box(2.5,2.5,4) at: self.location color: color;
		draw 'POLICE' at: self.location + {-5,-3} color: #black font: font('Default', 12, #bold);
	}
}


species car skills: [moving]{
	point targetPoint<-nil;
	bool youcango<-false;
	
	
	reflex setTarget{
		ask Participant{
			if (self.number_of_escaped_thiefs >2){
				myself.youcango<-true;
				//write myself.youcango;
			}
		}
	}
	
	reflex move when: youcango{
		targetPoint <- {100,location.y};
		do goto target:targetPoint;
	}	
	
	aspect geom3D{
		//draw obj_file("C:/Users/Alex/gama_workspace/Assignment2/includes/car.obj", 90::{-1,0,0}) size: 5
		//at: location + {0,0,7} rotate: - 90;
		
		draw box(6,4,4)  color: #blue;
		draw 'CAR' color: #black font: font('Default', 12, #bold);
	}
}

experiment CreativeModel type: gui repeat: 1{
	output {
		display main_display type:opengl{
			species Participant aspect: base;
			species Initiator aspect: geom3D;
			species police aspect: base;
			species car aspect: geom3D transparency: 0.5;
		}
	}	
}