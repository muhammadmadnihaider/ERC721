pragma solidity ^0.6.0;

import "./ERC721.sol";
import "./SafeMath.sol";

contract Zameen is ERC721{
    using SafeMath for uint256;
    
    // final_price;
    
    uint256 private final_price;
    
    // enum status
    
    enum responce{
        pending,
        accepted,
        rejected
    }
    
    // checking mappings
    struct buyer{
        address buyer_address;
        uint256 offer;
        responce status;
    }
    
    //Counter TokenId
    uint256 private _tokenId;
    
    // number of offer
     buyer[] private totalOffers;
    
    // mapping of TokenId to demand
    mapping (uint256 => uint256) demandOfPlot;
    
    // is Property on sale 
    mapping(uint256 => bool) isPropertyOnSale;
    
    // responce of owner to buyer
    mapping(address => responce) statusOfOffer;
    
    // collection of people who have made the offer
    
    mapping (address => bool) Interested;
    
    constructor() ERC721("Zameen town","ZTK") public {
    }
    
    
    
    modifier isAvailable(uint256 _token_id){
        require(isPropertyOnSale[_token_id] == true,"Property is not available for sale");
        _;
    }
    
    modifier isOwner(uint256 _token_id) {
        require(_tokenOwners[_token_id] == msg.sender, "you don't posses the ownership of this property");
        _;
    }
    
    modifier isInterested(){
        require(Interested[msg.sender] == true, "you haven't bid yet that's why you can't buy property");
        _;
    }
    // to register through register() function a property to blockchain as 721 representation

    function register(string memory tokenURI) public returns (uint256) {
        
        _tokenId = _tokenId.add(1);
        // new toke created and ownership assiged to allottee
        _mint(msg.sender, _tokenId);
        
        // new TokeURI save against newTokenID
        _setTokenURI(_tokenId, tokenURI);
        
        isPropertyOnSale[_tokenId] = false;
    }
    
    /////////////////////////////// part 1////////////////////////////////////////////////////
    
    // functions that faclitate the owner of the token
    
    // publish the token of your Property on sale so it will be visible to buyers
    function listProperty(uint256 _token_id, uint256 DemandInEthers) public isOwner(_token_id) returns(bool){
        require(isPropertyOnSale[_token_id]==false, "already listed");
        isPropertyOnSale[_token_id] = true;
        demandOfPlot[_token_id] = DemandInEthers;
        return true;
    }
    
    // how many offers are made to the token you are selling
    function numberOfOffers(uint256 _token_id) public isOwner(_token_id) isAvailable(_token_id) view returns(uint256){
        return totalOffers.length;
    }
    
    // numberOfOffers() will give you total offers then you can put into the checkTheOffers() function so get the desired demand invidually by puttin it's index
    function checkTheOffers(uint256 _index, uint256 _token_id) public isOwner(_token_id) isAvailable(_token_id) view returns(address _buyerAddress, uint256 _offer, responce _status) {
        buyer memory _buyer = totalOffers[_index];
        return(_buyer.buyer_address, _buyer.offer, _buyer.status);
    }
    
    // then give responce to those offers so the buyers will be eligbile to buy the property
    
    function ResponceToOffers(uint256 _index , responce _rec, uint256 _token_id) public isOwner(_token_id) returns(bool) {
        if(_rec == responce.rejected){
            statusOfOffer[totalOffers[_index].buyer_address] = _rec;
            totalOffers[_index] = totalOffers[totalOffers.length.sub(1)];
            totalOffers.pop();
        }
        else if(_rec == responce.accepted){
            statusOfOffer[totalOffers[_index].buyer_address] = _rec;
            final_price = totalOffers[_index].offer.mul(1 ether);
            approve(totalOffers[_index].buyer_address, _token_id);
            
        }
        
        return true;
    }
    
    
    ////////////////////////////////////////////// part 2 //////////////////////////////////////////////////
    
    //functions that faclitates buyers
    
    
    // search properties to buy 
    function isPropertyAvailbleForSale(uint256 _token_id) public isAvailable(_token_id) view returns(string memory URI, uint256 demand){
        
            return (_tokenURIs[_token_id], demandOfPlot[_token_id]);
        
    }
    
    
    // make offers to particular properties that you have searched before and they are available
    
    function makeOffer(uint256 _token_id, uint256 _offer) public isAvailable(_token_id){
        require(msg.sender.balance >= demandOfPlot[_token_id], "you can't make offer because of lower balance than demanded balance");
        require(_offer > 0 ,"value can't be zero");
        require(Interested[msg.sender] == false, " you already bid the offer");
        buyer memory _buyer;
        _buyer.buyer_address = msg.sender;
        _buyer.offer = _offer;
        _buyer.status = responce.pending;
        Interested[msg.sender] = true;
        totalOffers.push(_buyer);
    }
    
    // after giving the amount(offer) wait for the responce(pending, accepted , rejected);
    function checkYourRequestStatus() public view returns(responce){
        return statusOfOffer[msg.sender];
    } 
    
    
    // if it's accepted then you can buy the property
    function buyProperty(uint256 _token_id) public payable isInterested() isAvailable(_token_id) {
        require(statusOfOffer[msg.sender] == responce.accepted , " your offer is not accepted");
        require(final_price <= msg.value,"amount is less than the committed amount");
        delete totalOffers;
        delete demandOfPlot[_token_id];
        delete isPropertyOnSale[_token_id];
        delete statusOfOffer[msg.sender];
        transferFrom(_tokenOwners[_token_id], msg.sender, _token_id);
        payable(_tokenOwners[_token_id]).transfer(address(this).balance);
        
    }
    
}