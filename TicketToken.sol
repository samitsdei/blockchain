// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

contract TokenMaster is ERC721, Pausable {
    // State variables
    address public owner;
    uint256 public totalOccasions;
    uint256 public totalSupply;

    struct Occasion {
        uint256 id;
        string name;
        uint256 cost;
        uint256 tickets;
        uint256 maxTickets;
        string date;
        string time;
        string location;
    }

    // Mappings
    mapping(uint256 => Occasion) public occasions;
    mapping(uint256 => mapping(address => bool)) public hasBought;
    mapping(uint256 => mapping(uint256 => address)) public seatTaken;
    mapping(uint256 => uint256[]) public seatsTaken;

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    // Constructor
    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
        owner = msg.sender;
    }

    // Pause the contract
    function pause() public onlyOwner {
        _pause();
    }

    // Unpause the contract
    function unpause() public onlyOwner {
        _unpause();
    }

    // List a new occasion
    function listOccasion(
        string memory _name,
        uint256 _cost,
        uint256 _maxTickets,
        string memory _date,
        string memory _time,
        string memory _location
    ) public onlyOwner whenNotPaused {
        totalOccasions++;
        occasions[totalOccasions] = Occasion({
            id: totalOccasions,
            name: _name,
            cost: _cost,
            tickets: _maxTickets,
            maxTickets: _maxTickets,
            date: _date,
            time: _time,
            location: _location
        });
    }

    // Mint a ticket for a specific occasion
    function mintTicket(uint256 _id, uint256 _seat) public payable whenNotPaused {
        // Validate inputs
        require(_id > 0 && _id <= totalOccasions, "Invalid occasion ID");
        require(msg.value >= occasions[_id].cost, "Insufficient payment");
        require(seatTaken[_id][_seat] == address(0), "Seat already taken");
        require(_seat > 0 && _seat <= occasions[_id].maxTickets, "Invalid seat number");
        require(occasions[_id].tickets > 0, "No tickets available");

        // Update state
        occasions[_id].tickets--;
        hasBought[_id][msg.sender] = true;
        seatTaken[_id][_seat] = msg.sender;
        seatsTaken[_id].push(_seat);

        // Mint NFT
        totalSupply++;
        _safeMint(msg.sender, totalSupply);
    }

    // Get details of a specific occasion
    function getOccasionDetails(uint256 _id) public view returns (Occasion memory) {
        require(_id > 0 && _id <= totalOccasions, "Occasion does not exist");
        return occasions[_id];
    }

    // Get the list of taken seats for a specific occasion
    function getSeatsTaken(uint256 _id) public view returns (uint256[] memory) {
        require(_id > 0 && _id <= totalOccasions, "Occasion does not exist");
        return seatsTaken[_id];
    }

    // Withdraw contract balance to the owner
    function withdrawFunds() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");

        (bool success, ) = owner.call{value: balance}("");
        require(success, "Withdrawal failed");
    }

}
