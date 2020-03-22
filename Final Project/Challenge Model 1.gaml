/***
* Name: FinalProject
* Author: Alexandros Nicolaou, Alexandre Justo Miro
* Description: Behavior of different agents
* Tags: Tag1, Tag2, TagN
***/

model ChallengeModel1


global {
	int number_of_bar <- 1;
	int number_of_bank <- 1;
	int number_of_exit <- 1;
	int number_of_toilet <- 1;
	int number_of_drugdealers <- 6;
	int number_of_guests <- 50;
	int i<-0;
	
	point bar_location <- {10,10};
	point bank_location <- {10,90};
	point exit_location <- {90,10};
	point toilet_location <- {90,90};
	
	list<drug_dealer> ddealers<-[];
	point drugs_at_location <- nil;
	list drug_names <- ['El Chapo', 'Escobar', 'Rodriguez', 'Justo Miro', 'Rick Ross', ' Fuentes'];
	
	// Predicates
	predicate dance <- new_predicate("Everybody dance now");
	predicate do_drugs <- new_predicate("I'm blue da boo dee da boo daa");
	predicate drink <- new_predicate("Shall I buy you a shot?");
	predicate get_money <- new_predicate("Money rule the world");
	predicate need_pee <- new_predicate("Emergency... Be right back");
	predicate pee <- new_predicate("That felt nice");
	predicate go_back <- new_predicate("Continue...");
	predicate need_money <- new_predicate("Where's my money?");
	predicate nirvana <- new_predicate("Shall I go for drink or drugs?");
	
	
	init {
		create guest number: number_of_guests;
		create bar number: number_of_bar;
		create bank number: number_of_bank;
		create toilet number: number_of_toilet;
		create exit number: number_of_exit;
		create drug_dealer number: number_of_drugdealers;
	}
}

// Bar
species bar {

	aspect base {
		draw rectangle(7,4) at: bar_location color: #gray;
		draw string('Bar') at: bar_location + {-4, 4} color: #black font: font('Default', 18, #bold);
	}
}

// Toilet
species toilet {

	aspect base {
		draw rectangle(7,4) at: toilet_location color: #gray;
		draw string('Toilet') at: toilet_location + {-4, 4} color: #black font: font('Default', 18, #bold);
	}
}

// Bank
species bank {

	aspect base {
		draw rectangle(7,4) at: bank_location color: #gray;
		draw string('Bank') at: bank_location + {-4, 4} color: #black font: font('Default', 18, #bold);
	}
}

// Exit
species exit {

	aspect base {
		draw rectangle(7,4) at: exit_location color: #gray;
		draw string('Exit') at: exit_location + {-4, 4} color: #black font: font('Default', 18, #bold);
	}
}

// Guests
species guest skills: [moving] control: simple_bdi{
	
	int money_level<- rnd(200,500);
	int money_delta <- rnd(1,3);
	
	int thirst_level<-rnd(250,500);
	int thirst_delta <- rnd(1,2);
	int thirst_threshold <- 200;
	
	int drunk_level<-rnd(0,50);
	int drunk_delta <- rnd(2,6);
	int drunk_threshold <- 200;
	
	
	point initial_location <- self.location;
	point targetPoint <-nil;
	float view_dist<-50.0;
	
	aspect base {
		draw circle(1) color: #blue;
	}
	
	init {
		do add_desire(dance);
	}
	
	// Reflexes
	reflex activate_money_need when: money_level<10{
		do add_belief(need_money);
	}
	
	
	// Perceive
	perceive target: drug_dealer where (each.drug_quantity > 0) in: view_dist{
		if myself.drunk_level >myself.drunk_threshold {
			drugs_at_location<-self.location;
		    ask myself {
		        do add_belief(nirvana);
		    }   
		}
	}

	// Rules
	rule belief: need_money new_desire: get_money strength: 10.0;
	rule belief: nirvana new_desire: do_drugs strength: 8.0;
	rule belief: nirvana new_desire: drink strength: 8.0;
	rule belief: need_pee new_desire: pee strength: 1.0;
	
	//rule belief: nirvana new_desire: dance strength: 3.0;
	
	
	// Plans	
	plan Dance intention: dance  {
		//do goto target: initial_location;
        do wander;
        thirst_level <- thirst_level - thirst_delta;
		if thirst_level < thirst_threshold{
			do add_belief(need_pee);
			do add_desire(drink);
			do remove_belief(nirvana);
			do remove_intention(dance,true);
		}
    }
       
    plan GoBack intention: go_back  {
        do goto target: initial_location;
        if (self.location = initial_location){
        	do remove_intention(go_back,true);
        	do add_desire(dance);
        }
    }
    
    plan GetMoney intention: get_money  {
        do goto target: bank_location;
        if (self.location = bank_location){
        	money_level<-rnd(450,500);
        	do remove_belief(need_money);
        	do remove_intention(get_money,true);
        	do add_desire(go_back);
        }
    }
    
    plan Drink intention: drink  {
        do goto target: bar_location;
        if (self.location = bar_location){
        	thirst_level<-rnd(450,500);
        	drunk_level <- drunk_level + drunk_delta;
        	money_level <- money_level - 10;
        	do remove_intention(drink,true);
        	do remove_belief(nirvana);
        	do add_desire(go_back);
        }
    }
    
    plan Drugs intention: do_drugs {
    	if !empty(ddealers){
        	do goto target: drugs_at_location;	
        }else{
        	do remove_intention(do_drugs,true);
        	do add_desire(go_back);
        }
        if (self.location = drugs_at_location){
        	ask drug_dealer at_distance(1){
        		self.drug_quantity <- self.drug_quantity -1;
        	}
        	money_level <- money_level - 10;
        	
        	do remove_intention(do_drugs,true);
        	do remove_belief(nirvana);
        	do add_desire(go_back);
        }
    }
    
    plan Pee intention: pee{
    	do goto target: toilet_location;
        if (self.location = toilet_location){
        	do remove_intention(pee,true);
        	do remove_belief(need_pee);
        	do add_desire(go_back);
        }
    }
    
}

// Drug Dealers
species drug_dealer skills: [moving]{
	int drug_quantity<- rnd(5,10);
	
	
	init{
		self.name <- drug_names[i];
		i<- i+1;
		add self to: ddealers;
	}
	
	reflex leave when: drug_quantity=0{
		do goto target: exit_location;
		if (self.location = exit_location){
			write 'The ' + self.name + ' dealer sold his product and left';
			ddealers <-ddealers-self;
			drugs_at_location <- nil;
			do die;
		}
	}
	
	aspect base {
		draw circle(1+0.2*drug_quantity) color: #red;
	}
}

experiment ChallengeModel1 type: gui {
	output {
		display Festival {
			species bar aspect: base;
			species toilet aspect: base;
			species exit aspect: base;
			species bank aspect: base;
			species drug_dealer aspect: base;
			species guest aspect: base;
		}
	}
}