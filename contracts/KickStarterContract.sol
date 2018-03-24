pragma solidity ^0.4.17;

contract CampaignFactory {
    address[] public deployedCampaigns;

    function createCampaign(uint minimum) public {
        address newCampaign = new Campaign(minimum, msg.sender);
        deployedCampaigns.push(newCampaign);
    }

    function getDeployedCampaigns() public view returns (address[]) {
        return deployedCampaigns;
    }
}

contract Campaign {
    struct Request {
        string description; // Describes why the request is being created.
        uint value; // Amount of money that the manager wants to send to vendor.
        address recipient; // Address that the money will be sent to.
        bool complete; // True if the request has already been processed.
        uint approvalCount; // Track who has voted
        mapping(address => bool) approvals; // Track number of approvals
    }

    address public manager; // Address of the person who is managing this campaign.
    uint public minimumContribution; // Minimum donation required to be considered a contributor or approver.
    mapping(address => bool) public approvers; // List of addresses for every person who has donated money.
    Request[] public requests; // List of requests that the manager has created.
    uint public approversCount; // Keep count every time someone donates to campaign.

    // Constructor function that sets the minimumContribution and the owner.
    function Campaign(uint minimum, address creator) public {
        manager = creator;
        minimumContribution = minimum;
    }
    // Called when someone wants to donate money to the campaign and become an approver.
    function contribute() public payable {
        require(msg.value > minimumContribution);
        if(!approvers[msg.sender]){
            approvers[msg.sender] = true;
            approversCount++;
        }
    }
    // Called by the manager to create a new spending request.
    function createRequest(string description, uint value, address recipient) public restricted {
        Request memory newRequest = Request({
           description: description,
           value: value,
           recipient: recipient,
           complete: false,
           approvalCount: 0
        });
        requests.push(newRequest);
    }

    // Called by each contributor to approve a spending request
    function approveRequest(uint index) public {
        Request storage currentRequest = requests[index];

        require(approvers[msg.sender]); // Require User is an Approver.
        require(!currentRequest.approvals[msg.sender]); // Require Approver hasnt already voted for this Request.

        currentRequest.approvals[msg.sender] = true; // Approver has now cast his vote for this Request.
        currentRequest.approvalCount++; // Increment the number of Approvals voted.
    }

    // After a req has gotten enough approvals, the manager can call this to get money sent to vendor.
    function finalizeRequest(uint index) public restricted {
        Request storage currentRequest = requests[index];

        require(currentRequest.approvalCount > (approversCount / 2)); // More than half of Approvers must vote.
        require(!currentRequest.complete); // Require this Request hasnt already been complete.

        currentRequest.recipient.transfer(currentRequest.value); // Send out money to the vendor.
        currentRequest.complete = true;
    }

    modifier restricted() {
        require(msg.sender == manager);
        _;
    }
}
