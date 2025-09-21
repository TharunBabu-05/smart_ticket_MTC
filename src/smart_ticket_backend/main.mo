import Principal "mo:base/Principal";
import Time "mo:base/Time";
import HashMap "mo:base/HashMap";
import Result "mo:base/Result";
import Debug "mo:base/Debug";

actor SmartTicketBackend {
    
    // Types
    public type TicketId = Text;
    public type UserId = Text;
    public type Amount = Nat;
    
    public type Ticket = {
        id: TicketId;
        userId: UserId;
        route: Text;
        fromStop: Text;
        toStop: Text;
        amount: Amount;
        timestamp: Int;
        isValid: Bool;
    };
    
    public type TicketResult = Result.Result<Ticket, Text>;
    public type ValidationResult = Result.Result<Bool, Text>;
    
    // Storage
    private stable var ticketEntries : [(TicketId, Ticket)] = [];
    private var tickets = HashMap.HashMap<TicketId, Ticket>(0, Text.equal, Text.hash);
    
    // Initialize storage from stable memory
    system func preupgrade() {
        ticketEntries := tickets.entries() |> Iter.toArray(_);
    };
    
    system func postupgrade() {
        tickets := HashMap.fromIter<TicketId, Ticket>(ticketEntries.vals(), ticketEntries.size(), Text.equal, Text.hash);
        ticketEntries := [];
    };
    
    // Generate unique ticket ID
    private func generateTicketId() : TicketId {
        let timestamp = Time.now();
        let caller = Principal.toText(Principal.fromActor(SmartTicketBackend));
        "ICP_TKT_" # Int.toText(timestamp) # "_" # caller
    };
    
    // Purchase ticket on blockchain
    public func purchaseTicket(
        userId: UserId,
        route: Text,
        fromStop: Text,
        toStop: Text,
        amount: Amount
    ) : async TicketResult {
        
        let ticketId = generateTicketId();
        let ticket : Ticket = {
            id = ticketId;
            userId = userId;
            route = route;
            fromStop = fromStop;
            toStop = toStop;
            amount = amount;
            timestamp = Time.now();
            isValid = true;
        };
        
        tickets.put(ticketId, ticket);
        Debug.print("Ticket purchased: " # ticketId);
        
        #ok(ticket)
    };
    
    // Validate ticket
    public query func validateTicket(ticketId: TicketId) : async ValidationResult {
        switch (tickets.get(ticketId)) {
            case (?ticket) {
                if (ticket.isValid) {
                    #ok(true)
                } else {
                    #err("Ticket is not valid")
                }
            };
            case null {
                #err("Ticket not found")
            };
        }
    };
    
    // Get ticket details
    public query func getTicket(ticketId: TicketId) : async ?Ticket {
        tickets.get(ticketId)
    };
    
    // Get user tickets
    public query func getUserTickets(userId: UserId) : async [Ticket] {
        tickets.vals()
        |> Iter.filter(_, func(ticket: Ticket) : Bool { ticket.userId == userId })
        |> Iter.toArray(_)
    };
    
    // Invalidate ticket (for conductor use)
    public func invalidateTicket(ticketId: TicketId) : async ValidationResult {
        switch (tickets.get(ticketId)) {
            case (?ticket) {
                let updatedTicket = {
                    ticket with isValid = false
                };
                tickets.put(ticketId, updatedTicket);
                Debug.print("Ticket invalidated: " # ticketId);
                #ok(false)
            };
            case null {
                #err("Ticket not found")
            };
        }
    };
    
    // Get total tickets count
    public query func getTotalTicketsCount() : async Nat {
        tickets.size()
    };
    
    // Health check
    public query func healthCheck() : async Text {
        "Smart Ticket Backend is running on IC mainnet"
    };
}